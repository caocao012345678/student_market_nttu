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
          final newUser = UserModel(
            id: userId,
            email: user.email ?? '',
            displayName: user.displayName ?? '',
            photoURL: user.photoURL ?? '',
            phoneNumber: user.phoneNumber ?? '',
            address: '',
            createdAt: DateTime.now(),
            lastActive: DateTime.now(),
          );
          await _firestore.collection('users').doc(userId).set(newUser.toMap());
          _currentUser = newUser;
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
  Future<DocumentSnapshot> getUserById(String userId) {
    return _firestore.collection('users').doc(userId).get();
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
} 