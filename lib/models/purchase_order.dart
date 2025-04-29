import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,
  confirmed,
  shipping,
  delivered,
  cancelled,
  refunded
}

class PurchaseOrder {
  final String id;
  final String buyerId;
  final String buyerName;
  final String sellerId;
  final String? shipperId;
  final String productId;
  final String productTitle;
  final String productImage;
  final double price;
  final double originalPrice; // Giá gốc trước khi áp dụng điểm
  final int quantity;
  final String status;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final String address;
  final String phone;
  final String? note;
  final double? shippingFee;
  final Map<String, dynamic>? paymentDetails;
  final int pointsUsed; // Số điểm đã sử dụng cho đơn hàng
  final double discountAmount; // Số tiền giảm từ việc dùng điểm

  PurchaseOrder({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.sellerId,
    this.shipperId,
    required this.productId,
    required this.productTitle,
    required this.productImage,
    required this.price,
    this.originalPrice = 0.0,
    required this.quantity,
    required this.status,
    required this.createdAt,
    this.deliveredAt,
    required this.address,
    required this.phone,
    this.note,
    this.shippingFee,
    this.paymentDetails,
    this.pointsUsed = 0,
    this.discountAmount = 0.0,
  });

  factory PurchaseOrder.fromMap(Map<String, dynamic> map, String id) {
    return PurchaseOrder(
      id: id,
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? '',
      sellerId: map['sellerId'] ?? '',
      shipperId: map['shipperId'],
      productId: map['productId'] ?? '',
      productTitle: map['productTitle'] ?? '',
      productImage: map['productImage'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      originalPrice: (map['originalPrice'] ?? map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 1,
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      deliveredAt: map['deliveredAt'] != null
          ? (map['deliveredAt'] as Timestamp).toDate()
          : null,
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      note: map['note'],
      shippingFee: (map['shippingFee'] as num?)?.toDouble(),
      paymentDetails: map['paymentDetails'],
      pointsUsed: map['pointsUsed'] ?? 0,
      discountAmount: (map['discountAmount'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'buyerName': buyerName,
      'sellerId': sellerId,
      'shipperId': shipperId,
      'productId': productId,
      'productTitle': productTitle,
      'productImage': productImage,
      'price': price,
      'originalPrice': originalPrice,
      'quantity': quantity,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'deliveredAt':
          deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'address': address,
      'phone': phone,
      'note': note,
      'shippingFee': shippingFee,
      'paymentDetails': paymentDetails,
      'pointsUsed': pointsUsed,
      'discountAmount': discountAmount,
    };
  }

  PurchaseOrder copyWith({
    String? id,
    String? buyerId,
    String? buyerName,
    String? sellerId,
    String? shipperId,
    String? productId,
    String? productTitle,
    String? productImage,
    double? price,
    double? originalPrice,
    int? quantity,
    String? status,
    DateTime? createdAt,
    DateTime? deliveredAt,
    String? address,
    String? phone,
    String? note,
    double? shippingFee,
    Map<String, dynamic>? paymentDetails,
    int? pointsUsed,
    double? discountAmount,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      sellerId: sellerId ?? this.sellerId,
      shipperId: shipperId ?? this.shipperId,
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      productImage: productImage ?? this.productImage,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      note: note ?? this.note,
      shippingFee: shippingFee ?? this.shippingFee,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      pointsUsed: pointsUsed ?? this.pointsUsed,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }
} 