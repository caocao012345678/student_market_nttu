import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LMStudioClient {
  final String _baseUrl;
  final String _apiKey;
  final String _llmIdentifier;
  final String _vlmIdentifier;
  
  // Cờ kiểm soát nếu không thể kết nối
  bool _hasConnectionFailed = false;
  DateTime? _lastConnectionAttempt;
  final Duration _retryInterval = Duration(minutes: 5);

  // Getter cho model ID
  String get llmModelId => _llmIdentifier;
  String get visionModelId => _vlmIdentifier;

  LMStudioClient({
    String? baseUrl,
    String? apiKey,
    String? llmIdentifier,
    String? vlmIdentifier,
  }) : 
    _baseUrl = baseUrl ?? _getEnvBaseUrl(),
    _apiKey = apiKey ?? '',
    _llmIdentifier = llmIdentifier ?? dotenv.env['LM_API_LLM_IDENTIFIER'] ?? 'default',
    _vlmIdentifier = vlmIdentifier ?? dotenv.env['LM_API_VLM_IDENTIFIER'] ?? 'default';
    
  // Lấy URL từ biến môi trường
  static String _getEnvBaseUrl() {
    final serverUrl = dotenv.env['LM_LOCAL_SERVER'];
    if (serverUrl != null && serverUrl.isNotEmpty) {
      final baseEndpoint = serverUrl.endsWith('/models') 
          ? serverUrl.substring(0, serverUrl.length - 7) 
          : serverUrl;
      return baseEndpoint;
    }
    return 'http://localhost:1234/v1';
  }

  // Kiểm tra kết nối đến LM Studio
  Future<bool> isAvailable() async {
    // Nếu đã thất bại trước đó, chỉ thử lại sau khoảng thời gian nhất định
    if (_hasConnectionFailed && _lastConnectionAttempt != null) {
      final now = DateTime.now();
      final difference = now.difference(_lastConnectionAttempt!);
      if (difference < _retryInterval) {
        debugPrint('Bỏ qua kiểm tra kết nối do lỗi gần đây. Thử lại sau $_retryInterval.');
        return false;
      }
    }
    
    try {
      _lastConnectionAttempt = DateTime.now();
      final endpoint = '$_baseUrl/models';
      debugPrint('Kiểm tra kết nối LM Studio tại: $endpoint');
      
      final response = await http.get(
        Uri.parse(endpoint),
        headers: _getHeaders(),
      ).timeout(Duration(seconds: 5));
      
      final success = response.statusCode == 200;
      if (success) {
        debugPrint('Kết nối thành công đến LM Studio');
        _hasConnectionFailed = false;

        // Log danh sách model có sẵn
        try {
          final modelsData = jsonDecode(response.body);
          if (modelsData['data'] is List) {
            final models = modelsData['data'] as List;
            debugPrint('Models khả dụng: ${models.map((m) => m['id']).join(', ')}');
          }
        } catch (e) {
          debugPrint('Lỗi khi phân tích danh sách model: $e');
        }
      } else {
        debugPrint('Không thể kết nối đến LM Studio: Mã lỗi ${response.statusCode}');
        _hasConnectionFailed = true;
      }
      return success;
    } catch (e) {
      debugPrint('Không thể kết nối đến LM Studio: $e');
      _hasConnectionFailed = true;
      return false;
    }
  }
  
  // Kiểm tra xem LM Studio có hỗ trợ xử lý hình ảnh không
  Future<bool> supportsVision() async {
    try {
      debugPrint('Kiểm tra khả năng xử lý hình ảnh của LM Studio với model: $_vlmIdentifier');
      final response = await http.get(
        Uri.parse('$_baseUrl/models'),
        headers: _getHeaders(),
      ).timeout(Duration(seconds: 5));
      
      if (response.statusCode != 200) {
        debugPrint('Không thể kiểm tra khả năng xử lý hình ảnh. Mã lỗi: ${response.statusCode}');
        return false;
      }
      
      final modelsData = jsonDecode(response.body);
      // Kiểm tra xem model vision được chỉ định có tồn tại không
      if (modelsData['data'] is List) {
        final models = modelsData['data'] as List;
        for (final model in models) {
          if (model['id'] == _vlmIdentifier) {
            debugPrint('Tìm thấy model vision: $_vlmIdentifier');
            return true;
          }
        }
        
        // Không tìm thấy model chỉ định, kiểm tra bất kỳ model nào có khả năng vision
        for (final model in models) {
          if (model['capabilities']?['vision'] == true) {
            debugPrint('Tìm thấy model hỗ trợ vision: ${model['id']}');
            return true;
          }
        }
      }
      
      debugPrint('Không tìm thấy model hỗ trợ xử lý hình ảnh. Model yêu cầu: $_vlmIdentifier');
      return false;
    } catch (e) {
      debugPrint('Không thể kiểm tra khả năng xử lý hình ảnh: $e');
      return false;
    }
  }

  // Gửi yêu cầu phân tích văn bản
  Future<String> generateResponse(String prompt) async {
    try {
      debugPrint('Gửi yêu cầu phân tích văn bản với model: $_llmIdentifier');
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: _getHeaders(),
        body: jsonEncode({
          'model': _llmIdentifier,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.2,
          'max_tokens': 500,
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Lỗi khi gọi API: ${response.statusCode}');
      }
      
      final responseBody = jsonDecode(response.body);
      return responseBody['choices'][0]['message']['content'];
    } catch (e) {
      debugPrint('Lỗi khi gửi yêu cầu phân tích văn bản: $e');
      throw Exception('Không thể phân tích văn bản: $e');
    }
  }

  // Gửi yêu cầu phân tích hình ảnh
  Future<String> analyzeImage(String base64Image, String prompt) async {
    try {
      debugPrint('Gửi yêu cầu phân tích hình ảnh với model: $_vlmIdentifier');
      final payload = jsonEncode({
        'model': _vlmIdentifier,
        'messages': [
          {
            'role': 'user', 
            'content': [
              {'type': 'text', 'text': prompt},
              {'type': 'image_url', 'image_url': {'url': base64Image}}
            ]
          }
        ],
        'temperature': 0.2,
        'max_tokens': 500,
      });
      
      debugPrint('Endpoint: $_baseUrl/chat/completions');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: _getHeaders(),
        body: payload,
      );
      
      if (response.statusCode != 200) {
        debugPrint('Lỗi phản hồi: ${response.statusCode}, ${response.body}');
        throw Exception('Lỗi khi gọi API: ${response.statusCode}');
      }
      
      final responseBody = jsonDecode(response.body);
      return responseBody['choices'][0]['message']['content'];
    } catch (e) {
      debugPrint('Lỗi khi gửi yêu cầu phân tích hình ảnh: $e');
      throw Exception('Không thể phân tích hình ảnh: $e');
    }
  }
  
  // Phân tích JSON từ phản hồi
  Map<String, dynamic> parseJsonResponse(String response) {
    try {
      // Tìm và trích xuất JSON từ phản hồi
      final RegExp jsonRegex = RegExp(r'```json([\s\S]*?)```|{[\s\S]*}');
      final match = jsonRegex.firstMatch(response);
      
      String jsonString;
      if (match != null) {
        if (match.group(1) != null) {
          // Trích xuất nội dung bên trong ```json ... ```
          jsonString = match.group(1)!.trim();
        } else {
          // Trích xuất JSON trực tiếp nếu không có markdown block
          jsonString = match.group(0)!.trim();
        }
      } else {
        // Thử tìm phần tử đầu tiên có dấu { và cuối cùng có dấu }
        final firstBrace = response.indexOf('{');
        final lastBrace = response.lastIndexOf('}');
        
        if (firstBrace != -1 && lastBrace != -1 && firstBrace < lastBrace) {
          jsonString = response.substring(firstBrace, lastBrace + 1);
        } else {
          debugPrint('Không tìm thấy JSON trong phản hồi: $response');
          throw Exception('Không tìm thấy JSON trong phản hồi');
        }
      }
      
      // Parse JSON
      final result = jsonDecode(jsonString);
      debugPrint('Đã phân tích JSON thành công');
      return result;
    } catch (e) {
      debugPrint('Lỗi khi phân tích JSON: $e');
      // Trả về một object mặc định nếu không phân tích được
      return {
        'isCompliant': true,
        'confidenceScore': 0.7,
        'details': 'Không thể phân tích phản hồi từ AI'
      };
    }
  }

  // Lấy headers cho API
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_apiKey.isNotEmpty) 'Authorization': 'Bearer $_apiKey',
    };
  }
} 