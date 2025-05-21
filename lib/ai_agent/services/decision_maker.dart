import 'package:flutter/foundation.dart';
import '../models/analysis_result.dart';
import '../models/review_decision.dart';

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

  DecisionMaker();

  Future<ReviewDecision> makeDecision(
    String productId,
    List<AnalysisResult> analysisResults
  ) async {
    try {
      double totalConfidenceScore = 0.0;
      double totalWeight = 0.0;
      List<String> violationDetails = [];
      bool allCompliant = true;
      
      // Tính điểm tổng hợp từ các phân tích
      for (final result in analysisResults) {
        final weight = _weights[result.type] ?? 0.15;
        totalWeight += weight;
        
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
      
      // Logic ra quyết định
      DecisionType decisionType;
      String reason;
      
      if (allCompliant && normalizedScore >= _approvalThreshold) {
        // Nếu tất cả đều tuân thủ và điểm tin cậy cao, phê duyệt
        decisionType = DecisionType.approved;
        reason = 'Sản phẩm tuân thủ tất cả quy định với độ tin cậy cao';
      } else if (!allCompliant && normalizedScore >= _rejectionThreshold) {
        // Nếu có vi phạm và điểm tin cậy cao cho việc từ chối, từ chối
        decisionType = DecisionType.rejected;
        reason = 'Sản phẩm vi phạm một hoặc nhiều quy định';
      } else {
        // Trong trường hợp không chắc chắn, đánh dấu để xem xét thủ công
        decisionType = DecisionType.flaggedForReview;
        reason = allCompliant 
          ? 'Cần kiểm tra thêm để đảm bảo sản phẩm tuân thủ quy định'
          : 'Có dấu hiệu vi phạm nhưng cần xác minh thủ công';
      }
      
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