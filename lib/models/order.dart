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
  final String sellerId;
  final String? shipperId;
  final String productId;
  final double amount;
  final String paymentMethod;
  final bool isPaid;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final String shippingAddress;
  final String buyerPhone;
  final String? note;
  final double? shippingFee;
  final Map<String, dynamic>? paymentDetails;

  PurchaseOrder({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    this.shipperId,
    required this.productId,
    required this.amount,
    required this.paymentMethod,
    required this.isPaid,
    required this.status,
    required this.createdAt,
    this.deliveredAt,
    required this.shippingAddress,
    required this.buyerPhone,
    this.note,
    this.shippingFee,
    this.paymentDetails,
  });

  factory PurchaseOrder.fromMap(Map<String, dynamic> map, String id) {
    return PurchaseOrder(
      id: id,
      buyerId: map['buyerId'] as String,
      sellerId: map['sellerId'] as String,
      shipperId: map['shipperId'] as String?,
      productId: map['productId'] as String,
      amount: (map['amount'] as num).toDouble(),
      paymentMethod: map['paymentMethod'] as String,
      isPaid: map['isPaid'] as bool,
      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == 'OrderStatus.${map['status']}',
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      deliveredAt: map['deliveredAt'] != null
          ? (map['deliveredAt'] as Timestamp).toDate()
          : null,
      shippingAddress: map['shippingAddress'] as String,
      buyerPhone: map['buyerPhone'] as String,
      note: map['note'] as String?,
      shippingFee: (map['shippingFee'] as num?)?.toDouble(),
      paymentDetails: map['paymentDetails'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'sellerId': sellerId,
      'shipperId': shipperId,
      'productId': productId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'isPaid': isPaid,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'deliveredAt':
          deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'shippingAddress': shippingAddress,
      'buyerPhone': buyerPhone,
      'note': note,
      'shippingFee': shippingFee,
      'paymentDetails': paymentDetails,
    };
  }

  PurchaseOrder copyWith({
    String? id,
    String? buyerId,
    String? sellerId,
    String? shipperId,
    String? productId,
    double? amount,
    String? paymentMethod,
    bool? isPaid,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? deliveredAt,
    String? shippingAddress,
    String? buyerPhone,
    String? note,
    double? shippingFee,
    Map<String, dynamic>? paymentDetails,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      shipperId: shipperId ?? this.shipperId,
      productId: productId ?? this.productId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isPaid: isPaid ?? this.isPaid,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      note: note ?? this.note,
      shippingFee: shippingFee ?? this.shippingFee,
      paymentDetails: paymentDetails ?? this.paymentDetails,
    );
  }
} 