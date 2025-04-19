import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:async';

// Import js có điều kiện để tránh lỗi trên mobile
import 'dart:js_util' if (dart.library.io) 'package:flutter/material.dart' as js_util;

class GeminiService extends ChangeNotifier {
  GenerativeModel? _model;
  ChatSession? _chatSession;
  
  // Danh sách lịch sử chat dạng Content
  List<Content> _history = [];

  // Lịch sử chat - không còn private để RAGService có thể truy cập
  List<Map<String, dynamic>> chatHistory = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  // Tham chiếu đến phương thức sendMessageWithContext
  late Future<String> Function(String context, String message) sendContextMessage;

  // Thêm phương thức để set isLoading
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Thêm phương thức để set errorMessage
  void setErrorMessage(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  // Phương thức để cập nhật cả hai cùng lúc
  void updateState({bool? loading, String? errorMsg}) {
    if (loading != null) _isLoading = loading;
    if (errorMsg != null) _errorMessage = errorMsg;
    notifyListeners();
  }

  // Danh sách các models đã được lấy từ API
  List<String> _availableModels = [];
  List<String> get availableModels => _availableModels;

  GeminiService() {
    _initializeGemini();
    _loadChatHistory();
    // Gán tham chiếu đến phương thức
    sendContextMessage = sendMessageWithContext;
  }
  
  /// Khởi tạo model Gemini
  Future<void> initialize() async {
    await _initializeGemini();
  }
  
  /// Kiểm tra xem model đã được khởi tạo chưa
  void _checkInitialized() {
    if (_model == null) {
      throw Exception('Gemini model chưa được khởi tạo. Hãy gọi initialize() trước.');
    }
  }
  
  /// Giới hạn độ dài của lịch sử để tránh quá tải
  void _trimHistory() {
    // Giữ tối đa 10 tin nhắn gần nhất (5 cặp hỏi-đáp)
    if (_history.length > 10) {
      _history = _history.sublist(_history.length - 10);
    }
  }

  // Phương thức lấy API key
  String? getApiKey() {
    return dotenv.env['GEMINI_API_KEY'];
  }

  Future<void> _initializeGemini() async {
    try {
      // Lấy API key từ .env
      String? apiKey = getApiKey();
      
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API key không hợp lệ. Vui lòng cấu hình API key');
      }
      
      // Khởi tạo model với Gemini 1.5 Flash (Model phiên bản mới nhất chính thức)
      _model = GenerativeModel(
        // Sử dụng model chính thức - model gemini-2.0-flash-thinking-experimental-01-21 không tồn tại
        model: 'gemini-1.5-flash', // 'gemini-1.5-pro' là lựa chọn thay thế nếu cần nhiều tính năng hơn
        apiKey: apiKey,
      );

      // Khởi tạo phiên chat
      _chatSession = _model?.startChat();
      
      // Khởi tạo lịch sử trống
      _history = [];
      
      // Gửi tin nhắn system prompt đầu tiên
      if (_chatSession != null) {
        await _chatSession!.sendMessage(
          Content.text('Bạn là trợ lý ảo trên ứng dụng Student Market NTTU. '
              'Bạn giúp người dùng tìm kiếm sản phẩm, hướng dẫn cách sử dụng các tính năng của ứng dụng. '
              'Hãy trả lời ngắn gọn, đầy đủ và thân thiện. '
              'Tập trung vào việc hỗ trợ người dùng trong việc mua bán, tìm kiếm sản phẩm và sử dụng ứng dụng.')
        );
      }
      
      // Lấy danh sách models có sẵn
      await fetchAvailableModels(apiKey);
    } catch (e) {
      _errorMessage = 'Không thể khởi tạo Gemini API: $e';
      debugPrint('Gemini Init Error: $_errorMessage');
      notifyListeners();
    }
  }

  // Phương thức: Lấy danh sách models hỗ trợ của Gemini API
  Future<List<String>> fetchAvailableModels(String apiKey) async {
    try {
      // Kiểm tra nếu đã có danh sách trong cache
      if (_availableModels.isNotEmpty) {
        debugPrint('Returning cached models list (${_availableModels.length} items)');
        return _availableModels;
      }

      // Thiết lập timeout cho request
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Thời gian yêu cầu đã hết hạn khi tải danh sách models');
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> models = data['models'] ?? [];
        
        _availableModels = models
            .map<String>((model) => model['name'] as String)
            .where((name) => name.contains('gemini'))
            .map((name) => name.replaceAll('models/', ''))
            .toList();
        
        // Sắp xếp models theo tên
        _availableModels.sort();
        
        notifyListeners();
        debugPrint('Available Gemini models: ${_availableModels.length} models found');
        return _availableModels;
      } else if (response.statusCode == 403) {
        throw Exception('Lỗi xác thực: API key không hợp lệ hoặc hết hạn');
      } else if (response.statusCode == 429) {
        throw Exception('Vượt quá giới hạn số lượng yêu cầu. Vui lòng thử lại sau');
      } else {
        throw Exception('Không thể tải danh sách models: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('Error fetching models: $e');
      throw Exception('Lỗi khi tải danh sách models: $e');
    }
  }
  
  // Cache lưu trữ chi tiết model
  final Map<String, Map<String, dynamic>> _modelDetailsCache = {};
  
  // Phương thức để lấy thông tin chi tiết về một model cụ thể
  Future<Map<String, dynamic>?> getModelDetails(String modelName, String apiKey) async {
    try {
      // Kiểm tra cache trước
      if (_modelDetailsCache.containsKey(modelName)) {
        debugPrint('Returning cached details for model: $modelName');
        return _modelDetailsCache[modelName];
      }
      
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$modelName?key=$apiKey');
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Thời gian yêu cầu đã hết hạn khi tải chi tiết model');
        },
      );
      
      if (response.statusCode == 200) {
        final details = json.decode(response.body);
        // Lưu vào cache
        _modelDetailsCache[modelName] = details;
        return details;
      } else if (response.statusCode == 404) {
        throw Exception('Model không tồn tại hoặc đã bị xóa khỏi API');
      } else if (response.statusCode == 403) {
        throw Exception('Lỗi xác thực: API key không hợp lệ hoặc hết hạn');
      } else {
        throw Exception('Lỗi khi tải chi tiết model: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('Error fetching model details: $e');
      throw Exception('Lỗi khi tải chi tiết model: $e');
    }
  }

  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString('chat_history');
      if (historyJson != null && historyJson.isNotEmpty) {
        final List<dynamic> decodedList = jsonDecode(historyJson);
        chatHistory = decodedList.map((item) => Map<String, dynamic>.from(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    }
  }

  // Cập nhật để có thể gọi từ bên ngoài class
  Future<void> saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String historyJson = jsonEncode(chatHistory);
      await prefs.setString('chat_history', historyJson);
    } catch (e) {
      debugPrint('Error saving chat history: $e');
    }
  }

  // Thêm tin nhắn người dùng vào lịch sử
  void addUserMessageToHistory(String message) {
    chatHistory.add({
      'role': 'user',
      'content': message,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    notifyListeners();
  }

  // Thêm tin nhắn bot vào lịch sử
  void addBotMessageToHistory(String message) {
    chatHistory.add({
      'role': 'assistant',
      'content': message,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    notifyListeners();
  }

  Future<String> sendMessage(String message, {bool addToHistory = false}) async {
    if (message.trim().isEmpty) return '';

    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      // Chỉ thêm tin nhắn người dùng vào lịch sử khi được yêu cầu (từ UI trực tiếp)
      // và không phải là RAG prompt
      if (addToHistory && !message.contains("Hãy trả lời câu hỏi của người dùng dựa trên các thông tin dưới đây")) {
        chatHistory.add({
          'role': 'user',
          'content': message,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }

      // Xem có model và phiên chat hay không
      if (_model == null || _chatSession == null) {
        await _initializeGemini();
        if (_model == null || _chatSession == null) {
          throw Exception('Không thể khởi tạo Gemini API');
        }
      }

      // Tạo đối tượng Content từ tin nhắn văn bản
      final content = Content.text(message);
      
      // Gửi tin nhắn đến API
      final response = await _chatSession?.sendMessage(content);
      final responseText = response?.text ?? 'Xin lỗi, tôi không thể trả lời vào lúc này';

      // Thêm phản hồi vào lịch sử chỉ khi được yêu cầu và không phải là RAG prompt
      if (addToHistory && !message.contains("Hãy trả lời câu hỏi của người dùng dựa trên các thông tin dưới đây")) {
        chatHistory.add({
          'role': 'assistant',
          'content': responseText,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        // Lưu lịch sử
        await saveChatHistory();
      }

      _isLoading = false;
      notifyListeners();
      return responseText;
    } catch (e) {
      final errorDetail = 'Lỗi khi gửi tin nhắn: $e';
      _errorMessage = errorDetail;
      debugPrint('Gemini API Error: $errorDetail');
      _isLoading = false;
      notifyListeners();
      
      // Trả về thông báo lỗi chi tiết thay vì thông báo mặc định
      return 'Lỗi: $e';
    }
  }

  void clearChat() {
    chatHistory.clear();
    _chatSession = _model?.startChat();
    saveChatHistory();
    notifyListeners();
  }

  // Phương thức để gửi tin nhắn với ngữ cảnh RAG
  Future<String> sendMessageWithRAGContext(String context, String userQuery) async {
    // Tạo prompt với ngữ cảnh và câu hỏi
    final prompt = """
Dựa trên thông tin sau đây:

$context

Hãy trả lời câu hỏi của người dùng: "$userQuery"

Trả lời một cách ngắn gọn, chính xác và hữu ích. Chỉ sử dụng thông tin được cung cấp.
""";

    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      // Đảm bảo model và chat session đã được khởi tạo
      if (_model == null || _chatSession == null) {
        await _initializeGemini();
        if (_model == null || _chatSession == null) {
          throw Exception('Không thể khởi tạo Gemini API');
        }
      }

      // Tạo đối tượng Content từ tin nhắn văn bản
      final content = Content.text(prompt);
      
      // Gửi tin nhắn RAG đến API nhưng không lưu vào lịch sử hiển thị
      final response = await _chatSession?.sendMessage(content);
      final responseText = response?.text ?? 'Xin lỗi, tôi không thể trả lời vào lúc này';

      _isLoading = false;
      notifyListeners();
      return responseText;
    } catch (e) {
      final errorDetail = 'Lỗi khi xử lý RAG: $e';
      _errorMessage = errorDetail;
      debugPrint('Gemini RAG Error: $errorDetail');
      _isLoading = false;
      notifyListeners();
      
      return 'Lỗi khi xử lý dữ liệu: $e';
    }
  }

  /// Gửi tin nhắn với context dưới dạng văn bản tự do
  Future<String> sendMessageWithContext(String context, String message) async {
    _checkInitialized();
    
    try {
      final systemContext = 'Hãy sử dụng thông tin sau đây để trả lời câu hỏi:\n\n$context';
      debugPrint('Sending message with context to Gemini');
      
      // Tạo phiên chat mới nếu chưa có
      if (_chatSession == null) {
        _chatSession = _model?.startChat();
      }
      
      if (_model == null) {
        throw Exception('Model không được khởi tạo');
      }
      
      // Tạo nội dung
      final List<Content> contentList = [Content.text(systemContext), Content.text(message)];
      
      final response = await _model!.generateContent(contentList);
      final responseText = response.text ?? '';
      
      // Thêm vào lịch sử
      _history.add(Content.text(message));
      _history.add(Content.text(responseText));
      
      // Đảm bảo lịch sử không quá dài
      _trimHistory();
      
      return responseText;
    } catch (e) {
      debugPrint('Gemini error: $e');
      return 'Xin lỗi, tôi không thể trả lời câu hỏi này vào lúc này. Lỗi: $e';
    }
  }
  
  /// Gửi tin nhắn với system prompt để kiểm soát phản hồi
  Future<String> sendPromptedMessage(String systemPrompt, String message, {bool addToHistory = true}) async {
    _checkInitialized();
    
    try {
      debugPrint('Sending prompted message to Gemini');
      
      if (_model == null) {
        throw Exception('Model không được khởi tạo');
      }
      
      // Tạo đối tượng Content cho system prompt và tin nhắn
      final List<Content> contentList = [Content.text(systemPrompt), Content.text(message)];
      
      // Gửi tin nhắn
      final response = await _model!.generateContent(contentList);
      final responseText = response.text ?? '';
      
      // Thêm vào lịch sử nếu được chỉ định
      if (addToHistory) {
        _history.add(Content.text(message));
        _history.add(Content.text(responseText));
        
        // Đảm bảo lịch sử không quá dài
        _trimHistory();
      }
      
      return responseText;
    } catch (e) {
      debugPrint('Gemini error: $e');
      return 'Xin lỗi, tôi không thể trả lời câu hỏi này vào lúc này. Lỗi: $e';
    }
  }
  
  /// Gửi tin nhắn với cả context và system prompt
  Future<String> sendContextAndPrompt(String context, String systemPrompt, String message) async {
    _checkInitialized();
    
    try {
      final fullPrompt = '$systemPrompt\n\nDữ liệu tham khảo:\n$context';
      debugPrint('Sending message with context and system prompt to Gemini');
      
      if (_model == null) {
        throw Exception('Model không được khởi tạo');
      }
      
      // Tạo nội dung
      final List<Content> contentList = [Content.text(fullPrompt), Content.text(message)];
      
      // Gửi tin nhắn
      final response = await _model!.generateContent(contentList);
      final responseText = response.text ?? '';
      
      // Thêm vào lịch sử
      _history.add(Content.text(message));
      _history.add(Content.text(responseText));
      
      // Đảm bảo lịch sử không quá dài
      _trimHistory();
      
      return responseText;
    } catch (e) {
      debugPrint('Gemini error: $e');
      return 'Xin lỗi, tôi không thể trả lời câu hỏi này vào lúc này. Lỗi: $e';
    }
  }
} 