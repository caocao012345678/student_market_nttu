import 'package:flutter/foundation.dart';
import '../utils/lm_studio_client.dart';
import '../models/analysis_result.dart';

class TextAnalyzer {
  final LMStudioClient _lmClient;
  
  // Danh sách từ khóa vi phạm quy định
  final List<String> _prohibitedKeywords = [
    'ma túy', 'cần sa', 'vũ khí', 'súng', 'đạn', 'rượu lậu',
    'thuốc lá lậu', 'hàng nhái', 'hàng giả', 'không rõ nguồn gốc',
    'lừa đảo', 'đa cấp', 'hút máu', 'di động clone'
  ];
  
  // Ngưỡng điểm tin cậy cho quyết định
  final double _confidenceThreshold = 0.75;

  TextAnalyzer({LMStudioClient? lmClient}) 
    : _lmClient = lmClient ?? LMStudioClient();

  // Phân tích tiêu đề sản phẩm
  Future<AnalysisResult> analyzeProductTitle(String title, {String? categoryId}) async {
    try {
      // Kiểm tra từ khóa cấm
      for (final keyword in _prohibitedKeywords) {
        if (title.toLowerCase().contains(keyword.toLowerCase())) {
          return AnalysisResult(
            type: AnalysisType.title,
            isCompliant: false,
            confidenceScore: 0.95,
            details: 'Tiêu đề chứa từ khóa bị cấm: $keyword',
            additionalData: {'keyword': keyword},
          );
        }
      }
      
      // Kiểm tra độ dài tiêu đề
      if (title.length < 5) {
        return AnalysisResult(
          type: AnalysisType.title,
          isCompliant: false,
          confidenceScore: 0.9,
          details: 'Tiêu đề quá ngắn, cần ít nhất 5 ký tự',
        );
      }
      
      if (title.length > 100) {
        return AnalysisResult(
          type: AnalysisType.title,
          isCompliant: false,
          confidenceScore: 0.9,
          details: 'Tiêu đề quá dài, tối đa 100 ký tự',
        );
      }
      
      // Nếu có thể kết nối LM Studio, sử dụng AI để phân tích
      if (await _lmClient.isAvailable()) {
        final prompt = '''
        Phân tích tiêu đề sản phẩm sau đây và xác định xem nó có phù hợp làm tiêu đề rao bán trong chợ sinh viên hay không.
        Tiêu đề: "$title"
        ${categoryId != null ? 'Danh mục: $categoryId' : ''}
        
        Đánh giá các yếu tố sau:
        1. Ngôn ngữ lịch sự, phù hợp
        2. Mô tả rõ ràng về sản phẩm
        3. Không chứa nội dung lừa đảo hoặc cấm
        4. Không chứa từ ngữ thô tục
        
        Trả về JSON chỉ có các trường sau:
        {
          "isCompliant": true/false,
          "confidenceScore": 0.0-1.0,
          "details": "Giải thích ngắn gọn"
        }
        ''';
        
        final response = await _lmClient.generateResponse(prompt);
        try {
          final Map<String, dynamic> analysisData = _lmClient.parseJsonResponse(response);
          return AnalysisResult(
            type: AnalysisType.title,
            isCompliant: analysisData['isCompliant'] ?? true,
            confidenceScore: analysisData['confidenceScore']?.toDouble() ?? _confidenceThreshold,
            details: analysisData['details'] ?? 'Phân tích từ AI',
          );
        } catch (e) {
          debugPrint('Lỗi khi phân tích phản hồi AI: $e');
        }
      }
      
      // Nếu không kết nối được LM Studio, yêu cầu kiểm duyệt thủ công
      debugPrint('Không kết nối được LM Studio để phân tích tiêu đề: $title');
      return AnalysisResult(
        type: AnalysisType.title,
        isCompliant: false, // Đánh dấu không tuân thủ để yêu cầu kiểm duyệt
        confidenceScore: 0.0,
        details: 'Không thể kết nối đến AI để phân tích tiêu đề. Cần kiểm duyệt thủ công.',
      );
    } catch (e) {
      debugPrint('Lỗi khi phân tích tiêu đề: $e');
      return AnalysisResult(
        type: AnalysisType.title,
        isCompliant: false,
        confidenceScore: 0.5,
        details: 'Lỗi khi phân tích: $e',
      );
    }
  }

  // Phân tích mô tả sản phẩm
  Future<AnalysisResult> analyzeProductDescription(String description, {String? categoryId}) async {
    try {
      // Kiểm tra từ khóa cấm
      for (final keyword in _prohibitedKeywords) {
        if (description.toLowerCase().contains(keyword.toLowerCase())) {
          return AnalysisResult(
            type: AnalysisType.description,
            isCompliant: false,
            confidenceScore: 0.95,
            details: 'Mô tả chứa từ khóa bị cấm: $keyword',
            additionalData: {'keyword': keyword},
          );
        }
      }
      
      // Kiểm tra độ dài mô tả
      if (description.length < 20) {
        return AnalysisResult(
          type: AnalysisType.description,
          isCompliant: false,
          confidenceScore: 0.9,
          details: 'Mô tả quá ngắn, cần ít nhất 20 ký tự',
        );
      }
      
      // Nếu có thể kết nối LM Studio, sử dụng AI để phân tích
      if (await _lmClient.isAvailable()) {
        final prompt = '''
        Phân tích mô tả sản phẩm sau đây và xác định xem nó có phù hợp cho chợ sinh viên hay không.
        Mô tả: """$description"""
        ${categoryId != null ? 'Danh mục: $categoryId' : ''}
        
        Đánh giá các yếu tố sau:
        1. Ngôn ngữ lịch sự, phù hợp
        2. Mô tả rõ ràng về sản phẩm
        3. Không chứa nội dung lừa đảo, vi phạm pháp luật hoặc quảng cáo đa cấp
        4. Không chứa thông tin liên hệ ngoài hệ thống
        5. Không chứa từ ngữ thô tục
        
        Trả về JSON chỉ có các trường sau:
        {
          "isCompliant": true/false,
          "confidenceScore": 0.0-1.0,
          "details": "Giải thích ngắn gọn"
        }
        ''';
        
        final response = await _lmClient.generateResponse(prompt);
        try {
          final Map<String, dynamic> analysisData = _lmClient.parseJsonResponse(response);
          return AnalysisResult(
            type: AnalysisType.description,
            isCompliant: analysisData['isCompliant'] ?? true,
            confidenceScore: analysisData['confidenceScore']?.toDouble() ?? _confidenceThreshold,
            details: analysisData['details'] ?? 'Phân tích từ AI',
          );
        } catch (e) {
          debugPrint('Lỗi khi phân tích phản hồi AI: $e');
        }
      }
      
      // Nếu không kết nối được LM Studio, yêu cầu kiểm duyệt thủ công
      debugPrint('Không kết nối được LM Studio để phân tích mô tả sản phẩm');
      return AnalysisResult(
        type: AnalysisType.description,
        isCompliant: false, // Đánh dấu không tuân thủ để yêu cầu kiểm duyệt
        confidenceScore: 0.0,
        details: 'Không thể kết nối đến AI để phân tích mô tả. Cần kiểm duyệt thủ công.',
      );
    } catch (e) {
      debugPrint('Lỗi khi phân tích mô tả: $e');
      return AnalysisResult(
        type: AnalysisType.description,
        isCompliant: false,
        confidenceScore: 0.5,
        details: 'Lỗi khi phân tích: $e',
      );
    }
  }
} 