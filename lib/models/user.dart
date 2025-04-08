import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String photoURL;
  final String phoneNumber;
  final String address;
  final DateTime createdAt;
  final DateTime lastActive;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> settings;
  final List<String> favoriteProducts;
  final bool isShipper;
  final bool isVerified;
  final String? bio;
  final int productCount;
  final double rating;

  UserModel({
    required this.id,
    required this.email,
    this.displayName = '',
    this.photoURL = '',
    this.phoneNumber = '',
    this.address = '',
    required this.createdAt,
    required this.lastActive,
    this.preferences = const {},
    this.settings = const {},
    this.favoriteProducts = const [],
    this.isShipper = false,
    this.isVerified = false,
    this.bio,
    this.productCount = 0,
    this.rating = 0.0,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoURL: map['photoURL'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive: (map['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
      preferences: Map<String, dynamic>.from(map['preferences'] ?? {}),
      settings: Map<String, dynamic>.from(map['settings'] ?? {}),
      favoriteProducts: List<String>.from(map['favoriteProducts'] ?? []),
      isShipper: map['isShipper'] ?? false,
      isVerified: map['isVerified'] ?? false,
      bio: map['bio'],
      productCount: map['productCount'] ?? 0,
      rating: (map['rating'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'phoneNumber': phoneNumber,
      'address': address,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
      'preferences': preferences,
      'settings': settings,
      'favoriteProducts': favoriteProducts,
      'isShipper': isShipper,
      'isVerified': isVerified,
      'bio': bio,
      'productCount': productCount,
      'rating': rating,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    String? phoneNumber,
    String? address,
    DateTime? createdAt,
    DateTime? lastActive,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? settings,
    List<String>? favoriteProducts,
    bool? isShipper,
    bool? isVerified,
    String? bio,
    int? productCount,
    double? rating,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      preferences: preferences ?? this.preferences,
      settings: settings ?? this.settings,
      favoriteProducts: favoriteProducts ?? this.favoriteProducts,
      isShipper: isShipper ?? this.isShipper,
      isVerified: isVerified ?? this.isVerified,
      bio: bio ?? this.bio,
      productCount: productCount ?? this.productCount,
      rating: rating ?? this.rating,
    );
  }
} 