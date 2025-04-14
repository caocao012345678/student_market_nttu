import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<CartItem> _cartItems = [];
  bool _isLoading = false;
  String _error = '';

  // Getters
  List<CartItem> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  String get error => _error;

  // Tính tổng số lượng sản phẩm trong giỏ hàng
  int get itemCount {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  // Tính tổng giá trị giỏ hàng
  double get totalPrice {
    return _cartItems.fold(0.0, (sum, item) => sum + item.total);
  }

  // Lấy danh sách sản phẩm trong giỏ hàng của người dùng
  Future<void> fetchCartItems(String userId) async {
    if (userId.isEmpty) return;
    
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('carts')
          .where('userId', isEqualTo: userId)
          .get();

      _cartItems = snapshot.docs.map((doc) => CartItem.fromFirestore(doc)).toList();
      
      // Sắp xếp theo thời gian thêm vào giỏ hàng (mới nhất lên đầu)
      _cartItems.sort((a, b) => b.addedAt.compareTo(a.addedAt));
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Không thể tải giỏ hàng: $e';
      notifyListeners();
    }
  }

  // Thêm sản phẩm vào giỏ hàng
  Future<void> addToCart(Product product, String userId) async {
    if (userId.isEmpty) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      // Kiểm tra xem sản phẩm đã có trong giỏ hàng chưa
      final existingItemQuery = await _firestore
          .collection('carts')
          .where('userId', isEqualTo: userId)
          .where('productId', isEqualTo: product.id)
          .get();

      if (existingItemQuery.docs.isNotEmpty) {
        // Sản phẩm đã có trong giỏ hàng, tăng số lượng
        final existingDoc = existingItemQuery.docs.first;
        final existingItem = CartItem.fromFirestore(existingDoc);
        await updateQuantity(existingItem.id, existingItem.quantity + 1);
      } else {
        // Thêm sản phẩm mới vào giỏ hàng
        final cartItem = CartItem.fromProduct(product, userId);
        await _firestore.collection('carts').add(cartItem.toFirestore());
      }

      await fetchCartItems(userId);
    } catch (e) {
      _error = 'Không thể thêm vào giỏ hàng: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cập nhật số lượng sản phẩm
  Future<void> updateQuantity(String cartItemId, int newQuantity) async {
    if (cartItemId.isEmpty || newQuantity < 1) return;
    
    try {
      await _firestore.collection('carts').doc(cartItemId).update({
        'quantity': newQuantity,
      });

      // Cập nhật trạng thái local
      final index = _cartItems.indexWhere((item) => item.id == cartItemId);
      if (index != -1) {
        _cartItems[index] = _cartItems[index].copyWith(quantity: newQuantity);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Không thể cập nhật số lượng: $e';
      notifyListeners();
    }
  }

  // Xóa sản phẩm khỏi giỏ hàng
  Future<void> removeFromCart(String cartItemId) async {
    if (cartItemId.isEmpty) return;
    
    try {
      await _firestore.collection('carts').doc(cartItemId).delete();

      // Cập nhật trạng thái local
      _cartItems.removeWhere((item) => item.id == cartItemId);
      notifyListeners();
    } catch (e) {
      _error = 'Không thể xóa sản phẩm: $e';
      notifyListeners();
    }
  }

  // Xóa tất cả sản phẩm trong giỏ hàng
  Future<void> clearCart(String userId) async {
    if (userId.isEmpty) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('carts')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      _cartItems = [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Không thể xóa giỏ hàng: $e';
      _isLoading = false;
      notifyListeners();
    }
  }
} 