import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LMStudioClient {
  final String _baseUrl;
  final String _apiKey;
  
  // Cờ kiểm soát nếu không thể kết nối
  bool _hasConnectionFailed = false;
  DateTime? _lastConnectionAttempt;
  final Duration _retryInterval = Duration(minutes: 5);

  LMStudioClient({
    String? baseUrl,
    String? apiKey,
  })  : _baseUrl = baseUrl ?? 'http://localhost:1234/v1',
        _apiKey = apiKey ?? '';

  // Kiểm tra kết nối đến LM Studio
  Future<bool> isAvailable() async {
    // Nếu đã thất bại trước đó, chỉ thử lại sau khoảng thời gian nhất định
    if (_hasConnectionFailed && _lastConnectionAttempt != null) {
      final now = DateTime.now();
      final difference = now.difference(_lastConnectionAttempt!);
      if (difference < _retryInterval) {
        return false;
      }
    }
    
    try {
      _lastConnectionAttempt = DateTime.now();
      final response = await http.get(
        Uri.parse('$_baseUrl/models'),
        headers: _getHeaders(),
      ).timeout(Duration(seconds: 5));
      
      final success = response.statusCode == 200;
      _hasConnectionFailed = !success;
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
      final response = await http.get(
        Uri.parse('$_baseUrl/models'),
        headers: _getHeaders(),
      ).timeout(Duration(seconds: 5));
      
      if (response.statusCode != 200) {
        return false;
      }
      
      final models = jsonDecode(response.body);
      // Kiểm tra xem có model nào hỗ trợ vision không
      if (models is List) {
        for (final model in models) {
          if (model['capabilities']?['vision'] == true) {
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint('Không thể kiểm tra khả năng xử lý hình ảnh: $e');
      return false;
    }
  }

  // Gửi yêu cầu phân tích văn bản
  Future<String> generateResponse(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: _getHeaders(),
        body: jsonEncode({
          'model': 'default',
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
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: _getHeaders(),
        body: jsonEncode({
          'model': 'default',
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
        }),
      );
      
      if (response.statusCode != 200) {
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
          throw Exception('Không tìm thấy JSON trong phản hồi');
        }
      }
      
      // Parse JSON
      return jsonDecode(jsonString);
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