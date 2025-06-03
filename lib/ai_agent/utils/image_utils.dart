import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ImageUtils {
  // Kiểm tra URL hình ảnh có hợp lệ hay không
  bool isValidImageUrl(String url) {
    try {
      debugPrint('Kiểm tra tính hợp lệ của URL hình ảnh: $url');
      Uri uri = Uri.parse(url);
      if (!uri.hasScheme || !uri.hasAuthority) {
        debugPrint('URL không hợp lệ: thiếu scheme hoặc authority');
        return false;
      }
      
      // Hỗ trợ Firebase Storage và các dịch vụ lưu trữ không có phần mở rộng file
      if (url.contains('firebasestorage.googleapis.com') || 
          url.contains('storage.googleapis.com') ||
          url.contains('cloudinary.com') ||
          url.contains('imgur.com') ||
          (uri.queryParameters.containsKey('alt') && uri.queryParameters['alt'] == 'media')) {
        debugPrint('Phát hiện URL từ dịch vụ lưu trữ đám mây');
        return true;
      }
      
      // Kiểm tra Content-Type nếu URL có chứa tham số "token" (phổ biến trong Firebase Storage)
      if (uri.queryParameters.containsKey('token')) {
        debugPrint('URL có tham số token, chấp nhận là URL hình ảnh');
        return true;
      }
      
      // Kiểm tra phần mở rộng của file
      String path = uri.path.toLowerCase();
      bool hasImageExtension = path.endsWith('.jpg') || 
             path.endsWith('.jpeg') || 
             path.endsWith('.png') || 
             path.endsWith('.gif') || 
             path.endsWith('.webp') ||
             path.endsWith('.bmp') ||
             path.endsWith('.svg');
      
      if (!hasImageExtension && uri.queryParameters.isNotEmpty) {
        // Một số URL có thể không có phần mở rộng file ở path mà đưa vào tham số
        // Ví dụ: example.com/image?format=jpg hoặc example.com/image?type=png
        String query = uri.query.toLowerCase();
        if (query.contains('jpg') || query.contains('jpeg') || 
            query.contains('png') || query.contains('gif') || 
            query.contains('webp') || query.contains('image')) {
          debugPrint('URL không có phần mở rộng trong path nhưng có tham số hình ảnh hợp lệ');
          return true;
        }
      }
      
      if (!hasImageExtension) {
        debugPrint('URL không chứa phần mở rộng hình ảnh hợp lệ: $path');
      }
      
      return hasImageExtension;
    } catch (e) {
      debugPrint('Lỗi khi kiểm tra URL hình ảnh: $e');
      return false;
    }
  }

  // Kiểm tra URL thông qua HTTP HEAD request để xác định đây có thực sự là hình ảnh hay không
  Future<bool> validateImageUrlWithRequest(String url) async {
    try {
      debugPrint('Xác thực URL hình ảnh bằng HTTP request: $url');
      final response = await http.head(Uri.parse(url))
          .timeout(Duration(seconds: 5));
      
      if (response.statusCode != 200) {
        debugPrint('URL không hợp lệ: Mã phản hồi ${response.statusCode}');
        return false;
      }
      
      final contentType = response.headers['content-type'];
      if (contentType != null && contentType.startsWith('image/')) {
        debugPrint('Xác thực thành công: Content-Type là $contentType');
        return true;
      } else if (contentType != null) {
        debugPrint('URL không phải hình ảnh: Content-Type là $contentType');
        return false;
      }
      
      // Nếu không có content-type, dựa vào URL
      debugPrint('Không có Content-Type, dựa vào URL để xác định');
      return isValidImageUrl(url);
    } catch (e) {
      debugPrint('Lỗi khi xác thực URL hình ảnh bằng request: $e');
      // Nếu không thể kiểm tra qua request, quay lại kiểm tra URL
      return isValidImageUrl(url);
    }
  }

  // Chuyển đổi hình ảnh từ URL thành base64
  Future<String?> convertImageToBase64(String imageUrl) async {
    try {
      debugPrint('Đang tải hình ảnh từ URL: $imageUrl');
      final response = await http.get(Uri.parse(imageUrl))
          .timeout(Duration(seconds: 10));
      
      if (response.statusCode != 200) {
        debugPrint('Không thể tải hình ảnh, mã lỗi: ${response.statusCode}');
        return null;
      }
      
      // Kiểm tra Content-Type
      final contentType = response.headers['content-type'];
      if (contentType != null && !contentType.startsWith('image/')) {
        debugPrint('Nội dung tải về không phải là hình ảnh: $contentType');
        return null;
      }
      
      // Mã hóa dữ liệu nhị phân thành base64
      final bytes = response.bodyBytes;
      debugPrint('Đã tải hình ảnh thành công, kích thước: ${bytes.length} bytes');
      final base64String = base64Encode(bytes);
      
      // Lấy định dạng hình ảnh từ URL hoặc header
      String imageFormat = 'jpeg';
      if (contentType != null) {
        if (contentType.contains('png')) {
          imageFormat = 'png';
        } else if (contentType.contains('gif')) {
          imageFormat = 'gif';
        } else if (contentType.contains('webp')) {
          imageFormat = 'webp';
        }
      } else {
        // Trích xuất định dạng từ URL nếu không có content-type
        final url = imageUrl.toLowerCase();
        if (url.endsWith('.png')) {
          imageFormat = 'png';
        } else if (url.endsWith('.gif')) {
          imageFormat = 'gif';
        } else if (url.endsWith('.webp')) {
          imageFormat = 'webp';
        }
      }
      
      debugPrint('Đã chuyển đổi hình ảnh sang base64 với định dạng $imageFormat');
      return 'data:image/$imageFormat;base64,$base64String';
    } catch (e) {
      debugPrint('Lỗi khi chuyển đổi hình ảnh sang base64: $e');
      return null;
    }
  }
  
  // Kiểm tra kích thước hình ảnh có quá lớn không
  Future<bool> isImageTooLarge(String imageUrl, {int maxSizeInBytes = 5 * 1024 * 1024}) async {
    try {
      final response = await http.head(Uri.parse(imageUrl));
      
      if (response.statusCode != 200) {
        return true; // Coi là quá lớn nếu không thể kiểm tra
      }
      
      final contentLengthStr = response.headers['content-length'];
      if (contentLengthStr == null) {
        return false; // Không thể xác định kích thước
      }
      
      final contentLength = int.tryParse(contentLengthStr);
      if (contentLength == null) {
        return false;
      }
      
      return contentLength > maxSizeInBytes;
    } catch (e) {
      debugPrint('Lỗi khi kiểm tra kích thước hình ảnh: $e');
      return false;
    }
  }
  
  // Phát hiện hình ảnh trùng lặp (sử dụng hash đơn giản)
  Future<String> generateImageHash(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      
      if (response.statusCode != 200) {
        return '';
      }
      
      // Tạo hash đơn giản từ bytes của hình ảnh
      final bytes = response.bodyBytes;
      final hash = bytes.fold<int>(0, (prev, byte) => prev + byte);
      return hash.toString();
    } catch (e) {
      debugPrint('Lỗi khi tạo hash hình ảnh: $e');
      return '';
    }
  }
} 