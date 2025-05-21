import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ProductReviewListener {
  final FirebaseFirestore _firestore;
  Function(Map<String, dynamic>) _onProductNeedsReview;
  final Set<String> _processedProductIds = {};

  ProductReviewListener({
    FirebaseFirestore? firestore,
    required Function(Map<String, dynamic>) onProductNeedsReview,
  }) : 
    _firestore = firestore ?? FirebaseFirestore.instance,
    _onProductNeedsReview = onProductNeedsReview;

  Stream<QuerySnapshot>? _productStream;

  // Phương thức cập nhật callback sau khi đã khởi tạo
  void updateCallback(Function(Map<String, dynamic>) onProductNeedsReview) {
    _onProductNeedsReview = onProductNeedsReview;
    debugPrint('Đã cập nhật callback xử lý sản phẩm');
  }

  void startListening() {
    try {
      _productStream = _firestore
          .collection('products')
          .where('status', isEqualTo: 'pending_review')
          .snapshots();

      _productStream?.listen((snapshot) {
        for (final doc in snapshot.docs) {
          final productData = doc.data() as Map<String, dynamic>;
          final productId = doc.id;
          
          // Tránh xử lý trùng lặp
          if (!_processedProductIds.contains(productId)) {
            _processedProductIds.add(productId);
            
            // Thêm ID vào dữ liệu
            productData['id'] = productId;
            
            // Gọi callback
            _onProductNeedsReview(productData);
          }
        }
      });
      
      debugPrint('Bắt đầu lắng nghe các bài đăng cần duyệt');
    } catch (e) {
      debugPrint('Lỗi khi lắng nghe bài đăng: $e');
    }
  }

  void stopListening() {
    _productStream = null;
    debugPrint('Đã dừng lắng nghe các bài đăng cần duyệt');
  }
  
  // Xóa ID sản phẩm khỏi danh sách đã xử lý
  // (cho phép xử lý lại nếu cần)
  void resetProcessedProduct(String productId) {
    _processedProductIds.remove(productId);
  }
  
  // Xóa tất cả ID đã xử lý
  void resetAllProcessedProducts() {
    _processedProductIds.clear();
  }
} 