import 'dart:convert';
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
    'account': [
      'tài khoản', 'đăng ký', 'đăng nhập', 'password', 'mật khẩu', 'thông tin cá nhân', 'profile'
    ],
    'order': [
      'đơn hàng', 'đặt hàng', 'thanh toán', 'giao hàng', 'vận chuyển', 'order'
    ],
    'review': [
      'đánh giá', 'review', 'phản hồi', 'sao', 'nhận xét'
    ],
    'chat': [
      'tin nhắn', 'nhắn tin', 'liên hệ', 'chat', 'trò chuyện'
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
      // Sử dụng AI để phân loại câu hỏi thay vì kiểm tra pattern đơn giản
      final messageCategory = await _classifyMessage(message);
      
      switch (messageCategory) {
        case 'greeting':
          _addBotTextMessage(_getRandomGreetingResponse());
          break;
        case 'farewell':
          _addBotTextMessage(_getRandomFarewellResponse());
          break;
        case 'product_search':
          await _handleProductSearch(message);
          break;
        case 'help':
          await _handleHelpRequest(message);
          break;
        case 'account':
          await _handleAccountQuestion(message);
          break;
        case 'order':
          await _handleOrderQuestion(message);
          break;
        case 'review':
          await _handleReviewQuestion(message);
          break;
        case 'chat':
          await _handleChatQuestion(message);
          break;
        default:
          // Nếu không xác định được loại tin nhắn, sử dụng RAG để tạo phản hồi
          await _generateRAGResponse(message);
      }
    } catch (e) {
      print('Error processing message: $e');
      _addBotTextMessage('Xin lỗi, đã có lỗi xảy ra. Vui lòng thử lại sau.');
    } finally {
      _isLoading = false;
      notifyListeners();
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
      
      // Chuẩn bị danh sách category với mô tả
      final Map<String, String> categoryDescriptions = {
        'greeting': 'Lời chào hỏi, bắt đầu cuộc trò chuyện',
        'farewell': 'Lời tạm biệt, kết thúc cuộc trò chuyện',
        'product_search': 'Tìm kiếm, mua bán sản phẩm hoặc hỏi về giá cả',
        'help': 'Yêu cầu hỗ trợ, hướng dẫn sử dụng ứng dụng',
        'account': 'Thông tin tài khoản, đăng ký, đăng nhập, mật khẩu',
        'order': 'Đơn hàng, đặt hàng, thanh toán, giao hàng',
        'review': 'Đánh giá, nhận xét về sản phẩm hoặc dịch vụ',
        'chat': 'Tin nhắn, trò chuyện với người bán hoặc người dùng khác',
        'unknown': 'Không thuộc các danh mục trên'
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
          'Content-Type': 'application/json',
        },
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
        final data = jsonDecode(response.body);
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
        print('Error calling Gemini API: ${response.body}');
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
  Future<void> _handleProductSearch(String message) async {
    try {
      List<Product> products = [];
      
      // Sử dụng Cloud Function để tìm kiếm sản phẩm
      try {
        final result = await _functions.httpsCallable('searchProductsByText').call({
          'query': message,
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
        products = await _searchProductsWithKeywords(message);
      }
      
      if (products.isEmpty) {
        products = await _searchProductsWithKeywords(message);
      }
      
      if (products.isEmpty) {
        _addBotTextMessage('Xin lỗi, tôi không tìm thấy sản phẩm nào phù hợp với yêu cầu của bạn.');
        return;
      }
      
      // Lấy 5 sản phẩm phù hợp nhất
      final limitedProducts = products.take(5).toList();
      
      // Tạo tin nhắn hiển thị danh sách sản phẩm theo dạng trượt ngang
      _addBotProductListMessage('Đây là các sản phẩm phù hợp với yêu cầu của bạn:', limitedProducts);
      
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
  Future<void> _handleHelpRequest(String message) async {
    try {
      // Tìm kiếm tài liệu trợ giúp từ Firestore
      final helpDocuments = await _searchHelpDocuments(message);
      
      if (helpDocuments.isEmpty) {
        _addBotTextMessage('Xin lỗi, tôi không tìm thấy thông tin hướng dẫn phù hợp. Bạn có thể mô tả chi tiết hơn?');
        return;
      }
      
      // Sử dụng tài liệu tìm được để tạo câu trả lời
      final document = helpDocuments.first;
      final response = await _generateHelpResponse(message, document);
      
      _addBotHelpMessage(response, document);
      
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
          'Content-Type': 'application/json',
        },
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
        final data = jsonDecode(response.body);
        final content = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Phân tách các từ khóa bằng dấu phẩy
        final keywords = content.split(',')
            .map((keyword) => keyword.trim())
            .where((keyword) => keyword.isNotEmpty)
            .toList();
            
        return keywords;
      } else {
        print('Error extracting keywords: ${response.body}');
        
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
  Future<List<KnowledgeDocument>> _searchHelpDocuments(String query) async {
    try {
      List<KnowledgeDocument> documents = [];
      
      // Nếu Pinecone đã được khởi tạo, sử dụng tìm kiếm ngữ nghĩa
      if (_isPineconeInitialized) {
        final searchResults = await _findSimilarItemsInPinecone(query, topK: 3);
        documents = searchResults['documents'] as List<KnowledgeDocument>;
      }
      
      // Nếu không tìm thấy kết quả từ Pinecone hoặc Pinecone chưa khởi tạo, sử dụng tìm kiếm từ Firestore
      if (documents.isEmpty) {
        documents = await _searchHelpDocumentsFromFirestore(query);
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
  
  // Tạo câu trả lời cho yêu cầu trợ giúp sử dụng Gemini
  Future<String> _generateHelpResponse(String query, KnowledgeDocument document) async {
    try {
      final url = _getGeminiApiUrl();
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': 'Sử dụng thông tin từ tài liệu để trả lời câu hỏi của người dùng một cách lịch sự và hữu ích, bằng tiếng Việt.\n\nTài liệu: ${document.title}\n\n${document.content}\n\nCâu hỏi: $query'
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
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
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
  Future<void> _generateRAGResponse(String query) async {
    try {
      // Sử dụng phương thức mới có tích hợp ngữ cảnh cuộc trò chuyện
      await _generateRAGResponseWithContext(query);
    } catch (e) {
      print('Exception generating RAG response: $e');
      _addBotTextMessage('Xin lỗi, đã có lỗi xảy ra. Vui lòng thử lại sau.');
    }
  }
  
  // Thêm tính năng ghi nhớ ngữ cảnh cuộc trò chuyện
  Future<void> _generateRAGResponseWithContext(String query) async {
    try {
      // Các bước được refactor thành các phương thức nhỏ với mục đích rõ ràng
      final conversationContext = _buildConversationContext();
      final helpContext = await _buildHelpContext(query);
      final productContext = await _buildProductContext(query);
      
      // Tổng hợp tất cả ngữ cảnh
      final completeContext = StringBuffer();
      completeContext.writeln(conversationContext);
      completeContext.writeln(helpContext);
      completeContext.writeln(productContext);
      
      // Tạo và gửi câu trả lời
      await _generateAndSendResponse(query, completeContext.toString());
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
  Future<String> _buildHelpContext(String query) async {
    final StringBuffer helpContext = StringBuffer();
    helpContext.writeln('Tài liệu liên quan:');
    
    // Tìm kiếm tài liệu liên quan
    final helpDocuments = await _searchHelpDocuments(query);
    
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
  Future<String> _buildProductContext(String query) async {
    final StringBuffer productContext = StringBuffer();
    productContext.writeln('Sản phẩm liên quan:');
    
    // Thêm thông tin về sản phẩm nếu có từ khóa liên quan
    List<Product> products = [];
    
    // Sử dụng Cloud Function để tìm kiếm sản phẩm
    try {
      final result = await _functions.httpsCallable('searchProductsByText').call({
        'query': query,
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
      final keywords = await _extractKeywords(query);
      if (keywords.isNotEmpty) {
        products = await _fetchProductsByKeywords(keywords, limit: 2);
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
  Future<void> _generateAndSendResponse(String query, String context) async {
    try {
      // Tạo câu trả lời từ Gemini
      final url = _getGeminiApiUrl();
      
      final prompt = '''Bạn là trợ lý ảo của Student Market NTTU, một sàn thương mại điện tử cho sinh viên.
Sử dụng thông tin từ ngữ cảnh và lịch sử cuộc trò chuyện để trả lời câu hỏi của người dùng một cách lịch sự và hữu ích bằng tiếng Việt.
Trả lời nên mạch lạc, đầy đủ và phù hợp với cuộc hội thoại đang diễn ra.
Nếu được hỏi về sản phẩm, hãy cung cấp thông tin về giá, mô tả, và cách mua hàng.
Nếu được hỏi về cách sử dụng ứng dụng, hãy cung cấp hướng dẫn rõ ràng.
Nếu không có đủ thông tin, hãy nói rằng bạn không biết hoặc đề xuất người dùng đặt câu hỏi rõ ràng hơn.

Ngữ cảnh:
$context

Câu hỏi hiện tại: $query''';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
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
        final data = jsonDecode(response.body);
        final botResponse = data['candidates'][0]['content']['parts'][0]['text'];
        _addBotTextMessage(botResponse);
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
          'Content-Type': 'application/json',
        },
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
        final data = jsonDecode(response.body);
        final embedding = data['embedding']['values'] as List;
        return embedding.map((value) => value as double).toList();
      } else {
        print('Error creating embedding: ${response.statusCode} - ${response.body}');
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
          'Content-Type': 'application/json',
          'Api-Key': _pineconeApiKey,
        },
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
        print('Error storing document in Pinecone: ${response.statusCode} - ${response.body}');
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
          'Content-Type': 'application/json',
          'Api-Key': _pineconeApiKey,
        },
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
        print('Error storing product in Pinecone: ${response.statusCode} - ${response.body}');
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
      
      // Thêm bộ lọc metadata.type để thay thế cho namespace
      if (namespace == 'knowledge') {
        payload['filter'] = {
          'metadata': {
            'type': 'document'
          }
        };
      } else if (namespace == 'products') {
        payload['filter'] = {
          'metadata': {
            'type': 'product'
          }
        };
      }
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Api-Key': _pineconeApiKey,
        },
        body: jsonEncode(payload),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['matches'] ?? []);
      } else {
        print('Error querying Pinecone: ${response.statusCode} - ${response.body}');
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
} 