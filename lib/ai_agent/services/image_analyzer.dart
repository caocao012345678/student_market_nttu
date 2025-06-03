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

  // Phương thức mới để lấy mô tả hình ảnh từ VLM
  Future<String?> getImageDescription(String imageBase64) async {
    try {
      debugPrint('Đang yêu cầu mô tả hình ảnh từ VLM');
      final prompt = '''
      Mô tả chi tiết hình ảnh này bằng tiếng Việt. 
      Hãy tập trung vào các đặc điểm chính của sản phẩm như: màu sắc, hình dáng, kích thước tương đối, 
      tình trạng sản phẩm, và đây là sản phẩm gì.
      ''';
      
      final response = await _lmClient.analyzeImage(imageBase64, prompt);
      debugPrint('Đã nhận mô tả hình ảnh từ VLM: ${response.length} ký tự');
      return response.trim();
    } catch (e) {
      debugPrint('Lỗi khi lấy mô tả hình ảnh: $e');
      return null;
    }
  }

  // Phương thức để phân tích mô tả hình ảnh bằng LLM
  Future<AnalysisResult> analyzeImageDescription(
    String imageDescription, {
    String? productTitle,
    String? categoryId,
    String? imageUrl,
  }) async {
    try {
      debugPrint('Đang phân tích mô tả hình ảnh bằng LLM');
      final prompt = '''
      Dựa trên mô tả hình ảnh sau đây, hãy đánh giá xem hình ảnh này có phù hợp để đăng bán trên chợ sinh viên không:
      
      Mô tả hình ảnh: """$imageDescription"""
      ${productTitle != null ? 'Tiêu đề sản phẩm: $productTitle' : ''}
      ${categoryId != null ? 'Danh mục: $categoryId' : ''}
      
      Đánh giá các yếu tố sau:
      1. Hình ảnh có phù hợp với mô tả sản phẩm không (nếu có tiêu đề)
      2. Hình ảnh có chứa nội dung không phù hợp (khỏa thân, bạo lực, ma túy, vũ khí, v.v.) không
      3. Chất lượng mô tả hình ảnh có đủ để người dùng hiểu về sản phẩm không
      4. Dựa theo mô tả, hình ảnh có phải hàng giả, hàng nhái, hàng cấm không
      
      Trả về JSON chỉ có các trường sau:
      {
        "isCompliant": true/false,
        "confidenceScore": 0.0-1.0,
        "details": "Giải thích ngắn gọn",
        "detectedObjects": ["danh sách các đối tượng chính trong hình ảnh"]
      }
      ''';
      
      final response = await _lmClient.generateResponse(prompt);
      try {
        final Map<String, dynamic> analysisData = _lmClient.parseJsonResponse(response);
        debugPrint('Kết quả phân tích mô tả hình ảnh: ${jsonEncode(analysisData)}');
        
        final List<String> detectedObjects = 
          List<String>.from(analysisData['detectedObjects'] ?? []);
        
        debugPrint('Các đối tượng được phát hiện: ${detectedObjects.join(', ')}');
        
        // Kiểm tra các đối tượng phát hiện có vi phạm không
        bool hasProhibitedContent = false;
        String prohibitedItem = '';
        
        for (final item in detectedObjects) {
          for (final prohibited in _prohibitedImageContent) {
            if (item.toLowerCase().contains(prohibited.toLowerCase())) {
              hasProhibitedContent = true;
              prohibitedItem = prohibited;
              debugPrint('Đã phát hiện nội dung bị cấm: $prohibitedItem trong đối tượng: $item');
              break;
            }
          }
          if (hasProhibitedContent) break;
        }
        
        if (hasProhibitedContent) {
          debugPrint('Phát hiện nội dung bị cấm: $prohibitedItem');
          return AnalysisResult(
            type: AnalysisType.image,
            isCompliant: false,
            confidenceScore: 0.9,
            details: 'Hình ảnh chứa nội dung bị cấm: $prohibitedItem',
            additionalData: {
              'prohibitedContent': prohibitedItem,
              'detectedObjects': detectedObjects,
              'imageDescription': imageDescription,
              'url': imageUrl
            },
          );
        }
        
        bool isImageCompliant = analysisData['isCompliant'] ?? true;
        double confidenceScore = analysisData['confidenceScore']?.toDouble() ?? _confidenceThreshold;
        String details = analysisData['details'] ?? 'Phân tích từ AI';
        
        debugPrint('Kết luận phân tích hình ảnh: isCompliant=$isImageCompliant, score=$confidenceScore');
        debugPrint('Chi tiết: $details');
        
        return AnalysisResult(
          type: AnalysisType.image,
          isCompliant: isImageCompliant,
          confidenceScore: confidenceScore,
          details: details,
          additionalData: {
            'detectedObjects': detectedObjects,
            'imageDescription': imageDescription,
            'url': imageUrl
          },
        );
      } catch (e) {
        debugPrint('Lỗi khi phân tích phản hồi AI: $e');
        return AnalysisResult(
          type: AnalysisType.image,
          isCompliant: false,
          confidenceScore: 0.5,
          details: 'Lỗi khi phân tích phản hồi AI: $e',
          additionalData: {
            'error': 'parsing_error',
            'imageDescription': imageDescription,
            'url': imageUrl
          },
        );
      }
    } catch (e) {
      debugPrint('Lỗi khi phân tích mô tả hình ảnh: $e');
      return AnalysisResult(
        type: AnalysisType.image,
        isCompliant: false,
        confidenceScore: 0.5,
        details: 'Lỗi khi phân tích mô tả hình ảnh: $e',
        additionalData: {
          'error': 'analysis_error',
          'imageDescription': imageDescription,
          'url': imageUrl
        },
      );
    }
  }

  Future<AnalysisResult> analyzeProductImage(
    String imageUrl, {
    String? productTitle,
    String? categoryId,
  }) async {
    try {
      debugPrint('Bắt đầu phân tích hình ảnh: $imageUrl');
      
      // Kiểm tra URL hình ảnh hợp lệ (sử dụng phương thức mới tương thích với Firebase Storage)
      if (!_imageUtils.isValidImageUrl(imageUrl)) {
        debugPrint('URL hình ảnh không hợp lệ theo định dạng: $imageUrl');
        
        // Thử xác thực bằng HTTP request
        debugPrint('Thử xác thực URL bằng HTTP request');
        final isValid = await _imageUtils.validateImageUrlWithRequest(imageUrl);
        
        if (!isValid) {
          debugPrint('URL hình ảnh không vượt qua xác thực HTTP: $imageUrl');
          return AnalysisResult(
            type: AnalysisType.image,
            isCompliant: false,
            confidenceScore: 0.9,
            details: 'URL hình ảnh không hợp lệ hoặc không thể truy cập',
            additionalData: {
              'url': imageUrl,
              'error': 'invalid_url'
            },
          );
        } else {
          debugPrint('URL hình ảnh hợp lệ sau khi xác thực qua HTTP');
        }
      }
      
      // Chuyển đổi hình ảnh thành base64 để phân tích
      debugPrint('Chuyển đổi hình ảnh sang base64 để phân tích');
      final imageBase64 = await _imageUtils.convertImageToBase64(imageUrl);
      if (imageBase64 == null) {
        debugPrint('Không thể đọc hoặc chuyển đổi hình ảnh từ URL: $imageUrl');
        return AnalysisResult(
          type: AnalysisType.image,
          isCompliant: false,
          confidenceScore: 0.9,
          details: 'Không thể tải hoặc xử lý hình ảnh từ URL',
          additionalData: {
            'url': imageUrl,
            'error': 'conversion_failed'
          },
        );
      }
      
      debugPrint('Đã chuyển đổi hình ảnh sang base64 thành công');
      
      // Kiểm tra kết nối LM Studio
      debugPrint('Kiểm tra kết nối LM Studio và khả năng xử lý hình ảnh');
      bool isLmAvailable = await _lmClient.isAvailable();
      debugPrint('LM Studio khả dụng: $isLmAvailable');
      
      bool supportsVision = false;
      
      if (isLmAvailable) {
        supportsVision = await _lmClient.supportsVision();
        debugPrint('Model hỗ trợ vision: $supportsVision');
        debugPrint('ID model vision: ${_lmClient.visionModelId}');
      }
      
      // LUỒNG XỬ LÝ MỚI: Lấy mô tả hình ảnh trước, sau đó phân tích mô tả
      if (isLmAvailable && supportsVision) {
        // Bước 1: Lấy mô tả hình ảnh từ VLM (Moondream2)
        debugPrint('Bước 1: Lấy mô tả hình ảnh từ VLM');
        final imageDescription = await getImageDescription(imageBase64);
        
        if (imageDescription == null || imageDescription.isEmpty) {
          debugPrint('Không thể lấy mô tả hình ảnh từ VLM');
          return AnalysisResult(
            type: AnalysisType.image,
            isCompliant: false,
            confidenceScore: 0.5,
            details: 'Không thể lấy mô tả hình ảnh từ mô hình AI',
            additionalData: {
              'error': 'description_failed',
              'url': imageUrl
            },
          );
        }
        
        debugPrint('Mô tả hình ảnh từ VLM: $imageDescription');
        
        // Bước 2: Phân tích mô tả hình ảnh bằng LLM
        debugPrint('Bước 2: Phân tích mô tả hình ảnh bằng LLM');
        return analyzeImageDescription(
          imageDescription,
          productTitle: productTitle,
          categoryId: categoryId,
          imageUrl: imageUrl
        );
      }
      
      // Nếu không kết nối được LM Studio hoặc không hỗ trợ phân tích hình ảnh
      String reason;
      if (!isLmAvailable) {
        reason = 'Không thể kết nối đến LM Studio để phân tích hình ảnh';
        debugPrint(reason);
      } else if (!supportsVision) {
        reason = 'LM Studio không hỗ trợ phân tích hình ảnh';
        debugPrint(reason);
      } else {
        reason = 'Lỗi khi phân tích hình ảnh';
        debugPrint(reason);
      }
      
      // Đánh dấu không tuân thủ để yêu cầu kiểm duyệt thủ công
      debugPrint('Trả về kết quả để yêu cầu kiểm duyệt thủ công');
      return AnalysisResult(
        type: AnalysisType.image,
        isCompliant: false,
        confidenceScore: 0.0,
        details: '$reason. Cần kiểm duyệt thủ công.',
        additionalData: {
          'error': 'vision_unavailable',
          'url': imageUrl
        },
      );
    } catch (e) {
      debugPrint('Lỗi khi phân tích hình ảnh: $e');
      return AnalysisResult(
        type: AnalysisType.image,
        isCompliant: false,
        confidenceScore: 0.5,
        details: 'Lỗi khi phân tích hình ảnh: $e',
        additionalData: {
          'error': 'general_error',
          'url': imageUrl
        },
      );
    }
  }
  
  // Tiện ích - giới hạn độ dài chuỗi
  int min(int a, int b) {
    return a < b ? a : b;
  }
} 