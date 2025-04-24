import 'package:cloud_firestore/cloud_firestore.dart';

enum ModerationStatus {
  pending,      // Đang chờ kiểm duyệt
  approved,     // Đã được duyệt
  rejected,     // Bị từ chối
  in_review     // Đang được xem xét bởi người kiểm duyệt
}

class ModerationResult {
  final String id;
  final String productId;
  final ModerationStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewerId;
  
  // Điểm đánh giá các khía cạnh
  final int imageScore;       // 0-100
  final int contentScore;     // 0-100
  final int complianceScore;  // 0-100
  final int totalScore;       // 0-100
  
  // Phân tích chi tiết
  final List<ModerationIssue>? issues;
  final List<String>? suggestedTags;
  final String? rejectionReason;
  final Map<String, dynamic>? imageAnalysis;
  final Map<String, dynamic>? contentAnalysis;
  
  const ModerationResult({
    required this.id,
    required this.productId,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.reviewerId,
    required this.imageScore,
    required this.contentScore,
    required this.complianceScore,
    required this.totalScore,
    this.issues,
    this.suggestedTags,
    this.rejectionReason,
    this.imageAnalysis,
    this.contentAnalysis,
  });
  
  // Chuyển đổi từ Firestore Map sang ModerationResult
  factory ModerationResult.fromMap(Map<String, dynamic> map, String id) {
    List<ModerationIssue>? issuesList;
    if (map['issues'] != null) {
      issuesList = (map['issues'] as List)
          .map((issue) => ModerationIssue.fromMap(issue))
          .toList();
    }
    
    return ModerationResult(
      id: id,
      productId: map['productId'] ?? '',
      status: _parseStatus(map['status']),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      reviewedAt: map['reviewedAt'] != null 
          ? (map['reviewedAt'] as Timestamp).toDate() 
          : null,
      reviewerId: map['reviewerId'],
      imageScore: map['imageScore'] ?? 0,
      contentScore: map['contentScore'] ?? 0,
      complianceScore: map['complianceScore'] ?? 0,
      totalScore: map['totalScore'] ?? 0,
      issues: issuesList,
      suggestedTags: map['suggestedTags'] != null 
          ? List<String>.from(map['suggestedTags']) 
          : null,
      rejectionReason: map['rejectionReason'],
      imageAnalysis: map['imageAnalysis'],
      contentAnalysis: map['contentAnalysis'],
    );
  }
  
  // Chuyển đổi từ ModerationResult sang Firestore Map
  Map<String, dynamic> toMap() {
    List<Map<String, dynamic>>? issuesMaps;
    if (issues != null) {
      issuesMaps = issues!.map((issue) => issue.toMap()).toList();
    }
    
    return {
      'productId': productId,
      'status': _statusToString(status),
      'createdAt': Timestamp.fromDate(createdAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewerId': reviewerId,
      'imageScore': imageScore,
      'contentScore': contentScore,
      'complianceScore': complianceScore,
      'totalScore': totalScore,
      'issues': issuesMaps,
      'suggestedTags': suggestedTags,
      'rejectionReason': rejectionReason,
      'imageAnalysis': imageAnalysis,
      'contentAnalysis': contentAnalysis,
    };
  }
  
  // Hàm trợ giúp để chuyển đổi chuỗi thành ModerationStatus
  static ModerationStatus _parseStatus(String? status) {
    switch (status) {
      case 'approved':
        return ModerationStatus.approved;
      case 'rejected':
        return ModerationStatus.rejected;
      case 'in_review':
        return ModerationStatus.in_review;
      case 'pending':
      default:
        return ModerationStatus.pending;
    }
  }
  
  // Hàm trợ giúp để chuyển đổi ModerationStatus thành chuỗi
  static String _statusToString(ModerationStatus status) {
    switch (status) {
      case ModerationStatus.approved:
        return 'approved';
      case ModerationStatus.rejected:
        return 'rejected';
      case ModerationStatus.in_review:
        return 'in_review';
      case ModerationStatus.pending:
        return 'pending';
    }
  }
}

// Class mô tả vấn đề được phát hiện trong quá trình kiểm duyệt
class ModerationIssue {
  final String type;        // image, content, compliance
  final String severity;    // high, medium, low
  final String description;
  final String? field;      // title, description, image, tags, etc.
  final int? imageIndex;    // Chỉ số của hình ảnh có vấn đề
  
  const ModerationIssue({
    required this.type,
    required this.severity,
    required this.description,
    this.field,
    this.imageIndex,
  });
  
  factory ModerationIssue.fromMap(Map<String, dynamic> map) {
    return ModerationIssue(
      type: map['type'] ?? '',
      severity: map['severity'] ?? 'low',
      description: map['description'] ?? '',
      field: map['field'],
      imageIndex: map['imageIndex'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'severity': severity,
      'description': description,
      'field': field,
      'imageIndex': imageIndex,
    };
  }
} 