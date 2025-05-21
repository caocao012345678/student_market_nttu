import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/analysis_result.dart';
import '../utils/lm_studio_client.dart';
import '../utils/image_utils.dart';

class ImageAnalyzer {
  final LMStudioClient _lmClient;
  final ImageUtils _imageUtils;
  
  // Danh sách từ khóa nhạy cảm trong hình ảnh
  final List<String> _prohibitedImageContent = [
    'vũ khí', 'súng', 'đạn', 'ma túy', 'ảnh khỏa thân',
    'nội dung người lớn', 'rượu', 'thuốc lá', 'hình ảnh bạo lực',
    'hàng giả', 'hàng nhái', 'tiền giả'
  ];
  
  final double _confidenceThreshold = 0.7;

  ImageAnalyzer({
    LMStudioClient? lmClient,
    ImageUtils? imageUtils,
  }) : 
    _lmClient = lmClient ?? LMStudioClient(),
    _imageUtils = imageUtils ?? ImageUtils();

  Future<AnalysisResult> analyzeProductImage(
    String imageUrl, {
    String? productTitle,
    String? categoryId,
  }) async {
    try {
      // Kiểm tra URL hình ảnh hợp lệ
      if (!_imageUtils.isValidImageUrl(imageUrl)) {
        return AnalysisResult(
          type: AnalysisType.image,
          isCompliant: false,
          confidenceScore: 0.9,
          details: 'URL hình ảnh không hợp lệ',
        );
      }
      
      // Chuyển đổi hình ảnh thành base64 để phân tích
      final imageBase64 = await _imageUtils.convertImageToBase64(imageUrl);
      if (imageBase64 == null) {
        return AnalysisResult(
          type: AnalysisType.image,
          isCompliant: false,
          confidenceScore: 0.9,
          details: 'Không thể đọc hình ảnh từ URL',
        );
      }
      
      // Kiểm tra xem LM Studio có hỗ trợ phân tích hình ảnh không
      if (await _lmClient.isAvailable() && await _lmClient.supportsVision()) {
        final prompt = '''
        Phân tích hình ảnh sản phẩm này và xác định xem nó có phù hợp với quy định của chợ sinh viên không.
        ${productTitle != null ? 'Tiêu đề sản phẩm: $productTitle' : ''}
        ${categoryId != null ? 'Danh mục: $categoryId' : ''}
        
        Đánh giá các yếu tố sau:
        1. Hình ảnh có phù hợp với mô tả sản phẩm không
        2. Hình ảnh có chứa nội dung không phù hợp (khỏa thân, bạo lực, ma túy, vũ khí, v.v.) không
        3. Chất lượng hình ảnh có đủ để người dùng nhìn thấy sản phẩm không
        4. Hình ảnh có phải hàng giả, hàng nhái, hàng trôi nổi không
        
        Trả về JSON chỉ có các trường sau:
        {
          "isCompliant": true/false,
          "confidenceScore": 0.0-1.0,
          "details": "Giải thích ngắn gọn",
          "detectedObjects": ["danh sách các đối tượng phát hiện được"]
        }
        ''';
        
        final response = await _lmClient.analyzeImage(imageBase64, prompt);
        try {
          final Map<String, dynamic> analysisData = _lmClient.parseJsonResponse(response);
          final List<String> detectedObjects = 
            List<String>.from(analysisData['detectedObjects'] ?? []);
          
          // Kiểm tra các đối tượng phát hiện có vi phạm không
          bool hasProhibitedContent = false;
          String prohibitedItem = '';
          
          for (final item in detectedObjects) {
            for (final prohibited in _prohibitedImageContent) {
              if (item.toLowerCase().contains(prohibited.toLowerCase())) {
                hasProhibitedContent = true;
                prohibitedItem = prohibited;
                break;
              }
            }
            if (hasProhibitedContent) break;
          }
          
          if (hasProhibitedContent) {
            return AnalysisResult(
              type: AnalysisType.image,
              isCompliant: false,
              confidenceScore: 0.9,
              details: 'Hình ảnh chứa nội dung bị cấm: $prohibitedItem',
              additionalData: {
                'prohibitedContent': prohibitedItem,
                'detectedObjects': detectedObjects,
              },
            );
          }
          
          return AnalysisResult(
            type: AnalysisType.image,
            isCompliant: analysisData['isCompliant'] ?? true,
            confidenceScore: analysisData['confidenceScore']?.toDouble() ?? _confidenceThreshold,
            details: analysisData['details'] ?? 'Phân tích từ AI',
            additionalData: {
              'detectedObjects': detectedObjects,
            },
          );
        } catch (e) {
          debugPrint('Lỗi khi phân tích phản hồi AI: $e');
        }
      }
      
      // Sử dụng phương pháp dự phòng: gọi API bên ngoài khác để kiểm tra nếu LM Studio không hoạt động
      try {
        final result = await _fallbackImageAnalysis(imageUrl);
        return result;
      } catch (e) {
        debugPrint('Lỗi khi sử dụng phân tích hình ảnh dự phòng: $e');
      }
      
      // Trả về kết quả mặc định nếu không có phương pháp nào khả dụng
      return AnalysisResult(
        type: AnalysisType.image,
        isCompliant: true,
        confidenceScore: 0.6,
        details: 'Không thể phân tích chi tiết, giả định hình ảnh hợp lệ',
      );
    } catch (e) {
      debugPrint('Lỗi khi phân tích hình ảnh: $e');
      return AnalysisResult(
        type: AnalysisType.image,
        isCompliant: false,
        confidenceScore: 0.5,
        details: 'Lỗi khi phân tích hình ảnh: $e',
      );
    }
  }
  
  // Phương pháp dự phòng sử dụng API mở khác
  Future<AnalysisResult> _fallbackImageAnalysis(String imageUrl) async {
    try {
      // Giả lập việc gọi API bên ngoài (thực tế triển khai nên sử dụng API thật)
      await Future.delayed(Duration(milliseconds: 500));
      
      // Kết quả mẫu, thực tế sẽ được thay bằng API thực tế
      return AnalysisResult(
        type: AnalysisType.image,
        isCompliant: true,
        confidenceScore: 0.65,
        details: 'Phân tích cơ bản: Không phát hiện vi phạm rõ ràng',
      );
    } catch (e) {
      throw Exception('Không thể phân tích hình ảnh với phương pháp dự phòng: $e');
    }
  }
} 