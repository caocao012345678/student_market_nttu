import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:student_market_nttu/models/ntt_point_transaction.dart';

class NTTPointService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final int _pointsPerDonationProduct = 10; // 10 NTTPoint cho mỗi sản phẩm đồ tặng
  final int _expiryMonths = 6; // Hạn sử dụng 6 tháng
  
  // Các giao dịch NTTPoint của người dùng hiện tại
  List<NTTPointTransaction> _transactions = [];
  int _availablePoints = 0;
  bool _isLoading = false;

  // Getters
  List<NTTPointTransaction> get transactions => _transactions;
  int get availablePoints => _availablePoints;
  bool get isLoading => _isLoading;

  // Tải lịch sử giao dịch NTTPoint của người dùng
  Future<void> loadTransactions(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final QuerySnapshot snapshot = await _firestore
          .collection('nttPointTransactions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _transactions = snapshot.docs
          .map((doc) => NTTPointTransaction.fromMap(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      await _checkExpiredPoints(userId);
      await _calculateAvailablePoints(userId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Kiểm tra và đánh dấu các điểm đã hết hạn
  Future<void> _checkExpiredPoints(String userId) async {
    final batch = _firestore.batch();
    final now = DateTime.now();
    bool hasExpired = false;

    for (var transaction in _transactions) {
      // Chỉ xét các giao dịch cộng điểm và chưa hết hạn
      if (!transaction.isExpired && 
          transaction.type == NTTPointTransactionType.earned && 
          transaction.expiryDate.isBefore(now)) {
        
        // Cập nhật giao dịch cũ thành đã hết hạn
        DocumentReference docRef = _firestore
            .collection('nttPointTransactions')
            .doc(transaction.id);
        batch.update(docRef, {'isExpired': true});

        // Tạo giao dịch mới ghi nhận việc điểm bị hết hạn
        DocumentReference newDocRef = _firestore
            .collection('nttPointTransactions')
            .doc();
        batch.set(newDocRef, NTTPointTransaction(
          id: newDocRef.id,
          userId: userId,
          createdAt: now,
          expiryDate: now,
          points: transaction.points,
          type: NTTPointTransactionType.expired,
          description: 'Điểm đã hết hạn từ giao dịch ${transaction.id}',
          productId: transaction.productId,
        ).toMap());

        hasExpired = true;
      }
    }

    if (hasExpired) {
      await batch.commit();
      await loadTransactions(userId); // Tải lại giao dịch
    }
  }

  // Tính tổng điểm khả dụng của người dùng
  Future<void> _calculateAvailablePoints(String userId) async {
    int total = 0;
    final now = DateTime.now();

    for (var transaction in _transactions) {
      if (transaction.type == NTTPointTransactionType.earned && 
          !transaction.isExpired && 
          transaction.expiryDate.isAfter(now)) {
        total += transaction.points;
      } else if (transaction.type == NTTPointTransactionType.spent || 
                transaction.type == NTTPointTransactionType.deducted) {
        total -= transaction.points;
      } else if (transaction.type == NTTPointTransactionType.refunded && 
                !transaction.isExpired && 
                transaction.expiryDate.isAfter(now)) {
        total += transaction.points;
      }
    }

    _availablePoints = total < 0 ? 0 : total;
    
    // Cập nhật tổng điểm vào user document
    await _firestore.collection('users').doc(userId).update({
      'nttPoint': _availablePoints,
    });
  }

  // Thêm điểm cho người dùng khi đăng sản phẩm đồ tặng
  Future<void> addPointsForDonationProduct(String userId, String productId, String productTitle) async {
    final now = DateTime.now();
    final expiryDate = DateTime(now.year, now.month + _expiryMonths, now.day);
    
    final transaction = NTTPointTransaction(
      id: '',
      userId: userId,
      createdAt: now,
      expiryDate: expiryDate,
      points: _pointsPerDonationProduct,
      type: NTTPointTransactionType.earned,
      description: 'Đăng sản phẩm đồ tặng: $productTitle',
      productId: productId,
    );

    final docRef = await _firestore.collection('nttPointTransactions').add(transaction.toMap());
    
    // Tải lại giao dịch và cập nhật tổng điểm
    await loadTransactions(userId);
  }

  // Trừ điểm khi xóa hoặc thay đổi loại sản phẩm từ đồ tặng
  Future<void> deductPointsForDonationProduct(String userId, String productId, String productTitle) async {
    // Kiểm tra xem sản phẩm này đã từng được cộng điểm chưa
    final querySnapshot = await _firestore
        .collection('nttPointTransactions')
        .where('userId', isEqualTo: userId)
        .where('productId', isEqualTo: productId)
        .where('type', isEqualTo: NTTPointTransactionType.earned.toString().split('.').last)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return; // Không có giao dịch cộng điểm cho sản phẩm này
    }

    // Tính tổng điểm đã được cộng cho sản phẩm này
    int totalEarnedPoints = 0;
    for (var doc in querySnapshot.docs) {
      final transaction = NTTPointTransaction.fromMap(
          doc.data() as Map<String, dynamic>, doc.id);
      if (!transaction.isExpired) {
        totalEarnedPoints += transaction.points;
      }
    }

    if (totalEarnedPoints <= 0) {
      return; // Không có điểm nào để trừ
    }

    // Tạo giao dịch trừ điểm
    final now = DateTime.now();
    final transaction = NTTPointTransaction(
      id: '',
      userId: userId,
      createdAt: now,
      expiryDate: now.add(const Duration(days: 1)),
      points: totalEarnedPoints,
      type: NTTPointTransactionType.deducted,
      description: 'Điểm bị trừ do xóa/thay đổi sản phẩm đồ tặng: $productTitle',
      productId: productId,
    );

    await _firestore.collection('nttPointTransactions').add(transaction.toMap());
    
    // Tải lại giao dịch và cập nhật tổng điểm
    await loadTransactions(userId);
  }

  // Sử dụng điểm khi thanh toán
  Future<void> usePointsForPurchase(String userId, String orderId, int points, String orderDescription) async {
    if (points <= 0 || points > _availablePoints) {
      throw Exception('Số điểm không hợp lệ hoặc vượt quá số điểm hiện có');
    }

    final now = DateTime.now();
    final transaction = NTTPointTransaction(
      id: '',
      userId: userId,
      createdAt: now,
      expiryDate: now.add(const Duration(days: 1)),
      points: points,
      type: NTTPointTransactionType.spent,
      description: 'Sử dụng điểm cho đơn hàng: $orderDescription',
      orderId: orderId,
    );

    await _firestore.collection('nttPointTransactions').add(transaction.toMap());
    
    // Tải lại giao dịch và cập nhật tổng điểm
    await loadTransactions(userId);
  }

  // Hoàn lại điểm khi hủy đơn hàng
  Future<void> refundPoints(String userId, String orderId, int points) async {
    final now = DateTime.now();
    final expiryDate = DateTime(now.year, now.month + _expiryMonths, now.day);
    
    final transaction = NTTPointTransaction(
      id: '',
      userId: userId,
      createdAt: now,
      expiryDate: expiryDate,
      points: points,
      type: NTTPointTransactionType.refunded,
      description: 'Hoàn điểm từ đơn hàng đã hủy: $orderId',
      orderId: orderId,
    );

    await _firestore.collection('nttPointTransactions').add(transaction.toMap());
    
    // Tải lại giao dịch và cập nhật tổng điểm
    await loadTransactions(userId);
  }
} 