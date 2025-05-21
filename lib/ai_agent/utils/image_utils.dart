import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ImageUtils {
  // Kiểm tra URL hình ảnh có hợp lệ hay không
  bool isValidImageUrl(String url) {
    try {
      Uri uri = Uri.parse(url);
      if (!uri.hasScheme || !uri.hasAuthority) {
        return false;
      }
      
      // Kiểm tra phần mở rộng của file
      String path = uri.path.toLowerCase();
      return path.endsWith('.jpg') || 
             path.endsWith('.jpeg') || 
             path.endsWith('.png') || 
             path.endsWith('.gif') || 
             path.endsWith('.webp');
    } catch (e) {
      return false;
    }
  }

  // Chuyển đổi hình ảnh từ URL thành base64
  Future<String?> convertImageToBase64(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      
      if (response.statusCode != 200) {
        debugPrint('Không thể tải hình ảnh, mã lỗi: ${response.statusCode}');
        return null;
      }
      
      // Mã hóa dữ liệu nhị phân thành base64
      final bytes = response.bodyBytes;
      final base64String = base64Encode(bytes);
      
      // Lấy định dạng hình ảnh từ URL hoặc header
      String imageFormat = 'jpeg';
      final contentType = response.headers['content-type'];
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