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
} 