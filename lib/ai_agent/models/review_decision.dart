import 'analysis_result.dart';

enum DecisionType {
  approved,
  rejected,
  flaggedForReview
}

class ReviewDecision {
  final String productId;
  final DecisionType decision;
  final double confidenceScore;
  final String reason;
  final List<String> violationDetails;
  final DateTime reviewedAt;

  ReviewDecision({
    required this.productId,
    required this.decision,
    required this.confidenceScore,
    this.reason = '',
    this.violationDetails = const [],
    DateTime? reviewedAt,
  }) : reviewedAt = reviewedAt ?? DateTime.now();

  factory ReviewDecision.fromMap(Map<String, dynamic> map) {
    return ReviewDecision(
      productId: map['productId'] ?? '',
      decision: DecisionType.values.firstWhere(
        (e) => e.toString().split('.').last == map['decision'],
        orElse: () => DecisionType.flaggedForReview,
      ),
      confidenceScore: map['confidenceScore']?.toDouble() ?? 0.0,
      reason: map['reason'] ?? '',
      violationDetails: List<String>.from(map['violationDetails'] ?? []),
      reviewedAt: map['reviewedAt'] != null 
        ? (map['reviewedAt'] is DateTime 
            ? map['reviewedAt'] 
            : DateTime.parse(map['reviewedAt']))
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'decision': decision.toString().split('.').last,
      'confidenceScore': confidenceScore,
      'reason': reason,
      'violationDetails': violationDetails,
      'reviewedAt': reviewedAt.toIso8601String(),
    };
  }
} 