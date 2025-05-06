import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductStatus {
  available,
  sold,
  deleted,
  hidden,
  reserved,
  pending_review,
  rejected
}

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
  final Map<String, dynamic>? location;
  final List<String> tags;
  final Map<String, String> specifications;
  final int viewCount;
  final int favoriteCount;
  final double rating;
  final int reviewCount;
  final ProductStatus status;
  final Map<String, dynamic>? moderationInfo;
  final String moderationStatus;
  final Map<String, dynamic>? moderationResults;

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
    this.location,
    this.tags = const [],
    this.specifications = const {},
    this.viewCount = 0,
    this.favoriteCount = 0,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.status = ProductStatus.available,
    this.moderationInfo,
    this.moderationStatus = 'pending',
    this.moderationResults,
  });

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    // Xác định trạng thái của sản phẩm
    ProductStatus productStatus = ProductStatus.available;
    if (map['isSold'] == true) {
      productStatus = ProductStatus.sold;
    } else if (map['status'] != null) {
      String statusString = map['status'];
      if (statusString == 'sold') productStatus = ProductStatus.sold;
      else if (statusString == 'deleted') productStatus = ProductStatus.deleted;
      else if (statusString == 'hidden') productStatus = ProductStatus.hidden;
      else if (statusString == 'reserved') productStatus = ProductStatus.reserved;
      else if (statusString == 'pending_review') productStatus = ProductStatus.pending_review;
      else if (statusString == 'rejected') productStatus = ProductStatus.rejected;
    }

    // Xử lý trường location - có thể là String hoặc Map
    Map<String, dynamic>? locationData;
    if (map['location'] != null) {
      if (map['location'] is String) {
        // Chuyển đổi từ String thành Map
        locationData = {
          'address': map['location'],
        };
      } else if (map['location'] is Map) {
        locationData = Map<String, dynamic>.from(map['location'] as Map);
      }
    }

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
      location: locationData,
      tags: List<String>.from(map['tags'] ?? []),
      specifications: Map<String, String>.from(map['specifications'] ?? {}),
      viewCount: map['viewCount'] ?? 0,
      favoriteCount: map['favoriteCount'] ?? 0,
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      status: productStatus,
      moderationInfo: map['moderationInfo'],
      moderationStatus: map['moderationStatus'] ?? 'pending',
      moderationResults: map['moderationResults'],
    );
  }

  Map<String, dynamic> toMap() {
    String statusString = 'available';
    if (status == ProductStatus.sold) statusString = 'sold';
    else if (status == ProductStatus.deleted) statusString = 'deleted';
    else if (status == ProductStatus.hidden) statusString = 'hidden';
    else if (status == ProductStatus.reserved) statusString = 'reserved';
    else if (status == ProductStatus.pending_review) statusString = 'pending_review';
    else if (status == ProductStatus.rejected) statusString = 'rejected';

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
      'rating': rating,
      'reviewCount': reviewCount,
      'status': statusString,
      'moderationInfo': moderationInfo,
      'moderationStatus': moderationStatus,
      'moderationResults': moderationResults,
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
    Map<String, dynamic>? location,
    List<String>? tags,
    Map<String, String>? specifications,
    int? viewCount,
    int? favoriteCount,
    double? rating,
    int? reviewCount,
    ProductStatus? status,
    Map<String, dynamic>? moderationInfo,
    String? moderationStatus,
    Map<String, dynamic>? moderationResults,
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
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      status: status ?? this.status,
      moderationInfo: moderationInfo ?? this.moderationInfo,
      moderationStatus: moderationStatus ?? this.moderationStatus,
      moderationResults: moderationResults ?? this.moderationResults,
    );
  }
} 