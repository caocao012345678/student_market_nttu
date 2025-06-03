import 'package:flutter/foundation.dart';
import '../models/analysis_result.dart';
import '../models/review_decision.dart';
import '../utils/lm_studio_client.dart';

class DecisionMaker {
  // Ngưỡng điểm tin cậy để chấp nhận quyết định
  final double _approvalThreshold = 0.8;
  
  // Ngưỡng điểm tin cậy để từ chối quyết định
  final double _rejectionThreshold = 0.7;
  
  // Trọng số cho từng loại phân tích
  final Map<AnalysisType, double> _weights = {
    AnalysisType.title: 0.25,
    AnalysisType.description: 0.40,
    AnalysisType.image: 0.35,
    AnalysisType.price: 0.15,
    AnalysisType.category: 0.10,
  };
  
  final LMStudioClient _lmClient;

  DecisionMaker({LMStudioClient? lmClient}) 
      : _lmClient = lmClient ?? LMStudioClient();

  Future<ReviewDecision> makeDecision(
    String productId,
    List<AnalysisResult> analysisResults
  ) async {
    try {
      // Kiểm tra kết nối LM Studio
      final isLmAvailable = await _lmClient.isAvailable();
      
      // Nếu không kết nối được LM Studio, luôn đánh dấu để xem xét thủ công
      if (!isLmAvailable) {
        debugPrint('Không kết nối được LM Studio, đánh dấu sản phẩm $productId cần kiểm duyệt thủ công');
        return ReviewDecision(
          productId: productId,
          decision: DecisionType.flaggedForReview,
          confidenceScore: 0.0,
          reason: 'Không thể kết nối đến LM Studio để phân tích. Cần kiểm duyệt thủ công.',
          violationDetails: ['Mất kết nối LM Studio'],
        );
      }

      // Log số lượng kết quả phân tích
      debugPrint('Đang xử lý ${analysisResults.length} kết quả phân tích cho sản phẩm $productId');
      
      double totalConfidenceScore = 0.0;
      double totalWeight = 0.0;
      List<String> violationDetails = [];
      bool allCompliant = true;
      
      // Tính điểm tổng hợp từ các phân tích
      for (final result in analysisResults) {
        final weight = _weights[result.type] ?? 0.15;
        totalWeight += weight;
        
        // Log chi tiết từng kết quả phân tích
        debugPrint('Phân tích ${result.type}: isCompliant=${result.isCompliant}, score=${result.confidenceScore}, details=${result.details}');
        
        // Nếu có bất kỳ kết quả nào không tuân thủ, ghi lại lý do vi phạm
        if (!result.isCompliant) {
          allCompliant = false;
          violationDetails.add('${result.type.toString().split('.').last}: ${result.details}');
        }
        
        totalConfidenceScore += result.confidenceScore * weight;
      }
      
      // Chuẩn hóa điểm tin cậy
      final normalizedScore = totalWeight > 0.0 
        ? totalConfidenceScore / totalWeight 
        : 0.5;
      
      debugPrint('Phân tích tổng hợp: allCompliant=$allCompliant, normalizedScore=$normalizedScore');
      
      // Logic ra quyết định
      DecisionType decisionType;
      String reason;
      
      // Sửa logic ra quyết định để đảm bảo nhất quán
      if (allCompliant && normalizedScore >= _approvalThreshold) {
        // Nếu tất cả đều tuân thủ và điểm tin cậy cao, phê duyệt
        decisionType = DecisionType.approved;
        reason = 'Sản phẩm tuân thủ tất cả quy định với độ tin cậy cao';
      } else if (!allCompliant) {
        // Nếu có bất kỳ vi phạm nào, từ chối
        decisionType = DecisionType.rejected;
        reason = 'Sản phẩm vi phạm một hoặc nhiều quy định';
      } else {
        // Trong trường hợp không chắc chắn, đánh dấu để xem xét thủ công
        decisionType = DecisionType.flaggedForReview;
        reason = 'Cần kiểm tra thêm để đảm bảo sản phẩm tuân thủ quy định';
      }
      
      debugPrint('Quyết định cuối cùng: $decisionType với lý do: $reason');
      
      // Tạo quyết định cuối cùng
      return ReviewDecision(
        productId: productId,
        decision: decisionType,
        confidenceScore: normalizedScore,
        reason: reason,
        violationDetails: violationDetails,
      );
    } catch (e) {
      debugPrint('Lỗi khi ra quyết định: $e');
      // Trong trường hợp lỗi, luôn đánh dấu để xem xét thủ công
      return ReviewDecision(
        productId: productId,
        decision: DecisionType.flaggedForReview,
        confidenceScore: 0.0,
        reason: 'Lỗi khi ra quyết định',
        violationDetails: ['Lỗi xử lý: $e'],
      );
    }
  }
} 