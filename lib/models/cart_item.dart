import 'package:cloud_firestore/cloud_firestore.dart';
import 'product.dart';

class CartItem {
  final String id;
  final String productId;
  final String userId;
  final int quantity;
  final double price;
  final Timestamp addedAt;
  
  // Thông tin bổ sung từ sản phẩm để hiển thị
  final String productName;
  final String productImage;
  final String sellerId;
  final String sellerName;
  final bool isAvailable; // Kiểm tra sản phẩm còn khả dụng không

  CartItem({
    required this.id,
    required this.productId,
    required this.userId,
    required this.quantity,
    required this.price,
    required this.addedAt,
    required this.productName,
    required this.productImage,
    required this.sellerId,
    required this.sellerName,
    required this.isAvailable,
  });

  // Tạo CartItem từ Firestore document
  factory CartItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return CartItem(
      id: doc.id,
      productId: data['productId'] ?? '',
      userId: data['userId'] ?? '',
      quantity: data['quantity'] ?? 1,
      price: (data['price'] ?? 0.0).toDouble(),
      addedAt: data['addedAt'] ?? Timestamp.now(),
      productName: data['productName'] ?? '',
      productImage: data['productImage'] ?? '',
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
    );
  }

  // Tạo CartItem từ Product
  factory CartItem.fromProduct(Product product, String userId) {
    return CartItem(
      id: '', // Sẽ được tạo khi lưu vào Firestore
      productId: product.id,
      userId: userId,
      quantity: 1,
      price: product.price,
      addedAt: Timestamp.now(),
      productName: product.title,
      productImage: product.images.isNotEmpty ? product.images.first : '',
      sellerId: product.sellerId,
      sellerName: product.sellerName,
      isAvailable: product.status != ProductStatus.sold && product.status != ProductStatus.deleted,
    );
  }

  // Chuyển đổi sang Map để lưu vào Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'userId': userId,
      'quantity': quantity,
      'price': price,
      'addedAt': addedAt,
      'productName': productName,
      'productImage': productImage,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'isAvailable': isAvailable,
    };
  }

  // Tạo bản sao với thông tin cập nhật
  CartItem copyWith({
    String? id,
    String? productId,
    String? userId,
    int? quantity,
    double? price,
    Timestamp? addedAt,
    String? productName,
    String? productImage,
    String? sellerId,
    String? sellerName,
    bool? isAvailable,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      addedAt: addedAt ?? this.addedAt,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  // Tính tổng giá trị của mặt hàng
  double get total => price * quantity;
} 