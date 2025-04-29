import 'package:cloud_firestore/cloud_firestore.dart';

enum NTTPointTransactionType {
  earned,       // Điểm tích lũy được 
  spent,        // Điểm đã sử dụng
  expired,      // Điểm đã hết hạn
  refunded,     // Điểm hoàn lại (ví dụ: hủy đơn)
  deducted      // Điểm bị trừ (ví dụ: xóa sản phẩm đồ tặng)
}

class NTTPointTransaction {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime expiryDate;
  final int points;
  final NTTPointTransactionType type;
  final String description;
  final String? productId;
  final String? orderId;
  final bool isExpired;

  NTTPointTransaction({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.expiryDate,
    required this.points,
    required this.type,
    required this.description,
    this.productId,
    this.orderId,
    this.isExpired = false,
  });

  factory NTTPointTransaction.fromMap(Map<String, dynamic> map, String id) {
    return NTTPointTransaction(
      id: id,
      userId: map['userId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      expiryDate: (map['expiryDate'] as Timestamp).toDate(),
      points: map['points'] ?? 0,
      type: NTTPointTransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => NTTPointTransactionType.earned,
      ),
      description: map['description'] ?? '',
      productId: map['productId'],
      orderId: map['orderId'],
      isExpired: map['isExpired'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'points': points,
      'type': type.toString().split('.').last,
      'description': description,
      'productId': productId,
      'orderId': orderId,
      'isExpired': isExpired,
    };
  }
} 