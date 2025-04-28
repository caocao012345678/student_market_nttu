import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../models/knowledge_base.dart';
import '../models/product.dart';
import './product_service.dart';

class ChatbotService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  ProductService _productService;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final uuid = Uuid();
  
  // Constant để lưu những tin nhắn chào hỏi mà bot sẽ phản hồi
  final List<String> _greetingPatterns = [
    'xin chào', 'chào', 'hello', 'hi', 'hey', 'chào bạn', 'xin chào bạn'
  ];
  
  // Constant để lưu những tin nhắn tạm biệt mà bot sẽ phản hồi
  final List<String> _farewellPatterns = [
    'tạm biệt', 'bye', 'goodbye', 'hẹn gặp lại', 'see you'
  ];
  
  // Constant để lưu các mẫu câu tìm kiếm sản phẩm
  final List<String> _productSearchPatterns = [
    'có bán', 'tìm', 'mua', 'sản phẩm', 'giá', 'cần', 'muốn mua'
  ];
  
  // Constant để lưu các mẫu câu hỏi về hướng dẫn sử dụng
  final List<String> _helpPatterns = [
    'hướng dẫn', 'cách', 'làm sao', 'làm thế nào', 'giúp', 'help'
  ];
  
  bool get isLoading => _isLoading;
  List<ChatMessage> get messages => _messages;
  
  // API URL và key từ environment variable
  String get _geminiApiUrl => dotenv.env['GEMINI_API_URL'] ?? 'https://generativelanguage.googleapis.com/v1beta/models';
  String get _geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  String get _geminiModel => dotenv.env['GEMINI_MODEL'] ?? '';

  ChatbotService(this._productService) {
    _addWelcomeMessage();
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
      final lowerCaseMessage = message.toLowerCase();
      
      // Kiểm tra nếu tin nhắn là lời chào
      if (_isGreeting(lowerCaseMessage)) {
        _addBotTextMessage(_getRandomGreetingResponse());
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Kiểm tra nếu tin nhắn là lời tạm biệt
      if (_isFarewell(lowerCaseMessage)) {
        _addBotTextMessage(_getRandomFarewellResponse());
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Kiểm tra nếu tin nhắn là tìm kiếm sản phẩm
      if (_isProductSearch(lowerCaseMessage)) {
        await _handleProductSearch(lowerCaseMessage);
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Kiểm tra nếu tin nhắn là hỏi về hướng dẫn sử dụng
      if (_isHelpRequest(lowerCaseMessage)) {
        await _handleHelpRequest(lowerCaseMessage);
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Nếu không xác định được loại tin nhắn, sử dụng RAG để tạo phản hồi
      await _generateRAGResponse(lowerCaseMessage);
      
    } catch (e) {
      print('Error processing message: $e');
      _addBotTextMessage('Xin lỗi, đã có lỗi xảy ra. Vui lòng thử lại sau.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Kiểm tra nếu tin nhắn là lời chào
  bool _isGreeting(String message) {
    return _greetingPatterns.any((pattern) => message.contains(pattern));
  }
  
  // Kiểm tra nếu tin nhắn là lời tạm biệt
  bool _isFarewell(String message) {
    return _farewellPatterns.any((pattern) => message.contains(pattern));
  }
  
  // Kiểm tra nếu tin nhắn là tìm kiếm sản phẩm
  bool _isProductSearch(String message) {
    return _productSearchPatterns.any((pattern) => message.contains(pattern));
  }
  
  // Kiểm tra nếu tin nhắn là hỏi về hướng dẫn sử dụng
  bool _isHelpRequest(String message) {
    return _helpPatterns.any((pattern) => message.contains(pattern));
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
  
  // Tìm kiếm tài liệu trợ giúp từ Firestore
  Future<List<KnowledgeDocument>> _searchHelpDocuments(String query) async {
    try {
      final snapshot = await _firestore.collection('knowledge_documents').get();
      
      final documents = snapshot.docs.map((doc) {
        return KnowledgeDocument.fromMap(doc.data(), doc.id);
      }).toList();
      
      // Nếu có dữ liệu trong Firestore thì sử dụng chúng
      if (documents.isNotEmpty) {
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
      
      // Chỉ sử dụng mock data khi thực sự không có dữ liệu trong database
      print('No documents found in Firestore, using mock data');
      final mockDocuments = [
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
      
      return mockDocuments;
    } catch (e) {
      print('Error searching help documents: $e');
      
      // Vẫn trả về mock data nếu có lỗi xảy ra
      final mockDocuments = [
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
      
      return mockDocuments;
    }
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
      // Tìm kiếm tài liệu liên quan
      final helpDocuments = await _searchHelpDocuments(query);
      
      // Chuẩn bị ngữ cảnh cho câu trả lời
      final StringBuffer context = StringBuffer();
      
      // Thêm tài liệu trợ giúp nếu có
      if (helpDocuments.isNotEmpty) {
        for (final doc in helpDocuments.take(2)) {
          context.writeln('Tài liệu: ${doc.title}\n${doc.content}\n');
        }
      }
      
      // Thêm thông tin về sản phẩm nếu có từ khóa liên quan
      final keywords = await _extractKeywords(query);
      if (keywords.isNotEmpty) {
        final productSnapshot = await _firestore
          .collection('products')
          .where('isSold', isEqualTo: false)
          .where('status', whereNotIn: ['pending_review', 'rejected'])
          .limit(3)
          .get();
          
        final products = productSnapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .where((product) {
            final productData = '${product.title.toLowerCase()} ${product.description.toLowerCase()} ${product.category.toLowerCase()} ${product.tags.join(' ').toLowerCase()}';
            return keywords.any((keyword) => productData.contains(keyword.toLowerCase()));
          })
          .take(2)
          .toList();
          
        if (products.isNotEmpty) {
          for (final product in products) {
            context.writeln('Sản phẩm: ${product.title}\nGiá: ${product.price.toStringAsFixed(0)} VND\nMô tả: ${product.description}\n');
          }
        }
      }
      
      // Tạo câu trả lời từ Gemini
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
                  'text': 'Bạn là trợ lý ảo của Student Market NTTU. Sử dụng thông tin từ ngữ cảnh để trả lời câu hỏi của người dùng một cách lịch sự và hữu ích bằng tiếng Việt. Nếu không có đủ thông tin, hãy nói rằng bạn không biết hoặc đề xuất người dùng đặt câu hỏi rõ ràng hơn.\n\nNgữ cảnh:\n${context.toString()}\n\nCâu hỏi: $query'
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
        print('Error generating RAG response: ${response.body}');
        _addBotTextMessage('Xin lỗi, tôi không thể xử lý yêu cầu của bạn lúc này. Vui lòng thử lại sau.');
      }
    } catch (e) {
      print('Exception generating RAG response: $e');
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
} 