import 'dart:convert' show jsonEncode, jsonDecode, utf8, Encoding;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/chat_message.dart';
import '../models/knowledge_base.dart';
import '../models/product.dart';
import './product_service.dart';

class ChatbotService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  ProductService _productService;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final uuid = Uuid();
  
  // Pinecone config
  bool _isPineconeInitialized = false;
  String _pineconeApiUrl = '';
  String _pineconeHost = '';
  String _pineconeIndexName = '';
  
  // Cloud Function API URLs
  final String _findSimilarProductsUrl = 'https://us-central1-chosinhviennttu.cloudfunctions.net/findSimilarProducts';
  final String _searchProductsByTextUrl = 'https://us-central1-chosinhviennttu.cloudfunctions.net/searchProductsByText';
  final String _rebuildPineconeIndexUrl = 'https://us-central1-chosinhviennttu.cloudfunctions.net/rebuildPineconeIndex';
  
  // Constant để lưu danh mục câu hỏi
  final Map<String, List<String>> _questionCategories = {
    'greeting': [
      'xin chào', 'chào', 'hello', 'hi', 'hey', 'chào bạn', 'xin chào bạn'
    ],
    'farewell': [
      'tạm biệt', 'bye', 'goodbye', 'hẹn gặp lại', 'see you'
    ],
    'product_search': [
      'có bán', 'tìm', 'mua', 'sản phẩm', 'giá', 'cần', 'muốn mua'
    ],
    'help': [
      'hướng dẫn', 'cách', 'làm sao', 'làm thế nào', 'giúp', 'help'
    ],
    'talk_to_user': [
      'tâm sự', 'chuyện trò', 'trò chuyện', 'tâm tình', 'nói chuyện', 'chia sẻ', 'buồn', 'vui',
      'cảm thấy', 'nghĩ gì', 'cảm xúc', 'suy nghĩ', 'lo lắng', 'áp lực', 'căng thẳng', 'stress'
    ]
  };
  
  bool get isLoading => _isLoading;
  List<ChatMessage> get messages => _messages;
  
  // API URL và key từ environment variable
  String get _geminiApiUrl => dotenv.env['GEMINI_API_URL'] ?? 'https://generativelanguage.googleapis.com/v1beta/models';
  String get _geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  String get _geminiModel => dotenv.env['GEMINI_MODEL'] ?? '';
  String get _pineconeApiKey => dotenv.env['PINECONE_API_KEY'] ?? '';
  String get _pineconeEnvironment => dotenv.env['PINECONE_ENVIRONMENT'] ?? 'gcp-starter';

  ChatbotService(this._productService) {
    _addWelcomeMessage();
    _initPinecone();
  }
  
  // Khởi tạo Pinecone
  Future<bool> _initPinecone() async {
    try {
      if (_pineconeApiKey.isEmpty) {
        print('PINECONE_API_KEY not found in environment variables');
        return false;
      }
      
      // Khởi tạo các giá trị
      _pineconeHost = dotenv.env['PINECONE_HOST'] ?? '';
      _pineconeIndexName = dotenv.env['PINECONE_INDEX_NAME'] ?? 'student-market-knowledge-base';
      
      if (_pineconeHost.isEmpty) {
        print('PINECONE_HOST not found in environment variables');
        return false;
      }
      
      // Xử lý URL để tránh lặp lại https://
      if (_pineconeHost.startsWith('https://')) {
        _pineconeApiUrl = _pineconeHost;
      } else {
        _pineconeApiUrl = 'https://$_pineconeHost';
      }
      
      _isPineconeInitialized = true;
      print('Pinecone initialized with API URL: $_pineconeApiUrl, Index: $_pineconeIndexName');
      return true;
    } catch (e) {
      print('Error initializing Pinecone: $e');
      return false;
    }
  }
  
  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      id: uuid.v4(),
      content: 'Xin chào! Tôi là trợ lý ảo của Student Market NTTU. Tôi có thể giúp bạn tìm kiếm sản phẩm hoặc giải đáp thắc mắc về cách sử dụng ứng dụng. Bạn có thể hỏi tôi điều gì?',
      isUser: false,
      timestamp: DateTime.now(),
    );
    _messages.add(welcomeMessage);
  }
  
  // Thêm tin nhắn mới từ người dùng
  Future<void> addUserMessage(String message) async {
    if (message.trim().isEmpty) return;
    
    final userMessage = ChatMessage(
      id: uuid.v4(),
      content: message,
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    _messages.add(userMessage);
    notifyListeners();
    
    // Xử lý tin nhắn và tạo phản hồi
    await _processMessage(message);
  }
  
  // Xử lý tin nhắn và quyết định loại phản hồi
  Future<void> _processMessage(String message) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Sử dụng AI để phân loại câu hỏi
      final messageCategory = await _classifyMessage(message);
      
      // Trích xuất từ khóa chính dựa trên loại tin nhắn
      List<String> keywords = [];
      
      switch (messageCategory) {
        case 'product_search':
          keywords = await _extractProductKeywords(message);
          print('Extracted product keywords: $keywords');
          break;
        case 'help':
          keywords = await _extractHelpKeywords(message);
          print('Extracted help keywords: $keywords');
          break;
        default:
          // Cho các loại tin nhắn khác, sử dụng trích xuất từ khóa chung
          keywords = await _extractMainKeywords(message);
          print('Extracted general keywords: $keywords');
          break;
      }
      
      // Xử lý tin nhắn theo danh mục
      switch (messageCategory) {
        case 'greeting':
          _addBotTextMessage(_getRandomGreetingResponse());
          break;
        case 'farewell':
          _addBotTextMessage(_getRandomFarewellResponse());
          break;
        case 'product_search':
          await _handleProductSearch(message, keywords);
          break;
        case 'help':
          await _handleHelpRequest(message, keywords);
          break;
        case 'talk_to_user':
          await _handleTalkToUser(message);
          break;
        default:
          // Nếu không xác định được loại tin nhắn, sử dụng RAG để tạo phản hồi
          await _generateRAGResponse(message, keywords);
      }
    } catch (e) {
      print('Error processing message: $e');
      _addBotTextMessage('Xin lỗi, đã có lỗi xảy ra. Vui lòng thử lại sau.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Trích xuất từ khóa chung 
  Future<List<String>> _extractMainKeywords(String message) async {
    try {
      final url = _getGeminiApiUrl();
      
      final prompt = '''Trích xuất TỐI ĐA 5 từ khóa CHÍNH từ câu hỏi sau đây của người dùng.
Chỉ trả về danh sách từ khóa, mỗi từ khóa một dòng, không có số thứ tự, không có dấu gạch đầu dòng.
Từ khóa nên là các danh từ hoặc cụm từ ngắn, có ý nghĩa và liên quan trực tiếp đến nội dung câu hỏi.
KHÔNG bao gồm các từ chung chung như "cách", "làm sao", "hướng dẫn" trừ khi chúng là phần quan trọng của câu hỏi.
Ví dụ, nếu câu hỏi là "Làm sao để đăng ký tài khoản?", từ khóa nên là "đăng ký tài khoản", không phải "làm sao".
Từ khóa có thể bằng tiếng Việt hoặc tiếng Anh tùy thuộc vào ngôn ngữ trong câu hỏi.
Sắp xếp từ khóa theo thứ tự quan trọng giảm dần.

Câu hỏi: $message''';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
        encoding: Encoding.getByName('utf-8'),
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': prompt
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 100,
          }
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final String resultText = data['candidates'][0]['content']['parts'][0]['text'].trim();
        
        // Tách các từ khóa (mỗi từ khóa một dòng)
        final keywords = resultText
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .take(5) // Giới hạn tối đa 5 từ khóa
            .toList();
        
        return keywords;
      } else {
        print('Error extracting main keywords: ${utf8.decode(response.bodyBytes)}');
        // Trong trường hợp lỗi, sử dụng phương thức trích xuất từ khóa cũ
        return _extractKeywords(message);
      }
    } catch (e) {
      print('Exception extracting main keywords: $e');
      // Trong trường hợp lỗi, sử dụng phương thức trích xuất từ khóa cũ
      return _extractKeywords(message);
    }
  }
  
  // Phương thức mới: Trích xuất từ khóa liên quan đến sản phẩm
  Future<List<String>> _extractProductKeywords(String message) async {
    try {
      final url = _getGeminiApiUrl();
      
      final prompt = '''Trích xuất TỐI ĐA 5 từ khóa CHÍNH liên quan đến SẢN PHẨM từ câu hỏi của người dùng.
Chỉ trả về danh sách từ khóa, mỗi từ khóa một dòng, không có số thứ tự, không có dấu gạch đầu dòng.
Tập trung vào các từ khóa liên quan đến:
- Tên sản phẩm hoặc loại sản phẩm
- Đặc điểm, thuộc tính của sản phẩm (màu sắc, kích thước, tính năng)
- Thương hiệu hoặc nhà sản xuất
- Giá cả hoặc phạm vi giá
- Mục đích sử dụng sản phẩm
- Danh mục sản phẩm

KHÔNG bao gồm các từ chung chung như "tìm", "mua", "sản phẩm", "có bán không" trừ khi chúng là phần quan trọng.
Từ khóa có thể bằng tiếng Việt hoặc tiếng Anh tùy thuộc vào ngôn ngữ trong câu hỏi.
Sắp xếp từ khóa theo thứ tự quan trọng giảm dần.

Câu hỏi: $message''';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
        encoding: Encoding.getByName('utf-8'),
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': prompt
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 100,
          }
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final String resultText = data['candidates'][0]['content']['parts'][0]['text'].trim();
        
        // Tách các từ khóa (mỗi từ khóa một dòng)
        final keywords = resultText
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .take(5) // Giới hạn tối đa 5 từ khóa
            .toList();
        
        return keywords;
      } else {
        print('Error extracting product keywords: ${utf8.decode(response.bodyBytes)}');
        // Trong trường hợp lỗi, sử dụng phương thức trích xuất từ khóa chung
        return _extractMainKeywords(message);
      }
    } catch (e) {
      print('Exception extracting product keywords: $e');
      // Trong trường hợp lỗi, sử dụng phương thức trích xuất từ khóa chung
      return _extractMainKeywords(message);
    }
  }
  
  // Phương thức mới: Trích xuất từ khóa liên quan đến trợ giúp ứng dụng
  Future<List<String>> _extractHelpKeywords(String message) async {
    try {
      final url = _getGeminiApiUrl();
      
      final prompt = '''Trích xuất TỐI ĐA 5 từ khóa CHÍNH liên quan đến TÍNH NĂNG ỨNG DỤNG từ câu hỏi của người dùng (KHÔNG nhất thiết phải đủ 5). Không được tạo có từ khóa không liên quan mật thiết với câu hỏi người dùng
Chỉ trả về danh sách từ khóa, mỗi từ khóa một dòng, không có số thứ tự, không có dấu gạch đầu dòng.
Tập trung vào các từ khóa liên quan đến:
- Tính năng hoặc chức năng cụ thể của ứng dụng
- Giao diện người dùng
- Cài đặt hoặc cấu hình
- Đăng ký, đăng nhập, tài khoản 
- Quy trình thực hiện việc gì đó (mua hàng, bán hàng, thanh toán)
- Vấn đề người dùng gặp phải
- Hướng dẫn sử dụng ứng dụng

KHÔNG bao gồm các từ chung chung như "cách", "làm sao", "hướng dẫn" trừ khi chúng là phần quan trọng.
Từ khóa có thể bằng tiếng Việt hoặc tiếng Anh tùy thuộc vào ngôn ngữ trong câu hỏi.
Sắp xếp từ khóa theo thứ tự quan trọng giảm dần.

Câu hỏi: $message''';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
        encoding: Encoding.getByName('utf-8'),
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': prompt
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 100,
          }
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final String resultText = data['candidates'][0]['content']['parts'][0]['text'].trim();
        
        // Tách các từ khóa (mỗi từ khóa một dòng)
        final keywords = resultText
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .take(5) // Giới hạn tối đa 5 từ khóa
            .toList();
        
        return keywords;
      } else {
        print('Error extracting help keywords: ${utf8.decode(response.bodyBytes)}');
        // Trong trường hợp lỗi, sử dụng phương thức trích xuất từ khóa chung
        return _extractMainKeywords(message);
      }
    } catch (e) {
      print('Exception extracting help keywords: $e');
      // Trong trường hợp lỗi, sử dụng phương thức trích xuất từ khóa chung
      return _extractMainKeywords(message);
    }
  }
  
  // Phương thức mới: Phân loại tin nhắn bằng AI
  Future<String> _classifyMessage(String message) async {
    try {
      // Thử phân loại bằng Gemini API
      return await _classifyWithGemini(message);
    } catch (e) {
      print('Error classifying with Gemini: $e');
      // Fallback: Sử dụng phương pháp dựa trên pattern
      return _classifyWithPattern(message.toLowerCase());
    }
  }
  
  // Phân loại câu hỏi bằng Gemini API
  Future<String> _classifyWithGemini(String message) async {
    try {
      final url = _getGeminiApiUrl();
      
      final Map<String, String> categoryDescriptions = {
        'greeting': 'Lời chào hỏi, bắt đầu cuộc trò chuyện',
        'farewell': 'Lời tạm biệt, kết thúc cuộc trò chuyện',
        'product_search': 'Tìm kiếm hoặc hỏi về giá của sản phẩm cụ thể',
        'help': 'Yêu cầu hỗ trợ chung, hướng dẫn sử dụng các tính năng của ứng dụng (ví dụ: cách bán hàng, cách tạo tài khoản, nút tìm kiếm ở đâu, v.v.',
        'talk_to_user': 'Trò chuyện, tâm sự, chia sẻ cảm xúc, suy nghĩ với người dùng, giúp đỡ về mặt tinh thần',
        'unknown': 'Không thuộc các danh mục trên' // Vẫn giữ cái này trong map gốc nếu cần xử lý sau
      };
      
      // Tạo prompt cấu trúc rõ ràng
      final StringBuffer categoriesText = StringBuffer();
      categoryDescriptions.forEach((category, description) {
        if (category != 'unknown') { // Không đưa 'unknown' vào danh sách lựa chọn
          categoriesText.writeln('- $category: $description');
        }
      });
      
      final prompt = '''Phân loại tin nhắn dưới đây vào một trong các danh mục sau:

$categoriesText

Tin nhắn: "$message"

Phân tích: Hãy phân tích tin nhắn và xác định danh mục phù hợp nhất.
Kết quả: Chỉ trả về tên danh mục (không có dấu ngoặc, không có giải thích thêm).''';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
        encoding: Encoding.getByName('utf-8'),
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': prompt
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 10,
          }
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        String category = data['candidates'][0]['content']['parts'][0]['text'].trim().toLowerCase();
        
        // Xử lý kết quả cẩn thận hơn
        // Loại bỏ tiền tố như "danh mục:", "category:", v.v.
        final colonIndex = category.indexOf(':');
        if (colonIndex >= 0) {
          category = category.substring(colonIndex + 1).trim();
        }
        
        // Loại bỏ các ký tự đặc biệt và dấu ngoặc
        category = category.replaceAll(RegExp(r'[^a-z_]'), '');
        
        // Kiểm tra xem category có trong danh sách không
        if (categoryDescriptions.containsKey(category)) {
          print('Message classified as: $category');
          return category;
        } else {
          // Tìm key gần đúng nhất
          String bestMatch = 'unknown';
          int highestSimilarity = 0;
          
          for (final key in categoryDescriptions.keys) {
            // Đếm số ký tự trùng khớp
            int similarity = 0;
            for (int i = 0; i < key.length && i < category.length; i++) {
              if (key[i] == category[i]) similarity++;
            }
            
            if (similarity > highestSimilarity) {
              highestSimilarity = similarity;
              bestMatch = key;
            }
          }
          
          // Nếu mức độ tương đồng quá thấp, trả về unknown
          if (highestSimilarity < 3 && bestMatch != 'unknown') {
            print('Message classified as: unknown (best match was too weak)');
            return 'unknown';
          }
          
          print('Message classified as: $bestMatch (best match for "$category")');
          return bestMatch;
        }
      } else {
        print('Error calling Gemini API: ${utf8.decode(response.bodyBytes)}');
        return _classifyWithPattern(message.toLowerCase());
      }
    } catch (e) {
      print('Exception in _classifyWithGemini: $e');
      return _classifyWithPattern(message.toLowerCase());
    }
  }
  
  // Phân loại câu hỏi bằng pattern (phương pháp dự phòng)
  String _classifyWithPattern(String lowerCaseMessage) {
    // Tính điểm cho mỗi danh mục
    final Map<String, int> scores = {};
    
    _questionCategories.forEach((category, patterns) {
      int score = 0;
      for (final pattern in patterns) {
        if (lowerCaseMessage.contains(pattern)) {
          // Từ ngắn (dưới 4 ký tự) có thể là trùng hợp, nên có điểm thấp hơn
          score += (pattern.length >= 4) ? 2 : 1;
        }
      }
      scores[category] = score;
    });
    
    // Tìm danh mục có điểm cao nhất
    String bestCategory = 'unknown';
    int highestScore = 0;
    
    scores.forEach((category, score) {
      if (score > highestScore) {
        highestScore = score;
        bestCategory = category;
      }
    });
    
    // Nếu điểm cao nhất là 0, không danh mục nào phù hợp
    return (highestScore > 0) ? bestCategory : 'unknown';
  }
  
  // Lấy ngẫu nhiên câu chào đáp lại
  String _getRandomGreetingResponse() {
    final responses = [
      'Xin chào! Tôi có thể giúp gì cho bạn?',
      'Chào bạn! Bạn cần tìm kiếm gì trong Student Market?',
      'Chào bạn! Tôi có thể giúp bạn tìm kiếm sản phẩm hoặc giải đáp thắc mắc.',
      'Xin chào! Hôm nay bạn muốn tìm kiếm gì?'
    ];
    return responses[DateTime.now().millisecond % responses.length];
  }
  
  // Lấy ngẫu nhiên câu tạm biệt
  String _getRandomFarewellResponse() {
    final responses = [
      'Tạm biệt! Hẹn gặp lại bạn.',
      'Chào bạn, hẹn gặp lại.',
      'Tạm biệt! Cảm ơn bạn đã sử dụng Student Market.',
      'Chúc bạn một ngày tốt lành. Hẹn gặp lại!'
    ];
    return responses[DateTime.now().millisecond % responses.length];
  }
  
  // Các phương thức xử lý mới cho các danh mục câu hỏi
  Future<void> _handleAccountQuestion(String message) async {
    try {
      // Sử dụng trực tiếp message của người dùng cho tìm kiếm
      final relevantDocs = await _searchHelpDocuments(message);
      if (relevantDocs.isNotEmpty) {
        final document = relevantDocs.firstWhere(
          (doc) => doc.category == 'account',
          orElse: () => relevantDocs.first,
        );
        final response = await _generateHelpResponse(message, document);
        _addBotHelpMessage(response, document);
      } else {
        await _generateRAGResponse(message);
      }
    } catch (e) {
      print('Error handling account question: $e');
      _addBotTextMessage('Xin lỗi, đã có lỗi xảy ra khi xử lý yêu cầu về tài khoản. Vui lòng thử lại sau.');
    }
  }
  
  Future<void> _handleOrderQuestion(String message) async {
    try {
      final relevantDocs = await _searchHelpDocuments(message);
      if (relevantDocs.isNotEmpty) {
        final document = relevantDocs.firstWhere(
          (doc) => doc.category == 'order',
          orElse: () => relevantDocs.first,
        );
        final response = await _generateHelpResponse(message, document);
        _addBotHelpMessage(response, document);
      } else {
        await _generateRAGResponse(message);
      }
    } catch (e) {
      print('Error handling order question: $e');
      _addBotTextMessage('Xin lỗi, đã có lỗi xảy ra khi xử lý yêu cầu về đơn hàng. Vui lòng thử lại sau.');
    }
  }
  
  Future<void> _handleReviewQuestion(String message) async {
    try {
      final relevantDocs = await _searchHelpDocuments(message);
      if (relevantDocs.isNotEmpty) {
        final document = relevantDocs.firstWhere(
          (doc) => doc.category == 'review',
          orElse: () => relevantDocs.first,
        );
        final response = await _generateHelpResponse(message, document);
        _addBotHelpMessage(response, document);
      } else {
        await _generateRAGResponse(message);
      }
    } catch (e) {
      print('Error handling review question: $e');
      _addBotTextMessage('Xin lỗi, đã có lỗi xảy ra khi xử lý yêu cầu về đánh giá. Vui lòng thử lại sau.');
    }
  }
  
  Future<void> _handleChatQuestion(String message) async {
    try {
      final relevantDocs = await _searchHelpDocuments(message);
      if (relevantDocs.isNotEmpty) {
        final document = relevantDocs.firstWhere(
          (doc) => doc.category == 'chat',
          orElse: () => relevantDocs.first,
        );
        final response = await _generateHelpResponse(message, document);
        _addBotHelpMessage(response, document);
      } else {
        await _generateRAGResponse(message);
      }
    } catch (e) {
      print('Error handling chat question: $e');
      _addBotTextMessage('Xin lỗi, đã có lỗi xảy ra khi xử lý yêu cầu về tin nhắn. Vui lòng thử lại sau.');
    }
  }
  
  // Thêm tin nhắn phản hồi văn bản từ bot
  void _addBotTextMessage(String content) {
    final botMessage = ChatMessage(
      id: uuid.v4(),
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
    );
    
    _messages.add(botMessage);
    notifyListeners();
  }
  
  // Thêm tin nhắn phản hồi sản phẩm từ bot
  void _addBotProductMessage(String content, Product product) {
    final botMessage = ChatMessage(
      id: uuid.v4(),
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.product,
      metadata: {
        'productId': product.id,
        'productName': product.title,
        'productImage': product.images.isNotEmpty ? product.images[0] : '',
        'productPrice': product.price,
        'productDescription': product.description,
      },
    );
    
    _messages.add(botMessage);
    notifyListeners();
  }
  
  // Thêm tin nhắn phản hồi trợ giúp từ bot
  void _addBotHelpMessage(String content, KnowledgeDocument document) {
    final botMessage = ChatMessage(
      id: uuid.v4(),
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.help,
      metadata: {
        'documentId': document.id,
        'documentTitle': document.title,
        'documentCategory': document.category,
      },
    );
    
    _messages.add(botMessage);
    notifyListeners();
  }
  
  // Xử lý tìm kiếm sản phẩm
  Future<void> _handleProductSearch(String message, [List<String>? keywords]) async {
    try {
      List<Product> products = [];
      
      // Sử dụng từ khóa nếu có
      final searchQuery = keywords != null && keywords.isNotEmpty
          ? '${message} ${keywords.join(' ')}'
          : message;
      
      // Sử dụng Cloud Function để tìm kiếm sản phẩm
      try {
        final result = await _functions.httpsCallable('searchProductsByText').call({
          'query': searchQuery,
          'limit': 5,
        });
        
        if (result.data != null && result.data['results'] != null) {
          final List<dynamic> searchResults = result.data['results'];
          products = searchResults.map((item) {
            return Product(
              id: item['id'] ?? '',
              title: item['title'] ?? 'Sản phẩm',
              description: item['description'] ?? '',
              category: item['category'] ?? 'Khác',
              price: double.tryParse(item['price'].toString()) ?? 0.0,
              sellerId: item['sellerId'] ?? 'unknown',
              sellerName: item['sellerName'] ?? 'Người bán',
              createdAt: DateTime.now(),
              images: item['imageUrl'] != null ? [item['imageUrl']] : 
                      item['thumbnailUrl'] != null ? [item['thumbnailUrl']] : [],
              tags: item['tags'] != null ? List<String>.from(item['tags']) : [],
              condition: item['condition'] ?? 'Chưa xác định',
              location: item['location'] ?? '',
              isSold: false,
              status: ProductStatus.available,
            );
          }).toList();
        }
      } catch (e) {
        print('Error using searchProductsByText: $e');
        
        // Fallback: Sử dụng tìm kiếm từ local
        products = await _searchProductsWithKeywords(searchQuery);
      }
      
      if (products.isEmpty) {
        _addBotTextMessage('Xin lỗi, tôi không tìm thấy sản phẩm nào phù hợp với yêu cầu của bạn.');
        return;
      }
      
      // Đánh giá sản phẩm với AI để xác định mức độ phù hợp
      final relevantProducts = await _evaluateProductRelevance(message, products, keywords);
      
      if (relevantProducts.isEmpty) {
        _addBotTextMessage('Xin lỗi, tôi không tìm thấy sản phẩm nào thực sự phù hợp với yêu cầu của bạn.');
        return;
      }
      
      // Tạo tin nhắn hiển thị danh sách sản phẩm theo dạng trượt ngang
      _addBotProductListMessage('Đây là các sản phẩm phù hợp với yêu cầu của bạn:', relevantProducts);
      
    } catch (e) {
      print('Error in product search: $e');
      _addBotTextMessage('Xin lỗi, đã có lỗi xảy ra khi tìm kiếm sản phẩm. Vui lòng thử lại sau.');
    }
  }
  
  // Thêm phương thức mới để hiển thị danh sách sản phẩm theo dạng trượt ngang
  void _addBotProductListMessage(String content, List<Product> products) {
    final botMessage = ChatMessage(
      id: uuid.v4(),
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.productList,
      metadata: {
        'products': products.map((product) => {
          'productId': product.id,
          'productName': product.title,
          'productImage': product.images.isNotEmpty ? product.images[0] : '',
          'productPrice': product.price,
          'productDescription': product.description,
          'productCategory': product.category,
          'productCondition': product.condition,
          'productLocation': product.location,
          'productSellerName': product.sellerName,
          'productTags': product.tags,
        }).toList(),
      },
    );
    
    _messages.add(botMessage);
    notifyListeners();
  }
  
  // Xử lý yêu cầu trợ giúp
  Future<void> _handleHelpRequest(String message, [List<String>? keywords]) async {
    try {
      // Tìm kiếm tài liệu trợ giúp từ Firestore
      final helpDocuments = await _searchHelpDocuments(message, keywords);
      
      if (helpDocuments.isEmpty) {
        _addBotTextMessage('Xin lỗi, tôi không tìm thấy thông tin hướng dẫn phù hợp. Bạn có thể mô tả chi tiết hơn?');
        return;
      }
      
      // Đánh giá mức độ phù hợp của tất cả tài liệu và lưu lại kết quả
      List<Map<String, dynamic>> relevanceScores = [];
      
      // Lấy tối đa 5 tài liệu đầu tiên để đánh giá
      final documentsToEvaluate = helpDocuments.take(5).toList();
      
      for (final document in documentsToEvaluate) {
        final relevanceScore = await _evaluateHelpRelevance(message, document, keywords);
        relevanceScores.add({
          'document': document,
          'score': relevanceScore,
        });
      }
      
      // Lọc ra những tài liệu có điểm cao (từ 6 trở lên)
      final relevantDocuments = relevanceScores
          .where((item) => (item['score'] as double) >= 0.0)
          .toList();
      
      if (relevantDocuments.isEmpty) {
        _addBotTextMessage('Xin lỗi, hiện tại tôi không có thông tin phù hợp để trả lời câu hỏi của bạn.');
        return;
      }
      
      // Sắp xếp theo điểm từ cao đến thấp
      relevantDocuments.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
      
      // Sử dụng tài liệu có điểm cao nhất để tạo câu trả lời
      final bestDocument = relevantDocuments.first['document'] as KnowledgeDocument;
      final response = await _generateHelpResponse(message, bestDocument, keywords);
      
      _addBotHelpMessage(response, bestDocument);
      
    } catch (e) {
      print('Error in help request: $e');
      _addBotTextMessage('Xin lỗi, đã có lỗi xảy ra khi xử lý yêu cầu trợ giúp. Vui lòng thử lại sau.');
    }
  }
  
  // Trích xuất từ khóa từ văn bản sử dụng Gemini
  Future<List<String>> _extractKeywords(String text) async {
    try {
      final url = _getGeminiApiUrl();
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
        encoding: Encoding.getByName('utf-8'),
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': 'Trích xuất các từ khóa tìm kiếm sản phẩm từ câu hỏi sau đây. Trả về dưới dạng danh sách các từ khóa, cách nhau bởi dấu phẩy, không có các từ thừa: $text'
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.2,
            'maxOutputTokens': 100,
          }
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Phân tách các từ khóa bằng dấu phẩy
        final keywords = content.split(',')
            .map((keyword) => keyword.trim())
            .where((keyword) => keyword.isNotEmpty)
            .toList();
            
        return keywords;
      } else {
        print('Error extracting keywords: ${utf8.decode(response.bodyBytes)}');
        
        // Fallback: Tách từ trong câu và lọc các từ có ít nhất 3 ký tự
        return text.split(' ')
            .where((word) => word.trim().length > 2)
            .toList();
      }
    } catch (e) {
      print('Exception extracting keywords: $e');
      
      // Fallback: Tách từ trong câu và lọc các từ có ít nhất 3 ký tự
      return text.split(' ')
          .where((word) => word.trim().length > 2)
          .toList();
    }
  }
  
  // Tìm kiếm tài liệu trợ giúp từ Firestore và Pinecone
  Future<List<KnowledgeDocument>> _searchHelpDocuments(String query, [List<String>? keywords]) async {
    try {
      List<KnowledgeDocument> documents = [];
      
      // Sử dụng từ khóa nếu có
      final searchQuery = keywords != null && keywords.isNotEmpty
          ? '${query} ${keywords.join(' ')}'
          : query;
      
      // Nếu Pinecone đã được khởi tạo, sử dụng tìm kiếm ngữ nghĩa
      if (_isPineconeInitialized) {
        final searchResults = await _findSimilarItemsInPinecone(searchQuery, topK: 3);
        documents = searchResults['documents'] as List<KnowledgeDocument>;
      }
      
      // Nếu không tìm thấy kết quả từ Pinecone hoặc Pinecone chưa khởi tạo, sử dụng tìm kiếm từ Firestore
      if (documents.isEmpty) {
        documents = await _searchHelpDocumentsFromFirestore(searchQuery);
      }
      
      // Nếu vẫn không tìm thấy kết quả, sử dụng mock data
      if (documents.isEmpty) {
        documents = _getMockHelpDocuments();
      }
      
      return documents;
    } catch (e) {
      print('Error searching help documents: $e');
      return _getMockHelpDocuments();
    }
  }
  
  // Tìm kiếm tài liệu từ Firestore
  Future<List<KnowledgeDocument>> _searchHelpDocumentsFromFirestore(String query) async {
    try {
      final snapshot = await _firestore.collection('knowledge_documents').get();
      
      final documents = snapshot.docs.map((doc) {
        return KnowledgeDocument.fromMap(doc.data(), doc.id);
      }).toList();
      
      // Nếu có dữ liệu trong Firestore thì sử dụng chúng
      if (documents.isNotEmpty) {
        // Lưu các tài liệu vào Pinecone nếu Pinecone đã được khởi tạo
        if (_isPineconeInitialized) {
          for (final doc in documents) {
            _storeDocumentInPinecone(doc); // Không cần đợi kết quả
          }
        }
        
        // Tìm kiếm dựa trên từ khóa
        final lowerQuery = query.toLowerCase();
        return documents.where((doc) {
          final searchText = '${doc.title.toLowerCase()} ${doc.content.toLowerCase()} ${doc.category.toLowerCase()}';
          final keywordsMatch = doc.keywords.any((keyword) => 
              keyword.toLowerCase().contains(lowerQuery) || 
              lowerQuery.contains(keyword.toLowerCase()));
          return searchText.contains(lowerQuery) || keywordsMatch;
        }).toList();
      }
      
      return [];
    } catch (e) {
      print('Error searching help documents from Firestore: $e');
      return [];
    }
  }
  
  // Trả về mock data cho tài liệu trợ giúp
  List<KnowledgeDocument> _getMockHelpDocuments() {
    return [
      KnowledgeDocument(
        id: '1',
        title: 'Cách đăng ký tài khoản',
        content: 'Để đăng ký tài khoản, hãy làm theo các bước sau:\n\n1. Mở ứng dụng Student Market NTTU\n2. Nhấn vào nút "Đăng ký" ở màn hình đăng nhập\n3. Điền thông tin cá nhân, email và mật khẩu\n4. Xác nhận email để hoàn tất đăng ký',
        category: 'account',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      KnowledgeDocument(
        id: '2',
        title: 'Cách đăng sản phẩm',
        content: 'Để đăng sản phẩm bán, hãy làm theo các bước sau:\n\n1. Đăng nhập vào tài khoản của bạn\n2. Nhấn vào nút "+" ở góc dưới màn hình\n3. Chọn "Đăng sản phẩm"\n4. Điền thông tin sản phẩm, giá cả, và tải ảnh lên\n5. Nhấn "Đăng" để hoàn tất',
        category: 'product',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
  
  // Đánh giá mức độ phù hợp của tài liệu trợ giúp sử dụng AI
  Future<double> _evaluateHelpRelevance(String query, KnowledgeDocument document, [List<String>? keywords]) async {
    try {
      final url = _getGeminiApiUrl();
      
      // Tạo phần từ khóa nếu có
      final keywordsText = keywords != null && keywords.isNotEmpty
          ? '\nTừ khóa chính: ${keywords.join(', ')}'
          : '';
      
      final prompt = '''Đánh giá mức độ phù hợp của tài liệu trợ giúp với câu hỏi của người dùng.
Câu hỏi: "$query"$keywordsText

Tài liệu:
Tiêu đề: ${document.title}
Nội dung: ${document.content}
Danh mục: ${document.category}

Xác định mức độ phù hợp của tài liệu với câu hỏi của người dùng trên thang điểm từ 0 đến 10.
Trả về duy nhất một số từ 0-10, không có giải thích.
Trong đó:
0-3: Hoàn toàn không liên quan
4-6: Có liên quan một phần
7-10: Rất phù hợp hoặc trả lời trực tiếp câu hỏi''';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
        encoding: Encoding.getByName('utf-8'),
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': prompt
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 10,
          }
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final String result = data['candidates'][0]['content']['parts'][0]['text'].trim();
        
        // Trích xuất giá trị số từ kết quả
        final match = RegExp(r'\d+\.?\d*').firstMatch(result);
        if (match != null) {
          final score = double.tryParse(match.group(0) ?? '0') ?? 0;
          // Giới hạn điểm từ 0-10
          return score > 10 ? 10 : (score < 0 ? 0 : score);
        }
        
        // Fallback cho các trường hợp không trích xuất được số
        if (result.toLowerCase().contains('phù hợp') || 
            result.toLowerCase().contains('liên quan')) {
          return 7.0;
        }
        
        return 0.0;
      } else {
        print('Error evaluating help relevance: ${utf8.decode(response.bodyBytes)}');
        // Trong trường hợp lỗi, mặc định là điểm trung bình
        return 5.0;
      }
    } catch (e) {
      print('Exception evaluating help relevance: $e');
      // Trong trường hợp lỗi, mặc định là điểm trung bình
      return 5.0;
    }
  }

  // Tạo câu trả lời cho yêu cầu trợ giúp sử dụng Gemini
  Future<String> _generateHelpResponse(String query, KnowledgeDocument document, [List<String>? keywords]) async {
    try {
      final url = _getGeminiApiUrl();
      
      // Tạo phần từ khóa nếu có
      final keywordsText = keywords != null && keywords.isNotEmpty
          ? '\nTừ khóa chính: ${keywords.join(', ')}'
          : '';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
        encoding: Encoding.getByName('utf-8'),
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': '''Sử dụng thông tin từ tài liệu để trả lời câu hỏi của người dùng một cách lịch sự và hữu ích, bằng tiếng Việt.
Trả lời trực tiếp không bao gồm tựa đề, giới thiệu, hoặc kết luận. Không thêm "Trả lời:" hoặc bất kỳ tiêu đề nào vào phản hồi.
Chỉ cung cấp nội dung trả lời mạch lạc, rõ ràng, không thừa thãi.
Tập trung vào các từ khóa chính nếu được cung cấp.

Tài liệu: ${document.title}

${document.content}

Câu hỏi: $query$keywordsText'''
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 500,
          }
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        String text = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Loại bỏ tiêu đề thường gặp từ phản hồi của AI
        final patterns = [
          RegExp(r'^Trả lời:?\s*', caseSensitive: false),
          RegExp(r'^Dựa\s+(?:trên|vào)\s+(?:tài liệu|thông tin)[^:]*:?\s*', caseSensitive: false),
          RegExp(r'^Theo\s+(?:tài liệu|thông tin)[^:]*:?\s*', caseSensitive: false),
          RegExp(r'^Phản hồi:?\s*', caseSensitive: false),
        ];
        
        for (final pattern in patterns) {
          text = text.replaceFirst(pattern, '');
        }
        
        return text.trim();
      } else {
        print('Error generating help response: ${response.body}');
        return document.content;
      }
    } catch (e) {
      print('Exception generating help response: $e');
      return document.content;
    }
  }
  
  // Tạo câu trả lời bằng kỹ thuật RAG sử dụng Gemini
  Future<void> _generateRAGResponse(String query, [List<String>? keywords]) async {
    try {
      // Sử dụng phương thức mới có tích hợp ngữ cảnh cuộc trò chuyện
      await _generateRAGResponseWithContext(query, keywords);
    } catch (e) {
      print('Exception generating RAG response: $e');
      _addBotTextMessage('Xin lỗi, đã có lỗi xảy ra. Vui lòng thử lại sau.');
    }
  }
  
  // Thêm tính năng ghi nhớ ngữ cảnh cuộc trò chuyện
  Future<void> _generateRAGResponseWithContext(String query, [List<String>? keywords]) async {
    try {
      // Các bước được refactor thành các phương thức nhỏ với mục đích rõ ràng
      final conversationContext = _buildConversationContext();
      final helpContext = await _buildHelpContext(query, keywords);
      final productContext = await _buildProductContext(query, keywords);
      
      // Tổng hợp tất cả ngữ cảnh
      final completeContext = StringBuffer();
      completeContext.writeln(conversationContext);
      completeContext.writeln(helpContext);
      completeContext.writeln(productContext);
      
      // Tạo và gửi câu trả lời
      await _generateAndSendResponse(query, completeContext.toString(), keywords);
    } catch (e) {
      print('Exception generating contextualized response: $e');
      _addBotTextMessage('Xin lỗi, đã có lỗi xảy ra. Vui lòng thử lại sau.');
    }
  }
  
  // Xây dựng ngữ cảnh từ cuộc trò chuyện
  String _buildConversationContext() {
    // Lấy lịch sử trò chuyện (tối đa 5 tin nhắn gần nhất)
    final recentMessages = _messages
        .where((msg) => msg.type == MessageType.text)
        .toList()
        .reversed
        .take(5)
        .toList()
        .reversed
        .toList();
    
    // Tạo ngữ cảnh cuộc trò chuyện
    final StringBuffer conversationContext = StringBuffer();
    conversationContext.writeln('Ngữ cảnh cuộc trò chuyện:');
    for (final msg in recentMessages) {
      final role = msg.isUser ? 'Người dùng' : 'Bot';
      conversationContext.writeln('$role: ${msg.content}');
    }
    
    return conversationContext.toString();
  }
  
  // Xây dựng ngữ cảnh từ tài liệu trợ giúp
  Future<String> _buildHelpContext(String query, [List<String>? keywords]) async {
    final StringBuffer helpContext = StringBuffer();
    helpContext.writeln('Tài liệu liên quan:');
    
    // Sử dụng từ khóa nếu có
    final searchQuery = keywords != null && keywords.isNotEmpty
        ? '${query} ${keywords.join(' ')}'
        : query;
    
    // Tìm kiếm tài liệu liên quan
    final helpDocuments = await _searchHelpDocuments(searchQuery);
    
    // Thêm tài liệu trợ giúp nếu có
    if (helpDocuments.isNotEmpty) {
      for (final doc in helpDocuments.take(2)) {
        helpContext.writeln('Tiêu đề: ${doc.title}');
        helpContext.writeln('Nội dung: ${doc.content}\n');
      }
    } else {
      helpContext.writeln('Không tìm thấy tài liệu liên quan.');
    }
    
    return helpContext.toString();
  }
  
  // Xây dựng ngữ cảnh từ sản phẩm
  Future<String> _buildProductContext(String query, [List<String>? keywords]) async {
    final StringBuffer productContext = StringBuffer();
    productContext.writeln('Sản phẩm liên quan:');
    
    // Sử dụng từ khóa nếu có
    final searchQuery = keywords != null && keywords.isNotEmpty
        ? '${query} ${keywords.join(' ')}'
        : query;
    
    // Thêm thông tin về sản phẩm nếu có từ khóa liên quan
    List<Product> products = [];
    
    // Sử dụng Cloud Function để tìm kiếm sản phẩm
    try {
      final result = await _functions.httpsCallable('searchProductsByText').call({
        'query': searchQuery,
        'limit': 2,
      });
      
      if (result.data != null && result.data['results'] != null) {
        final List<dynamic> searchResults = result.data['results'];
        products = searchResults.map((item) {
          return Product(
            id: item['id'] ?? '',
            title: item['title'] ?? 'Sản phẩm',
            description: item['description'] ?? '',
            category: item['category'] ?? 'Khác',
            price: double.tryParse(item['price'].toString()) ?? 0.0,
            sellerId: item['sellerId'] ?? 'unknown',
            createdAt: DateTime.now(),
            images: item['imageUrl'] != null ? [item['imageUrl']] : [],
            tags: item['tags'] != null ? List<String>.from(item['tags']) : [],
            isSold: false,
            status: ProductStatus.available,
          );
        }).toList();
      }
    } catch (e) {
      print('Error using searchProductsByText for context: $e');
      
      // Fallback: Sử dụng tìm kiếm local
      final keywordsForSearch = keywords ?? await _extractKeywords(query);
      if (keywordsForSearch.isNotEmpty) {
        products = await _fetchProductsByKeywords(keywordsForSearch, limit: 2);
      }
    }
    
    if (products.isNotEmpty) {
      for (final product in products) {
        productContext.writeln('Tên: ${product.title}');
        productContext.writeln('Giá: ${product.price.toStringAsFixed(0)} VND');
        productContext.writeln('Mô tả: ${product.description}\n');
      }
    } else {
      productContext.writeln('Không tìm thấy sản phẩm liên quan.');
    }
    
    return productContext.toString();
  }
  
  // Tìm sản phẩm theo từ khóa
  Future<List<Product>> _fetchProductsByKeywords(List<String> keywords, {int limit = 2}) async {
    try {
      final productSnapshot = await _firestore
        .collection('products')
        .where('isSold', isEqualTo: false)
        .where('status', whereNotIn: ['pending_review', 'rejected'])
        .limit(limit * 2) // Lấy nhiều hơn một chút để lọc
        .get();
        
      final products = productSnapshot.docs
        .map((doc) => Product.fromMap(doc.data(), doc.id))
        .where((product) {
          final productData = '${product.title.toLowerCase()} ${product.description.toLowerCase()} ${product.category.toLowerCase()} ${product.tags.join(' ').toLowerCase()}';
          return keywords.any((keyword) => productData.contains(keyword.toLowerCase()));
        })
        .take(limit)
        .toList();
      
      // Lưu sản phẩm vào Pinecone nếu có thể
      if (_isPineconeInitialized) {
        for (final product in products) {
          _storeProductInPinecone(product); // Không cần đợi kết quả
        }
      }
        
      return products;
    } catch (e) {
      print('Error fetching products by keywords: $e');
      return [];
    }
  }
  
  // Tạo và gửi câu trả lời dựa trên ngữ cảnh
  Future<void> _generateAndSendResponse(String query, String context, [List<String>? keywords]) async {
    try {
      // Tạo phần từ khóa nếu có
      final keywordsText = keywords != null && keywords.isNotEmpty
          ? '\nTừ khóa chính: ${keywords.join(', ')}'
          : '';
      
      // Tạo câu trả lời từ Gemini
      final url = _getGeminiApiUrl();
      
      final prompt = '''Bạn là trợ lý ảo của Student Market NTTU, một sàn thương mại điện tử cho sinh viên.
Sử dụng thông tin từ ngữ cảnh và lịch sử cuộc trò chuyện để trả lời câu hỏi của người dùng một cách lịch sự và hữu ích bằng tiếng Việt.
Trả lời nên mạch lạc, đầy đủ và phù hợp với cuộc hội thoại đang diễn ra.
Trả lời trực tiếp không bao gồm tựa đề, giới thiệu, hoặc kết luận. Không thêm "Trả lời:" hoặc bất kỳ tiêu đề nào vào phản hồi.
Nếu được hỏi về sản phẩm, hãy cung cấp thông tin về giá, mô tả, và cách mua hàng.
Nếu được hỏi về cách sử dụng ứng dụng, hãy cung cấp hướng dẫn rõ ràng.
Nếu không có đủ thông tin, hãy nói rằng bạn không biết hoặc đề xuất người dùng đặt câu hỏi rõ ràng hơn.
Tập trung trả lời dựa trên các từ khóa chính được cung cấp.

Ngữ cảnh:
$context

Câu hỏi hiện tại: $query$keywordsText''';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
        encoding: Encoding.getByName('utf-8'),
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': prompt
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 500,
          }
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        String botResponse = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Loại bỏ tiêu đề thường gặp từ phản hồi của AI
        final patterns = [
          RegExp(r'^Trả lời:?\s*', caseSensitive: false),
          RegExp(r'^Dựa\s+(?:trên|vào)\s+(?:tài liệu|thông tin)[^:]*:?\s*', caseSensitive: false),
          RegExp(r'^Theo\s+(?:tài liệu|thông tin)[^:]*:?\s*', caseSensitive: false),
          RegExp(r'^Phản hồi:?\s*', caseSensitive: false),
        ];
        
        for (final pattern in patterns) {
          botResponse = botResponse.replaceFirst(pattern, '');
        }
        
        _addBotTextMessage(botResponse.trim());
      } else {
        print('Error generating response: ${response.statusCode} - ${response.body}');
        _addBotTextMessage('Xin lỗi, tôi không thể xử lý yêu cầu của bạn lúc này. Vui lòng thử lại sau.');
      }
    } catch (e) {
      print('Exception generating response: $e');
      _addBotTextMessage('Xin lỗi, đã có lỗi xảy ra. Vui lòng thử lại sau.');
    }
  }
  
  // Xóa tất cả tin nhắn
  void clearMessages() {
    _messages.clear();
    _addWelcomeMessage();
    notifyListeners();
  }
  
  // Thêm phương thức để cập nhật ProductService
  void updateProductService(ProductService productService) {
    _productService = productService;
  }

  // Helper để tạo URL API đầy đủ
  String _getGeminiApiUrl() {
    final baseUrl = _geminiApiUrl.trim();
    // Kiểm tra nếu URL đã có protocol (http:// hoặc https://)
    if (baseUrl.startsWith('http://') || baseUrl.startsWith('https://')) {
      if (baseUrl.endsWith('/')) {
        return '$baseUrl$_geminiModel:generateContent?key=$_geminiApiKey';
      } else {
        return '$baseUrl/$_geminiModel:generateContent?key=$_geminiApiKey';
      }
    } else {
      // Nếu không có protocol, thêm https:// vào đầu
      return 'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent?key=$_geminiApiKey';
    }
  }

  // Tạo embedding vector từ text sử dụng Gemini API
  Future<List<double>> _createEmbedding(String text) async {
    try {
      // Sử dụng API để tạo embedding
      final url = 'https://generativelanguage.googleapis.com/v1beta/models/embedding-001:embedContent?key=$_geminiApiKey';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
        encoding: Encoding.getByName('utf-8'),
        body: jsonEncode({
          'model': 'embedding-001',
          'content': {
            'parts': [
              {
                'text': text
              }
            ]
          },
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final embedding = data['embedding']['values'] as List;
        return embedding.map((value) => value as double).toList();
      } else {
        print('Error creating embedding: ${response.statusCode} - ${utf8.decode(response.bodyBytes)}');
        // Trả về vector rỗng trong trường hợp lỗi
        return [];
      }
    } catch (e) {
      print('Exception creating embedding: $e');
      return [];
    }
  }
  
  // Lưu trữ tài liệu vào Pinecone
  Future<bool> _storeDocumentInPinecone(KnowledgeDocument document) async {
    if (!_isPineconeInitialized) {
      print('Pinecone not initialized, cannot store document');
      return false;
    }
    
    try {
      // Tạo embedding cho tài liệu
      final documentText = '${document.title}. ${document.content}. Danh mục: ${document.category}';
      final embedding = await _createEmbedding(documentText);
      
      if (embedding.isEmpty) {
        print('Failed to create embedding for document');
        return false;
      }
      
      // Lưu vào Pinecone qua API
      final url = '$_pineconeApiUrl/vectors/upsert';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
          'Api-Key': _pineconeApiKey,
        },
        encoding: Encoding.getByName('utf-8'),
        body: jsonEncode({
          'vectors': [
            {
              'id': 'doc_${document.id}',
              'values': embedding,
              'metadata': {
                'type': 'document',
                'id': document.id,
                'title': document.title,
                'category': document.category,
                'content': document.content,
              },
            },
          ],
        }),
      );
      
      if (response.statusCode == 200) {
        print('Document stored in Pinecone: ${document.id}');
        return true;
      } else {
        print('Error storing document in Pinecone: ${response.statusCode} - ${utf8.decode(response.bodyBytes)}');
        return false;
      }
    } catch (e) {
      print('Error storing document in Pinecone: $e');
      return false;
    }
  }
  
  // Lưu trữ sản phẩm vào Pinecone
  Future<bool> _storeProductInPinecone(Product product) async {
    if (!_isPineconeInitialized) {
      print('Pinecone not initialized, cannot store product');
      return false;
    }
    
    try {
      // Tạo embedding cho sản phẩm
      final productText = '${product.title}. ${product.description}. Danh mục: ${product.category}. Tags: ${product.tags.join(', ')}';
      final embedding = await _createEmbedding(productText);
      
      if (embedding.isEmpty) {
        print('Failed to create embedding for product');
        return false;
      }
      
      // Lưu vào Pinecone qua API
      final url = '$_pineconeApiUrl/vectors/upsert';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
          'Api-Key': _pineconeApiKey,
        },
        encoding: Encoding.getByName('utf-8'),
        body: jsonEncode({
          'vectors': [
            {
              'id': 'prod_${product.id}',
              'values': embedding,
              'metadata': {
                'type': 'product',
                'id': product.id,
                'title': product.title,
                'description': product.description,
                'category': product.category,
                'price': product.price.toString(),
                'originalPrice': product.originalPrice.toString(),
                'imageUrl': product.images.isNotEmpty ? product.images[0] : '',
                'thumbnailUrl': product.images.isNotEmpty ? product.images[0] : '',
                'tags': product.tags,
                'condition': product.condition,
                'location': product.location,
                'specifications': _mapToStringMap(product.specifications),
                'sellerId': product.sellerId,
                'sellerName': product.sellerName,
                'isSold': product.isSold,
                'status': product.status.toString().split('.').last,
                'viewCount': product.viewCount,
                'favoriteCount': product.favoriteCount,
                'createdAt': product.createdAt.toIso8601String(),
              },
            },
          ],
        }),
      );
      
      if (response.statusCode == 200) {
        print('Product stored in Pinecone: ${product.id}');
        return true;
      } else {
        print('Error storing product in Pinecone: ${response.statusCode} - ${utf8.decode(response.bodyBytes)}');
        return false;
      }
    } catch (e) {
      print('Error storing product in Pinecone: $e');
      return false;
    }
  }
  
  // Phương thức hỗ trợ chuyển đổi map sang dạng chuỗi
  Map<String, String> _mapToStringMap(Map<String, dynamic> map) {
    final result = <String, String>{};
    map.forEach((key, value) {
      result[key] = value.toString();
    });
    return result;
  }
  
  // Tìm kiếm tài liệu và sản phẩm tương tự trong Pinecone
  Future<Map<String, List<dynamic>>> _findSimilarItemsInPinecone(String query, {int topK = 5}) async {
    if (!_isPineconeInitialized) {
      print('Pinecone not initialized, cannot search for similar items');
      return {'documents': [], 'products': []};
    }
    
    try {
      // Tạo embedding cho câu truy vấn
      final queryEmbedding = await _createEmbedding(query);
      
      if (queryEmbedding.isEmpty) {
        print('Failed to create embedding for query');
        return {'documents': [], 'products': []};
      }
      
      // Kết quả tìm kiếm
      List<KnowledgeDocument> documents = [];
      List<Product> products = [];
      
      // Tìm kiếm tài liệu trong namespace knowledge
      await _searchInNamespace('knowledge', queryEmbedding, topK).then((matches) {
        for (final match in matches) {
          final metadata = match['metadata'];
          if (metadata != null) {
            documents.add(KnowledgeDocument(
              id: metadata['id'],
              title: metadata['title'],
              content: metadata['content'],
              category: metadata['category'],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              keywords: [],
            ));
          }
        }
      });
      
      // Tìm kiếm sản phẩm sử dụng Cloud Function
      try {
        final result = await _functions.httpsCallable('findSimilarProducts').call({
          'query': query,
          'limit': topK,
        });
        
        if (result.data != null && result.data['products'] != null) {
          final List<dynamic> searchResults = result.data['products'];
          products = searchResults.map((item) {
            return Product(
              id: item['id'] ?? '',
              title: item['title'] ?? 'Sản phẩm',
              description: item['description'] ?? '',
              category: item['category'] ?? 'Khác',
              price: double.tryParse(item['price'].toString()) ?? 0.0,
              sellerId: item['sellerId'] ?? 'unknown',
              createdAt: DateTime.now(),
              images: item['imageUrl'] != null ? [item['imageUrl']] : [],
              tags: item['tags'] != null ? List<String>.from(item['tags']) : [],
              isSold: false,
              status: ProductStatus.available,
            );
          }).toList();
        }
      } catch (e) {
        print('Error using findSimilarProducts: $e');
      }
      
      return {
        'documents': documents,
        'products': products,
      };
    } catch (e) {
      print('Error finding similar items in Pinecone: $e');
      return {'documents': [], 'products': []};
    }
  }
  
  // Tìm kiếm trong namespace cụ thể
  Future<List<Map<String, dynamic>>> _searchInNamespace(String namespace, List<double> queryVector, int topK) async {
    try {
      final url = '$_pineconeApiUrl/query';
      
      // Tạo payload query mà không sử dụng namespace
      final Map<String, dynamic> payload = {
        'vector': queryVector,
        'topK': topK,
        'includeMetadata': true,
        'includeValues': false,
      };
      
      // Thêm bộ lọc type để thay thế cho namespace, không sử dụng metadata làm khóa ngoài
      if (namespace == 'knowledge') {
        payload['filter'] = {
          'type': 'document'
        };
      } else if (namespace == 'products') {
        payload['filter'] = {
          'type': 'product'
        };
      }
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
          'Api-Key': _pineconeApiKey,
        },
        encoding: Encoding.getByName('utf-8'),
        body: jsonEncode(payload),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return List<Map<String, dynamic>>.from(data['matches'] ?? []);
      } else {
        print('Error querying Pinecone: ${response.statusCode} - ${utf8.decode(response.bodyBytes)}');
        return [];
      }
    } catch (e) {
      print('Error searching in namespace $namespace: $e');
      return [];
    }
  }

  // Phương thức tìm kiếm sản phẩm bằng từ khóa (phương pháp cũ)
  Future<List<Product>> _searchProductsWithKeywords(String message) async {
    // Tìm kiếm các từ khóa sản phẩm từ câu hỏi
    final keywords = await _extractKeywords(message);
    
    // Lấy danh sách sản phẩm từ Firestore dựa trên từ khóa
    List<Product> products = [];
    for (final keyword in keywords) {
      final productSnapshot = await _firestore
        .collection('products')
        .where('isSold', isEqualTo: false)
        .where('status', whereNotIn: ['pending_review', 'rejected'])
        .get();
      
      final potentialProducts = productSnapshot.docs
        .map((doc) => Product.fromMap(doc.data(), doc.id))
        .where((product) {
          final productData = '${product.title.toLowerCase()} ${product.description.toLowerCase()} ${product.category.toLowerCase()} ${product.tags.join(' ').toLowerCase()}';
          return productData.contains(keyword.toLowerCase());
        })
        .toList();
      
      products.addAll(potentialProducts);
    }
    
    // Loại bỏ các sản phẩm trùng lặp
    final uniqueProductIds = <String>{};
    products = products.where((product) => uniqueProductIds.add(product.id)).toList();
    
    return products;
  }

  // Đánh giá mức độ phù hợp của sản phẩm sử dụng AI
  Future<List<Product>> _evaluateProductRelevance(String query, List<Product> products, [List<String>? keywords]) async {
    try {
      if (products.isEmpty) return [];
      
      final url = _getGeminiApiUrl();
      
      // Chuẩn bị danh sách sản phẩm để đánh giá
      final StringBuffer productListText = StringBuffer();
      for (int i = 0; i < products.length; i++) {
        final product = products[i];
        productListText.writeln('Sản phẩm ${i + 1}:');
        productListText.writeln('- Tên: ${product.title}');
        productListText.writeln('- Danh mục: ${product.category}');
        productListText.writeln('- Giá: ${product.price.toStringAsFixed(0)} VND');
        productListText.writeln('- Mô tả: ${product.description}');
        productListText.writeln('- Tình trạng: ${product.condition}');
        if (product.tags.isNotEmpty) {
          productListText.writeln('- Tags: ${product.tags.join(', ')}');
        }
        productListText.writeln('');
      }
      
      // Tạo phần từ khóa nếu có
      final keywordsText = keywords != null && keywords.isNotEmpty
          ? '\nTừ khóa chính: ${keywords.join(', ')}'
          : '';
      
      final prompt = '''Đánh giá mức độ phù hợp của các sản phẩm dưới đây đối với yêu cầu của người dùng.
Yêu cầu: "$query"$keywordsText

Danh sách sản phẩm:
$productListText

Hãy đánh giá mức độ phù hợp của mỗi sản phẩm với yêu cầu của người dùng, tập trung vào các từ khóa chính.
Trả về danh sách số thứ tự của các sản phẩm phù hợp, cách nhau bởi dấu phẩy.
Không đưa vào danh sách những sản phẩm không phù hợp với yêu cầu.
Chỉ trả về danh sách số (ví dụ: 1,3,5), không thêm giải thích.''';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
        encoding: Encoding.getByName('utf-8'),
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': prompt
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 50,
          }
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final String resultText = data['candidates'][0]['content']['parts'][0]['text'].trim();
        
        // Xử lý kết quả trả về để lấy danh sách số
        final List<int> relevantIndices = [];
        // Tìm tất cả số trong chuỗi kết quả 
        final matches = RegExp(r'\d+').allMatches(resultText);
        for (final match in matches) {
          final index = int.tryParse(match.group(0) ?? '');
          if (index != null && index >= 1 && index <= products.length) {
            relevantIndices.add(index - 1); // Chuyển từ 1-based index sang 0-based index
          }
        }
        
        // Nếu không có sản phẩm nào được xác định là phù hợp, trả về danh sách rỗng
        if (relevantIndices.isEmpty) return [];
        
        // Lấy các sản phẩm phù hợp
        return relevantIndices.map((index) => products[index]).toList();
      } else {
        print('Error evaluating product relevance: ${utf8.decode(response.bodyBytes)}');
        // Trong trường hợp lỗi, trả về toàn bộ danh sách sản phẩm gốc
        return products;
      }
    } catch (e) {
      print('Exception evaluating product relevance: $e');
      // Trong trường hợp lỗi, trả về toàn bộ danh sách sản phẩm gốc
      return products;
    }
  }
  

  // Phương thức mới để xử lý tâm sự với người dùng
  Future<void> _handleTalkToUser(String message) async {
    try {
      final url = _getGeminiApiUrl();
      
      final prompt = '''Bạn là trợ lý ảo của Student Market NTTU, một sàn thương mại điện tử cho sinh viên.
Người dùng đang muốn trò chuyện, tâm sự hoặc chia sẻ cảm xúc với bạn.
Hãy phản hồi một cách thấu hiểu, thân thiện và hỗ trợ tinh thần họ.
Trả lời trực tiếp bằng tiếng Việt, không thêm "Trả lời:" hay bất kỳ tiêu đề nào.

Tin nhắn của người dùng: "$message"''';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
        encoding: Encoding.getByName('utf-8'),
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': prompt
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.8,
            'maxOutputTokens': 500,
          }
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        String botResponse = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Loại bỏ tiêu đề thường gặp từ phản hồi của AI
        final patterns = [
          RegExp(r'^Trả lời:?\s*', caseSensitive: false),
          RegExp(r'^Phản hồi:?\s*', caseSensitive: false),
        ];
        
        for (final pattern in patterns) {
          botResponse = botResponse.replaceFirst(pattern, '');
        }
        
        _addBotTextMessage(botResponse.trim());
      } else {
        print('Error generating talk response: ${response.statusCode} - ${response.body}');
        _addBotTextMessage('Xin lỗi, tôi không thể trò chuyện lúc này. Bạn có thể chia sẻ sau được không?');
      }
    } catch (e) {
      print('Error handling talk to user: $e');
      _addBotTextMessage('Xin lỗi, đã có lỗi xảy ra. Vui lòng thử lại sau.');
    }
  }
} 