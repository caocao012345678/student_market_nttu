import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final double originalPrice;
  final String category;
  final List<String> images;
  final String sellerId;
  final String sellerName;
  final String sellerAvatar;
  final DateTime createdAt;
  final bool isSold;
  final int quantity;
  final String condition;
  final String location;
  final List<String> tags;
  final Map<String, String> specifications;
  final int viewCount;
  final int favoriteCount;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.originalPrice = 0.0,
    required this.category,
    required this.images,
    required this.sellerId,
    this.sellerName = '',
    this.sellerAvatar = '',
    required this.createdAt,
    this.isSold = false,
    this.quantity = 1,
    this.condition = 'Mới',
    this.location = '',
    this.tags = const [],
    this.specifications = const {},
    this.viewCount = 0,
    this.favoriteCount = 0,
  });

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      originalPrice: (map['originalPrice'] ?? 0.0).toDouble(),
      category: map['category'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      sellerAvatar: map['sellerAvatar'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isSold: map['isSold'] ?? false,
      quantity: map['quantity'] ?? 1,
      condition: map['condition'] ?? 'Mới',
      location: map['location'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      specifications: Map<String, String>.from(map['specifications'] ?? {}),
      viewCount: map['viewCount'] ?? 0,
      favoriteCount: map['favoriteCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'category': category,
      'images': images,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerAvatar': sellerAvatar,
      'createdAt': Timestamp.fromDate(createdAt),
      'isSold': isSold,
      'quantity': quantity,
      'condition': condition,
      'location': location,
      'tags': tags,
      'specifications': specifications,
      'viewCount': viewCount,
      'favoriteCount': favoriteCount,
    };
  }

  Product copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    double? originalPrice,
    String? category,
    List<String>? images,
    String? sellerId,
    String? sellerName,
    String? sellerAvatar,
    DateTime? createdAt,
    bool? isSold,
    int? quantity,
    String? condition,
    String? location,
    List<String>? tags,
    Map<String, String>? specifications,
    int? viewCount,
    int? favoriteCount,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      category: category ?? this.category,
      images: images ?? this.images,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerAvatar: sellerAvatar ?? this.sellerAvatar,
      createdAt: createdAt ?? this.createdAt,
      isSold: isSold ?? this.isSold,
      quantity: quantity ?? this.quantity,
      condition: condition ?? this.condition,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      specifications: specifications ?? this.specifications,
      viewCount: viewCount ?? this.viewCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
    );
  }
} 