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
  final Map<String, dynamic>? smtpConfig; // Cấu hình SMTP cho người bán
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
  final bool isAdmin;        // Xác định có phải là admin không
  final List<Map<String, dynamic>> locations; // Danh sách địa chỉ của người dùng
  final String? studentId;    // Mã số sinh viên (nếu có)
  final String? department;   // Khoa/Ngành học (nếu có)
  final int? studentYear;     // Năm học (1, 2, 3, 4, ...)
  final String? major;        // Ngành học
  final String? specialization; // Chuyên ngành
  final List<String> interests; // Sở thích cá nhân
  final List<String> preferredCategories; // Các danh mục sản phẩm quan tâm
  final bool completedSurvey; // Đã hoàn thành khảo sát hay chưa
  final List<String> recentlyViewed; // Thêm trường lưu sản phẩm đã xem gần đây

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
    this.smtpConfig,
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
    this.isAdmin = false,
    this.locations = const [],
    this.studentId,
    this.department,
    this.studentYear,
    this.major,
    this.specialization,
    this.interests = const [],
    this.preferredCategories = const [],
    this.completedSurvey = false,
    this.recentlyViewed = const [], // Khởi tạo mảng rỗng
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoURL: map['photoURL'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
      favoriteProducts: List<String>.from(map['favoriteProducts'] ?? []),
      following: List<String>.from(map['following'] ?? []),
      followers: List<String>.from(map['followers'] ?? []),
      isShipper: map['isShipper'] ?? false,
      isStudent: map['isStudent'] ?? false,
      isAdmin: map['isAdmin'] ?? false,
      locations: List<Map<String, dynamic>>.from(map['locations'] ?? []),
      studentId: map['studentId'] ?? '',
      department: map['department'] ?? '',
      createdAt: map['createdAt'] != null 
        ? (map['createdAt'] as Timestamp).toDate() 
        : DateTime.now(),
      lastActive: map['lastActive'] != null 
        ? (map['lastActive'] as Timestamp).toDate() 
        : DateTime.now(),
      settings: Map<String, dynamic>.from(map['settings'] ?? {'darkMode': false, 'notifications': true}),
      smtpConfig: map['smtpConfig'] as Map<String, dynamic>?,
      nttPoint: map['nttPoint'] ?? 0,
      nttCredit: map['nttCredit'] ?? 0,
      recentlyViewed: List<String>.from(map['recentlyViewed'] ?? []), // Lấy danh sách từ Firestore
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'phoneNumber': phoneNumber,
      'address': address,
      'favoriteProducts': favoriteProducts,
      'following': following,
      'followers': followers,
      'isShipper': isShipper,
      'isStudent': isStudent,
      'isAdmin': isAdmin,
      'locations': locations,
      'studentId': studentId,
      'department': department,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
      'settings': settings,
      'smtpConfig': smtpConfig,
      'nttPoint': nttPoint,
      'nttCredit': nttCredit,
      'recentlyViewed': recentlyViewed, // Lưu danh sách vào Firestore
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    String? phoneNumber,
    String? address,
    List<String>? favoriteProducts,
    List<String>? following,
    List<String>? followers,
    bool? isShipper,
    bool? isStudent,
    String? studentId,
    String? department,
    DateTime? createdAt,
    DateTime? lastActive,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? smtpConfig,
    int? nttPoint,
    int? nttCredit,
    List<String>? recentlyViewed, // Thêm vào phương thức copyWith
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      favoriteProducts: favoriteProducts ?? this.favoriteProducts,
      following: following ?? this.following,
      followers: followers ?? this.followers,
      isShipper: isShipper ?? this.isShipper,
      isStudent: isStudent ?? this.isStudent,
      studentId: studentId ?? this.studentId,
      department: department ?? this.department,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      settings: settings ?? this.settings,
      smtpConfig: smtpConfig ?? this.smtpConfig,
      nttPoint: nttPoint ?? this.nttPoint,
      nttCredit: nttCredit ?? this.nttCredit,
      recentlyViewed: recentlyViewed ?? this.recentlyViewed, // Sử dụng trong copyWith
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