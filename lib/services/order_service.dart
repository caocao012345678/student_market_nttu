import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/purchase_order.dart';
import '../services/payment_service.dart';

class OrderService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // Create a new order
  Future<String> createOrder(PurchaseOrder order) async {
    try {
      _isLoading = true;
      notifyListeners();

      final docRef = await _firestore.collection('orders').add(order.toMap());

      _isLoading = false;
      notifyListeners();

      return docRef.id;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Get order by id
  Future<PurchaseOrder> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (!doc.exists) throw Exception('Order not found');
      return PurchaseOrder.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw e;
    }
  }

  // Get orders by buyer id
  Stream<List<PurchaseOrder>> getOrdersByBuyerId(String buyerId) {
    return _firestore
        .collection('orders')
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PurchaseOrder.fromMap(doc.data(), doc.id)).toList());
  }

  // Get orders by seller id
  Stream<List<PurchaseOrder>> getOrdersBySellerId(String sellerId) {
    return _firestore
        .collection('orders')
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PurchaseOrder.fromMap(doc.data(), doc.id)).toList());
  }

  // Get orders by shipper id
  Stream<List<PurchaseOrder>> getOrdersByShipperId(String shipperId) {
    return _firestore
        .collection('orders')
        .where('shipperId', isEqualTo: shipperId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PurchaseOrder.fromMap(doc.data(), doc.id)).toList());
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('orders').doc(orderId).update({
        'status': status.toString().split('.').last,
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Assign shipper to order
  Future<void> assignShipper(String orderId, String shipperId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('orders').doc(orderId).update({
        'shipperId': shipperId,
        'status': OrderStatus.shipping.toString().split('.').last,
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Mark order as delivered
  Future<void> markAsDelivered(String orderId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('orders').doc(orderId).update({
        'status': OrderStatus.delivered.toString().split('.').last,
        'deliveredAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Update payment status
  Future<void> updatePaymentStatus(String orderId, bool isPaid) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('orders').doc(orderId).update({
        'isPaid': isPaid,
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Get order statistics
  Future<Map<String, dynamic>> getOrderStatistics(String userId) async {
    try {
      final buyerOrders = await _firestore
          .collection('orders')
          .where('buyerId', isEqualTo: userId)
          .get();

      final sellerOrders = await _firestore
          .collection('orders')
          .where('sellerId', isEqualTo: userId)
          .get();

      final shipperOrders = await _firestore
          .collection('orders')
          .where('shipperId', isEqualTo: userId)
          .get();

      return {
        'totalBought': buyerOrders.docs.length,
        'totalSold': sellerOrders.docs.length,
        'totalDelivered': shipperOrders.docs.length,
        'totalSpent': buyerOrders.docs
            .map((doc) => (doc.data()['amount'] as num).toDouble())
            .fold(0.0, (prev, amount) => prev + amount),
        'totalEarned': sellerOrders.docs
            .map((doc) => (doc.data()['amount'] as num).toDouble())
            .fold(0.0, (prev, amount) => prev + amount),
      };
    } catch (e) {
      throw e;
    }
  }

  // Thêm method mới
  Future<void> completeOrder(String orderId, String paymentMethod) async {
    try {
      _isLoading = true;
      notifyListeners();

      final order = await getOrderById(orderId);
      
      // Xử lý thanh toán
      final paymentService = PaymentService();
      final orderWithPayment = await paymentService.processPayment(order, paymentMethod);

      if (orderWithPayment.isNotEmpty) {
        // Cập nhật trạng thái đơn hàng
        await _firestore.collection('orders').doc(orderWithPayment).update({
          'status': OrderStatus.confirmed.toString().split('.').last,
        });
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }
} 