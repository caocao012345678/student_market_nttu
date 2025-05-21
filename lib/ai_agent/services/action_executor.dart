import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/review_decision.dart';

class ActionExecutor {
  final FirebaseFirestore _firestore;

  ActionExecutor({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Thực thi quyết định của AI Agent
  Future<bool> executeDecision(ReviewDecision decision) async {
    try {
      // Cập nhật trạng thái sản phẩm trong Firestore
      final productRef = _firestore.collection('products').doc(decision.productId);
      
      // Lưu lịch sử phê duyệt
      final reviewHistoryRef = _firestore.collection('product_reviews').doc();
      
      final reviewData = {
        'productId': decision.productId,
        'decision': decision.decision.toString().split('.').last,
        'confidenceScore': decision.confidenceScore,
        'reason': decision.reason,
        'violationDetails': decision.violationDetails,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': 'ai_agent',
        'isAutomated': true,
      };
      
      // Trạng thái mới dựa trên quyết định
      String newStatus;
      Map<String, dynamic> productUpdateData = {};
      
      switch (decision.decision) {
        case DecisionType.approved:
          newStatus = 'active';
          productUpdateData = {
            'status': newStatus,
            'approvedAt': FieldValue.serverTimestamp(),
            'approvedBy': 'ai_agent',
          };
          break;
        
        case DecisionType.rejected:
          newStatus = 'rejected';
          productUpdateData = {
            'status': newStatus,
            'rejectedAt': FieldValue.serverTimestamp(),
            'rejectedBy': 'ai_agent',
            'rejectionReason': decision.reason,
          };
          break;
        
        case DecisionType.flaggedForReview:
          newStatus = 'pending_manual_review';
          productUpdateData = {
            'status': newStatus,
            'flaggedAt': FieldValue.serverTimestamp(),
            'flaggedBy': 'ai_agent',
            'flagReason': decision.reason,
          };
          break;
      }
      
      // Thực hiện giao dịch để đảm bảo tính nhất quán
      await _firestore.runTransaction((transaction) async {
        // Cập nhật trạng thái sản phẩm
        transaction.update(productRef, productUpdateData);
        
        // Lưu lịch sử phê duyệt
        transaction.set(reviewHistoryRef, reviewData);
      });
      
      debugPrint('Đã thực thi quyết định: ${decision.decision} cho sản phẩm ${decision.productId}');
      return true;
    } catch (e) {
      debugPrint('Lỗi khi thực thi quyết định: $e');
      return false;
    }
  }
  
  /// Gửi thông báo cho người dùng về quyết định
  Future<bool> sendNotificationToUser(String userId, ReviewDecision decision) async {
    try {
      // Tạo nội dung thông báo dựa trên quyết định
      String title;
      String body;
      
      switch (decision.decision) {
        case DecisionType.approved:
          title = 'Bài đăng đã được duyệt';
          body = 'Bài đăng của bạn đã được duyệt và hiển thị trên hệ thống.';
          break;
        
        case DecisionType.rejected:
          title = 'Bài đăng bị từ chối';
          body = 'Bài đăng của bạn không được duyệt: ${decision.reason}';
          break;
        
        case DecisionType.flaggedForReview:
          title = 'Bài đăng đang được xem xét';
          body = 'Bài đăng của bạn đang được xem xét bởi quản trị viên.';
          break;
      }
      
      // Lưu thông báo vào Firestore
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'relatedTo': 'product',
        'relatedId': decision.productId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Thực hiện gửi thông báo đẩy ở đây nếu cần
      
      return true;
    } catch (e) {
      debugPrint('Lỗi khi gửi thông báo: $e');
      return false;
    }
  }
  
  /// Khôi phục quyết định - trong trường hợp quản trị viên muốn khôi phục sản phẩm bị từ chối
  Future<bool> revertDecision(String productId, String newStatus, String adminId) async {
    try {
      final productRef = _firestore.collection('products').doc(productId);
      
      // Cập nhật trạng thái mới
      await productRef.update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': adminId,
        'previousDecision': 'reverted_by_admin',
      });
      
      // Lưu lịch sử
      await _firestore.collection('product_reviews').add({
        'productId': productId,
        'decision': 'reverted',
        'newStatus': newStatus,
        'confidenceScore': 1.0,
        'reason': 'Quyết định được khôi phục bởi quản trị viên',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': adminId,
        'isAutomated': false,
      });
      
      return true;
    } catch (e) {
      debugPrint('Lỗi khi khôi phục quyết định: $e');
      return false;
    }
  }
} 