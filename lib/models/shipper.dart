import 'package:cloud_firestore/cloud_firestore.dart';

class Shipper {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String identityCard;
  final String vehicleType;
  final String vehiclePlate;
  final String status; // pending, approved, rejected
  final DateTime createdAt;
  final List<String> deliveryAreas; // List of areas where shipper can deliver
  final double rating;
  final int deliveryCount;

  Shipper({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.identityCard,
    required this.vehicleType,
    required this.vehiclePlate,
    required this.status,
    required this.createdAt,
    required this.deliveryAreas,
    this.rating = 0.0,
    this.deliveryCount = 0,
  });

  factory Shipper.fromMap(Map<String, dynamic> map, String id) {
    return Shipper(
      id: id,
      userId: map['userId'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      identityCard: map['identityCard'] as String,
      vehicleType: map['vehicleType'] as String,
      vehiclePlate: map['vehiclePlate'] as String,
      status: map['status'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      deliveryAreas: List<String>.from(map['deliveryAreas']),
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      deliveryCount: map['deliveryCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'phone': phone,
      'identityCard': identityCard,
      'vehicleType': vehicleType,
      'vehiclePlate': vehiclePlate,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'deliveryAreas': deliveryAreas,
      'rating': rating,
      'deliveryCount': deliveryCount,
    };
  }

  Shipper copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? identityCard,
    String? vehicleType,
    String? vehiclePlate,
    String? status,
    DateTime? createdAt,
    List<String>? deliveryAreas,
    double? rating,
    int? deliveryCount,
  }) {
    return Shipper(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      identityCard: identityCard ?? this.identityCard,
      vehicleType: vehicleType ?? this.vehicleType,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      deliveryAreas: deliveryAreas ?? this.deliveryAreas,
      rating: rating ?? this.rating,
      deliveryCount: deliveryCount ?? this.deliveryCount,
    );
  }
} 