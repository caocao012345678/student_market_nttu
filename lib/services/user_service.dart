import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user.dart';

class UserService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  UserModel? _currentUser;
  bool _isLoading = false;
  
  // Thêm Map để lưu cache thông tin người dùng khác
  final Map<String, UserModel> _userCache = {};

  UserService() {
    _initUserData();
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  Future<void> _initUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      await getUserData(user.uid);
    }

    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        await getUserData(user.uid);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<UserModel> getUserData(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data()!, userId);
      } else {
        // Create a basic user document if it doesn't exist
        final user = _auth.currentUser;
        if (user != null) {
          // Tạo map dữ liệu người dùng trực tiếp để đảm bảo đầy đủ các trường
          final Map<String, dynamic> userData = {
            'email': user.email ?? '',
            'displayName': user.displayName ?? '',
            'photoURL': user.photoURL ?? '',
            'phoneNumber': user.phoneNumber ?? '',
            'address': '',
            'createdAt': FieldValue.serverTimestamp(),
            'lastActive': FieldValue.serverTimestamp(),
            'preferences': {},
            'settings': {},
            'favoriteProducts': [],
            'followers': [],
            'following': [],
            'isShipper': false,
            'isVerified': false,
            'productCount': 0,
            'rating': 0.0,
            'nttPoint': 0,
            'nttCredit': 100,
            'isStudent': false,
            'interests': [],
            'preferredCategories': [],
            'completedSurvey': false,
            'isAdmin': false,
            'role': 'user',
          };
          
          // Lưu dữ liệu người dùng mới vào Firestore
          await _firestore.collection('users').doc(userId).set(userData);
          
          // Tạo đối tượng UserModel
          _currentUser = UserModel(
            id: userId,
            email: user.email ?? '',
            displayName: user.displayName ?? '',
            photoURL: user.photoURL ?? '',
            phoneNumber: user.phoneNumber ?? '',
            address: '',
            createdAt: DateTime.now(),
            lastActive: DateTime.now(),
            isAdmin: false,
          );
        }
      }

      // Update the lastActive field
      await _firestore.collection('users').doc(userId).update({
        'lastActive': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
      return _currentUser!;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<void> updateUserProfile({
    String? displayName,
    String? phoneNumber,
    String? address,
    bool? isStudent,
    String? studentId,
    String? department,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) throw Exception('Không có người dùng đăng nhập');

      final updates = <String, dynamic>{};
      if (displayName != null) {
        updates['displayName'] = displayName;
        await user.updateDisplayName(displayName);
      }
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (address != null) updates['address'] = address;
      if (isStudent != null) updates['isStudent'] = isStudent;
      if (studentId != null) updates['studentId'] = studentId;
      if (department != null) updates['department'] = department;

      await _firestore.collection('users').doc(user.uid).update(updates);
      await getUserData(user.uid);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<void> updateUserPhoto(dynamic image) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) throw Exception('Không có người dùng đăng nhập');

      String photoURL = '';
      final fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}';
      final ref = _storage.ref().child('users/$fileName');

      if (kIsWeb) {
        if (image is XFile) {
          final bytes = await image.readAsBytes();
          final metadata = SettableMetadata(
            contentType: 'image/${image.name.split('.').last}',
          );
          await ref.putData(bytes, metadata);
        } else {
          throw Exception('Định dạng ảnh không hỗ trợ');
        }
      } else {
        if (image is File) {
          await ref.putFile(image);
        } else {
          throw Exception('Định dạng ảnh không hỗ trợ');
        }
      }

      photoURL = await ref.getDownloadURL();
      await user.updatePhotoURL(photoURL);
      await _firestore.collection('users').doc(user.uid).update({
        'photoURL': photoURL,
      });
      await getUserData(user.uid);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<void> toggleFavoriteProduct(String productId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Không có người dùng đăng nhập');
      if (_currentUser == null) await getUserData(user.uid);

      final favoriteProducts = [..._currentUser!.favoriteProducts];
      if (favoriteProducts.contains(productId)) {
        favoriteProducts.remove(productId);
      } else {
        favoriteProducts.add(productId);
      }

      await _firestore.collection('users').doc(user.uid).update({
        'favoriteProducts': favoriteProducts,
      });

      _currentUser = _currentUser!.copyWith(favoriteProducts: favoriteProducts);
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateUserSettings(Map<String, dynamic> settings) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) throw Exception('Không có người dùng đăng nhập');

      await _firestore.collection('users').doc(user.uid).update({
        'settings': settings,
      });
      await getUserData(user.uid);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<void> requestShipperRole() async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) throw Exception('Không có người dùng đăng nhập');

      // Create a shipper request document
      await _firestore.collection('shipperRequests').add({
        'userId': user.uid,
        'email': user.email,
        'displayName': _currentUser?.displayName ?? user.displayName ?? '',
        'phoneNumber': _currentUser?.phoneNumber ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<List<UserModel>> getUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw e;
    }
  }

  Stream<UserModel> getUserStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => UserModel.fromMap(doc.data()!, doc.id));
  }

  // Lấy thông tin người dùng theo ID
  Future<UserModel?> getUserById(String userId) async {
    if (userId.isEmpty) return null;
    
    try {
      // Kiểm tra xem có phải người dùng hiện tại không
      if (_currentUser != null && _currentUser!.id == userId) {
        return _currentUser;
      }
      
      // Kiểm tra trong cache
      if (_userCache.containsKey(userId)) {
        return _userCache[userId];
      }
      
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists) {
        // Tạo model người dùng từ dữ liệu Firestore
        final userModel = UserModel.fromMap(doc.data()!, userId);
        
        // Lưu vào cache
        _userCache[userId] = userModel;
        
        // Thông báo cho UI cập nhật
        notifyListeners();
        
        return userModel;
      }
    } catch (e) {
      print('Error getting user by ID: $e');
    }
    
    return null;
  }
  
  // Kiểm tra xem người dùng hiện tại có đang follow userId không
  Future<bool> isFollowing(String userId) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;
      
      final userData = doc.data();
      final followingList = List<String>.from(userData?['following'] ?? []);
      return followingList.contains(userId);
    } catch (e) {
      return false;
    }
  }
  
  // Follow/Unfollow người dùng
  Future<void> toggleFollow(String userId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Không có người dùng đăng nhập');
    if (user.uid == userId) throw Exception('Không thể follow chính mình');
    
    final isCurrentlyFollowing = await isFollowing(userId);
    
    // Batch operation để cập nhật cả hai bên
    final batch = _firestore.batch();
    
    final currentUserRef = _firestore.collection('users').doc(user.uid);
    final targetUserRef = _firestore.collection('users').doc(userId);
    
    if (isCurrentlyFollowing) {
      // Unfollow: Xóa khỏi danh sách following của người dùng hiện tại
      batch.update(currentUserRef, {
        'following': FieldValue.arrayRemove([userId])
      });
      
      // Xóa khỏi danh sách followers của người dùng được unfollow
      batch.update(targetUserRef, {
        'followers': FieldValue.arrayRemove([user.uid])
      });
    } else {
      // Follow: Thêm vào danh sách following của người dùng hiện tại
      batch.update(currentUserRef, {
        'following': FieldValue.arrayUnion([userId])
      });
      
      // Thêm vào danh sách followers của người dùng được follow
      batch.update(targetUserRef, {
        'followers': FieldValue.arrayUnion([user.uid])
      });
    }
    
    await batch.commit();
    
    // Cập nhật thông tin người dùng hiện tại
    if (_currentUser != null) {
      await getUserData(user.uid);
    }
  }
  
  // Lấy số lượng follower của người dùng
  Future<int> getFollowerCount(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return 0;
      
      final userData = doc.data();
      final followers = List<String>.from(userData?['followers'] ?? []);
      return followers.length;
    } catch (e) {
      return 0;
    }
  }
  
  // Lấy số lượng following của người dùng
  Future<int> getFollowingCount(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return 0;
      
      final userData = doc.data();
      final following = List<String>.from(userData?['following'] ?? []);
      return following.length;
    } catch (e) {
      return 0;
    }
  }

  // Phương thức nạp NTTPoint vào tài khoản
  Future<void> rechargeNTTPoint(int amount) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) throw Exception('Không có người dùng đăng nhập');
      if (_currentUser == null) await getUserData(user.uid);

      // Cập nhật giá trị NTTPoint trong Firestore
      final currentPoints = _currentUser!.nttPoint;
      await _firestore.collection('users').doc(user.uid).update({
        'nttPoint': currentPoints + amount,
      });

      // Tạo lịch sử giao dịch
      await _firestore.collection('transactions').add({
        'userId': user.uid,
        'type': 'recharge',
        'amount': amount,
        'balance': currentPoints + amount,
        'description': 'Nạp $amount NTTPoint',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Cập nhật lại dữ liệu người dùng
      await getUserData(user.uid);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Sử dụng NTTPoint khi mua hàng
  Future<void> useNTTPoint(int amount, String description) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) throw Exception('Không có người dùng đăng nhập');
      if (_currentUser == null) await getUserData(user.uid);

      if (_currentUser!.nttPoint < amount) {
        throw Exception('Số dư NTTPoint không đủ');
      }

      // Cập nhật giá trị NTTPoint trong Firestore
      final currentPoints = _currentUser!.nttPoint;
      await _firestore.collection('users').doc(user.uid).update({
        'nttPoint': currentPoints - amount,
      });

      // Tạo lịch sử giao dịch
      await _firestore.collection('transactions').add({
        'userId': user.uid,
        'type': 'payment',
        'amount': -amount,
        'balance': currentPoints - amount,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Cập nhật lại dữ liệu người dùng
      await getUserData(user.uid);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Thêm sản phẩm vào lịch sử xem gần đây của người dùng
  Future<void> addToRecentlyViewed(String productId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return; // Không làm gì nếu người dùng chưa đăng nhập
      
      // Lấy dữ liệu người dùng hiện tại
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return;
      
      // Lấy danh sách sản phẩm đã xem gần đây
      List<String> recentlyViewed = List<String>.from(userDoc.data()?['recentlyViewed'] ?? []);
      
      // Xóa sản phẩm khỏi danh sách nếu đã tồn tại (để sau đó thêm lại vào đầu)
      recentlyViewed.remove(productId);
      
      // Thêm sản phẩm vào đầu danh sách
      recentlyViewed.insert(0, productId);
      
      // Giới hạn danh sách chỉ lưu tối đa 20 sản phẩm gần nhất
      if (recentlyViewed.length > 20) {
        recentlyViewed = recentlyViewed.sublist(0, 20);
      }
      
      // Cập nhật Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'recentlyViewed': recentlyViewed,
      });
      
      // Cập nhật dữ liệu người dùng local nếu cần
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(recentlyViewed: recentlyViewed);
        notifyListeners();
      }
    } catch (e) {
      print('Error adding to recently viewed: $e');
    }
  }
  
  // Lấy danh sách sản phẩm đã xem gần đây
  Future<List<String>> getRecentlyViewed() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];
      
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return [];
      
      return List<String>.from(userDoc.data()?['recentlyViewed'] ?? []);
    } catch (e) {
      print('Error getting recently viewed products: $e');
      return [];
    }
  }

  // Cập nhật điểm uy tín (NTTCredit)
  Future<void> updateNTTCredit(int points, String reason) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) throw Exception('Không có người dùng đăng nhập');
      if (_currentUser == null) await getUserData(user.uid);

      final currentCredit = _currentUser!.nttCredit;
      final newCredit = currentCredit + points;
      
      // Đảm bảo NTTCredit không âm
      final finalCredit = newCredit < 0 ? 0 : newCredit;

      await _firestore.collection('users').doc(user.uid).update({
        'nttCredit': finalCredit,
      });

      // Ghi nhận hoạt động thay đổi điểm uy tín
      await _firestore.collection('creditHistory').add({
        'userId': user.uid,
        'points': points,
        'beforeCredit': currentCredit,
        'afterCredit': finalCredit,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Cập nhật lại dữ liệu người dùng
      await getUserData(user.uid);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Lấy danh sách người dùng có rating cao nhất
  Future<List<Map<String, dynamic>>> getTopRatedUsers({int limit = 4}) async {
    try {
      // Không còn lọc theo productCount > 0, chỉ lấy theo rating
      final snapshot = await _firestore
          .collection('users')
          .orderBy('rating', descending: true) // Sắp xếp theo rating cao nhất
          .limit(limit)
          .get();
      
      final List<Map<String, dynamic>> result = [];
      for (var doc in snapshot.docs) {
        final userData = doc.data();
        final id = doc.id;
        final user = UserModel.fromMap(userData, id);
        // Đảm bảo dữ liệu hợp lệ về hiển thị
        result.add({
          'id': user.id,
          'name': user.displayName.isNotEmpty ? user.displayName : 'Người dùng',
          'avatar': user.photoURL.isNotEmpty ? user.photoURL : 'https://via.placeholder.com/80',
          'rating': user.rating > 0 ? user.rating : 4.5, // Nếu rating = 0, hiển thị 4.5
          'productCount': user.productCount > 0 ? user.productCount : 1, // Tối thiểu là 1
        });
      }
      
      // Nếu không có dữ liệu từ Firestore, lấy người dùng bất kỳ
      if (result.isEmpty) {
        final usersSnapshot = await _firestore
            .collection('users')
            .limit(limit)
            .get();
        
        for (var doc in usersSnapshot.docs) {
          final userData = doc.data();
          final id = doc.id;
          final user = UserModel.fromMap(userData, id);
          result.add({
            'id': user.id,
            'name': user.displayName.isNotEmpty ? user.displayName : 'Người dùng',
            'avatar': user.photoURL.isNotEmpty ? user.photoURL : 'https://via.placeholder.com/80',
            'rating': 4.5, // Rating mặc định
            'productCount': 1, // Số sản phẩm mặc định
          });
        }
      }
      
      return result;
    } catch (e) {
      print('Lỗi khi lấy người dùng có rating cao: $e');
      // Vẫn trả về danh sách rỗng
      return [];
    }
  }

  // Kiểm tra xem người dùng hiện tại có phải là admin hay không
  Future<bool> isCurrentUserAdmin() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return false;
      }
      
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      
      if (!userDoc.exists) {
        return false;
      }
      
      final userData = userDoc.data();
      // Kiểm tra cả hai trường để đảm bảo tính nhất quán
      return (userData?['role'] == 'admin' || userData?['isAdmin'] == true);
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Phương thức lấy danh sách người dùng có bộ lọc
  Future<List<Map<String, dynamic>>> getUserListWithFilter({
    String? roleFilter,
    String? searchQuery,
  }) async {
    try {
      Query query = _firestore.collection('users');
      
      // Áp dụng bộ lọc theo vai trò
      if (roleFilter != null && roleFilter.isNotEmpty) {
        if (roleFilter == 'admin') {
          query = query.where('isAdmin', isEqualTo: true);
        } else if (roleFilter == 'user') {
          query = query.where('isAdmin', isEqualTo: false);
        }
      }
      
      final querySnapshot = await query.get();
      
      // Xử lý kết quả và lọc theo từ khóa tìm kiếm
      List<Map<String, dynamic>> users = [];
      for (var doc in querySnapshot.docs) {
        final userData = doc.data() as Map<String, dynamic>;
        userData['id'] = doc.id;
        
        // Áp dụng bộ lọc theo từ khóa tìm kiếm
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final String name = (userData['fullName'] ?? '').toLowerCase();
          final String email = (userData['email'] ?? '').toLowerCase();
          final String searchLower = searchQuery.toLowerCase();
          
          if (!name.contains(searchLower) && !email.contains(searchLower)) {
            continue; // Bỏ qua nếu không khớp với từ khóa tìm kiếm
          }
        }
        
        users.add(userData);
      }
      
      return users;
    } catch (e) {
      debugPrint('Error fetching users: $e');
      return [];
    }
  }

  // Phương thức cập nhật vai trò người dùng
  Future<bool> updateUserRole(String userId, bool isAdmin) async {
    try {
      // Kiểm tra xem người dùng hiện tại có quyền admin không
      final hasAdminPermission = await isCurrentUserAdmin();
      if (!hasAdminPermission) {
        return false;
      }
      
      await _firestore.collection('users').doc(userId).update({
        'isAdmin': isAdmin,
      });
      
      return true;
    } catch (e) {
      debugPrint('Error updating user role: $e');
      return false;
    }
  }

  // Đặt vai trò của người dùng
  Future<bool> setUserRole(String userId, String role) async {
    try {
      // Kiểm tra xem người dùng hiện tại có phải là admin không
      final isAdmin = await isCurrentUserAdmin();
      
      if (!isAdmin) {
        throw Exception('Only administrators can change user roles');
      }
      
      await _firestore.collection('users').doc(userId).update({
        'role': role,
      });
      
      return true;
    } catch (e) {
      print('Error setting user role: $e');
      return false;
    }
  }
  
  // Lấy tất cả người dùng (chỉ dành cho admin)
  Future<List<UserModel>> getAllUsers() async {
    try {
      // Kiểm tra xem người dùng hiện tại có phải là admin không
      final isAdmin = await isCurrentUserAdmin();
      
      if (!isAdmin) {
        throw Exception('Only administrators can view all users');
      }
      
      final querySnapshot = await _firestore.collection('users').get();
      
      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  // Phương thức thêm địa điểm mới
  Future<void> addLocation(Map<String, dynamic> location) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Lấy danh sách địa điểm hiện tại
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final user = UserModel.fromMap(userDoc.data()!, userDoc.id);
      final currentLocations = List<Map<String, dynamic>>.from(user.locations);
      
      // Thêm ID cho địa điểm
      final newLocation = {
        ...location,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'createdAt': DateTime.now(),
      };
      
      // Thêm địa điểm mới và cập nhật Firestore
      currentLocations.add(newLocation);
      await _firestore.collection('users').doc(userId).update({
        'locations': currentLocations,
      });
      
      // Cập nhật user data
      await loadUserData();
      notifyListeners();
    } catch (e) {
      print('Error adding location: $e');
      throw e;
    }
  }
  
  // Phương thức cập nhật địa điểm
  Future<void> updateLocation(String locationId, Map<String, dynamic> updatedData) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Lấy danh sách địa điểm hiện tại
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final user = UserModel.fromMap(userDoc.data()!, userDoc.id);
      final currentLocations = List<Map<String, dynamic>>.from(user.locations);
      
      // Tìm và cập nhật địa điểm
      final locationIndex = currentLocations.indexWhere((loc) => loc['id'] == locationId);
      if (locationIndex >= 0) {
        currentLocations[locationIndex] = {
          ...currentLocations[locationIndex],
          ...updatedData,
          'updatedAt': DateTime.now(),
        };
        
        // Cập nhật Firestore
        await _firestore.collection('users').doc(userId).update({
          'locations': currentLocations,
        });
        
        // Cập nhật user data
        await loadUserData();
        notifyListeners();
      }
    } catch (e) {
      print('Error updating location: $e');
      throw e;
    }
  }
  
  // Phương thức xóa địa điểm
  Future<void> deleteLocation(String locationId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Lấy danh sách địa điểm hiện tại
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final user = UserModel.fromMap(userDoc.data()!, userDoc.id);
      final currentLocations = List<Map<String, dynamic>>.from(user.locations);
      
      // Lọc ra địa điểm cần xóa
      final updatedLocations = currentLocations.where((loc) => loc['id'] != locationId).toList();
      
      // Cập nhật Firestore
      await _firestore.collection('users').doc(userId).update({
        'locations': updatedLocations,
      });
      
      // Cập nhật user data
      await loadUserData();
      notifyListeners();
    } catch (e) {
      print('Error deleting location: $e');
      throw e;
    }
  }
  
  // Phương thức lấy tất cả địa điểm của người dùng
  List<Map<String, dynamic>> getUserLocations() {
    if (_currentUser == null) return [];
    return List<Map<String, dynamic>>.from(_currentUser!.locations);
  }

  // Phương thức tải dữ liệu người dùng hiện tại
  Future<void> loadUserData() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        _currentUser = null;
        return;
      }

      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        _currentUser = UserModel.fromMap(userDoc.data()!, userDoc.id);
      } else {
        _currentUser = null;
      }
      notifyListeners();
    } catch (e) {
      print('Error loading user data: $e');
      _currentUser = null;
    }
  }

  // Thêm phương thức mới để lấy thông tin người dùng từ cache
  UserModel? getUserFromCache(String userId) {
    // Kiểm tra nếu userId trùng với người dùng hiện tại
    if (_currentUser != null && _currentUser!.id == userId) {
      return _currentUser;
    }
    
    // Kiểm tra trong cache người dùng khác
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }
    
    return null;
  }

  // Thêm phương thức để lấy thông tin đăng nhập của admin
  // Lưu ý: Trong thực tế, bạn nên sử dụng cách an toàn hơn để lưu trữ thông tin đăng nhập 
  // như SharedPreferences có mã hóa hoặc Flutter Secure Storage
  Future<Map<String, String>> getAdminCredentials() async {
      // Đây chỉ là phương pháp tạm thời và không an toàn
      // Trong thực tế, hãy sử dụng tính năng như Custom Firebase Admin SDK
      // hoặc Firebase Functions để xử lý các nhiệm vụ admin
      
      // Kiểm tra xem người dùng hiện tại có phải là admin không
          return {
            'email': "admin@gmail.com",
            'password': '123456' // Mật khẩu giả định, KHÔNG ĐƯỢC SỬ DỤNG TRONG SẢN PHẨM THỰC TẾ!


  };
} }