import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final String iconName;
  final IconData icon;
  final Color color;
  final String parentId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  Category({
    required this.id,
    required this.name,
    required this.iconName,
    required this.icon,
    required this.color,
    this.parentId = '',
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory Category.fromMap(Map<String, dynamic> map, String id) {
    // Chuyển đổi String iconName thành IconData
    IconData getIconFromName(String iconName) {
      // Default icon nếu không tìm thấy
      if (iconName.isEmpty) return Icons.category;
      
      // Danh sách icon phổ biến
      final iconMap = {
        'book': Icons.book,
        'computer': Icons.computer,
        'electronics': Icons.devices,
        'clothing': Icons.checkroom,
        'sports': Icons.sports_basketball,
        'household': Icons.kitchen,
        'phone': Icons.phone_android,
        'camera': Icons.camera_alt,
        'used': Icons.recycling,
        'stationery': Icons.edit,
        'food': Icons.fastfood,
        'beauty': Icons.face,
        'jewelry': Icons.diamond,
        'toy': Icons.toys,
        'furniture': Icons.chair,
        'transportation': Icons.directions_car,
        'ticket': Icons.confirmation_number,
        'art': Icons.palette,
        'music': Icons.music_note,
        'pet': Icons.pets,
        'travel': Icons.flight,
        'game': Icons.sports_esports,
        'watch': Icons.watch,
        'accessory': Icons.headphones,
        'other': Icons.more_horiz,
        'all': Icons.category_outlined,
        'shop': Icons.shopping_bag,
        'grocery': Icons.shopping_basket,
        'health': Icons.health_and_safety,
        'education': Icons.school,
        'gift': Icons.card_giftcard,
        'tools': Icons.build,
        'garden': Icons.grass,
        'baby': Icons.child_care,
        'office': Icons.business_center,
        'movie': Icons.movie,
        'drink': Icons.local_drink,
        'entertainment': Icons.attractions,
        'book_store': Icons.menu_book,
        'category': Icons.category,
      };

      return iconMap[iconName] ?? Icons.category;
    }

    return Category(
      id: id,
      name: map['name'] ?? '',
      iconName: map['iconName'] ?? '',
      icon: getIconFromName(map['iconName'] ?? ''),
      color: Color(map['color'] ?? 0xFF2196F3),
      parentId: map['parentId'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'iconName': iconName,
      'color': color.value,
      'parentId': parentId,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? DateTime.now(),
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? iconName,
    IconData? icon,
    Color? color,
    String? parentId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      parentId: parentId ?? this.parentId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 