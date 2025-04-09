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
  final List<String> followers;
  final List<String> following;
  final bool isShipper;
  final bool isVerified;
  final String? bio;
  final int productCount;
  final double rating;
  final int nttPoint;         // Dùng để giảm giá, khuyến mãi (tương tự Shopee Xu)
  final int nttCredit;        // Điểm uy tín, người dùng mặc định là 100
  final bool isStudent;       // Xác định có phải là sinh viên không
  final String? studentId;    // Mã số sinh viên (nếu có)
  final String? department;   // Khoa/Ngành học (nếu có)

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
    this.followers = const [],
    this.following = const [],
    this.isShipper = false,
    this.isVerified = false,
    this.bio,
    this.productCount = 0,
    this.rating = 0.0,
    this.nttPoint = 0,
    this.nttCredit = 100,
    this.isStudent = false,
    this.studentId,
    this.department,
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
      followers: List<String>.from(map['followers'] ?? []),
      following: List<String>.from(map['following'] ?? []),
      isShipper: map['isShipper'] ?? false,
      isVerified: map['isVerified'] ?? false,
      bio: map['bio'],
      productCount: map['productCount'] ?? 0,
      rating: (map['rating'] ?? 0.0).toDouble(),
      nttPoint: map['nttPoint'] ?? 0,
      nttCredit: map['nttCredit'] ?? 100,
      isStudent: map['isStudent'] ?? false,
      studentId: map['studentId'],
      department: map['department'],
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
      'followers': followers,
      'following': following,
      'isShipper': isShipper,
      'isVerified': isVerified,
      'bio': bio,
      'productCount': productCount,
      'rating': rating,
      'nttPoint': nttPoint,
      'nttCredit': nttCredit,
      'isStudent': isStudent,
      'studentId': studentId,
      'department': department,
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
    List<String>? followers,
    List<String>? following,
    bool? isShipper,
    bool? isVerified,
    String? bio,
    int? productCount,
    double? rating,
    int? nttPoint,
    int? nttCredit,
    bool? isStudent,
    String? studentId,
    String? department,
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
      followers: followers ?? this.followers,
      following: following ?? this.following,
      isShipper: isShipper ?? this.isShipper,
      isVerified: isVerified ?? this.isVerified,
      bio: bio ?? this.bio,
      productCount: productCount ?? this.productCount,
      rating: rating ?? this.rating,
      nttPoint: nttPoint ?? this.nttPoint,
      nttCredit: nttCredit ?? this.nttCredit,
      isStudent: isStudent ?? this.isStudent,
      studentId: studentId ?? this.studentId,
      department: department ?? this.department,
    );
  }

  // Tính % giảm giá dựa trên NTTPoint
  double calculateDiscount([double? price]) {
    if (price != null) {
      // Quy đổi NTTPoint thành % giảm giá (1000 điểm = 1%)
      double discountPercentage = nttPoint / 1000;
      
      // Giới hạn giảm giá tối đa 50%
      discountPercentage = discountPercentage > 50 ? 50 : discountPercentage;
      
      return (price * discountPercentage / 100);
    } else {
      // Trả về tỷ lệ giảm giá dạng thập phân
      if (nttPoint >= 1000) {
        return 0.10; // 10% discount
      } else if (nttPoint >= 500) {
        return 0.05; // 5% discount
      } else if (nttPoint >= 200) {
        return 0.02; // 2% discount
      }
      return 0.0; // No discount
    }
  }
  
  // Kiểm tra mức độ uy tín
  String getCreditRating() {
    if (nttCredit >= 150) return 'Xuất sắc';
    if (nttCredit >= 120) return 'Tốt';
    if (nttCredit >= 100) return 'Bình thường';
    if (nttCredit >= 90) return 'Khá';
    if (nttCredit >= 60) return 'Trung bình';
    return 'Kém';
  }
  
  // Kiểm tra xem có đủ NTTPoint để giảm giá không
  bool hasEnoughPointsForDiscount() {
    // Kiểm tra xem có đủ điểm để giảm giá một phần không
    return nttPoint >= 1000; // Tối thiểu 1000 điểm để giảm 1%
  }

  // Check if user is eligible for buy now pay later
  bool isEligibleForBNPL() {
    return nttCredit >= 80;
  }

  // Check if user is eligible for installment payment
  bool isEligibleForInstallment() {
    return nttCredit >= 100;
  }

  // Calculate max installment period (in months) based on credit
  int getMaxInstallmentPeriod() {
    if (nttCredit >= 150) {
      return 12; // 12 months
    } else if (nttCredit >= 120) {
      return 6; // 6 months
    } else if (nttCredit >= 90) {
      return 3; // 3 months
    }
    return 0; // Not eligible
  }
} 