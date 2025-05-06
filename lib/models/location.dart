import 'package:cloud_firestore/cloud_firestore.dart';

class LocationModel {
  final String id;
  final String district; // Quận
  final String name; // Tên khu vực/cơ sở (ví dụ: A, B,C,D)
  final String address; // Địa chỉ đầy đủ
  final Map<String, double>? coordinates; // Tọa độ GPS (nếu có)
  final int order; // Thứ tự sắp xếp
  final bool isActive; // Trạng thái hoạt động
  final DateTime createdAt;
  final DateTime? updatedAt;

  LocationModel({
    required this.id,
    required this.district,
    required this.name,
    required this.address,
    this.coordinates,
    this.order = 0,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory LocationModel.fromMap(Map<String, dynamic> map, String docId) {
    return LocationModel(
      id: docId,
      district: map['district'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      coordinates: map['coordinates'] != null 
        ? {
            'lat': map['coordinates']['lat'] ?? 0.0,
            'lng': map['coordinates']['lng'] ?? 0.0,
          }
        : null,
      order: map['order'] ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null 
        ? (map['updatedAt'] as Timestamp).toDate() 
        : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'district': district,
      'name': name,
      'address': address,
      'coordinates': coordinates,
      'order': order,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  LocationModel copyWith({
    String? id,
    String? district,
    String? name,
    String? address,
    Map<String, double>? coordinates,
    int? order,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LocationModel(
      id: id ?? this.id,
      district: district ?? this.district,
      name: name ?? this.name,
      address: address ?? this.address,
      coordinates: coordinates ?? this.coordinates,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 