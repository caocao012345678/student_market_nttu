import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  bool _isLoading = false;
  bool _isAdmin = false;

  AuthService() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _user = _auth.currentUser;
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      _checkAdminStatus();
      notifyListeners();
    });
  }

  // Kiểm tra xem người dùng hiện tại có phải là admin hay không
  Future<void> _checkAdminStatus() async {
    _isAdmin = false; // Đặt giá trị mặc định
    
    try {
      if (_user != null) {
        final userDoc = await _firestore.collection('users').doc(_user!.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          // Kiểm tra cả hai trường để đảm bảo tính nhất quán
          _isAdmin = (userData?['role'] == 'admin' || userData?['isAdmin'] == true);
        }
      }
    } catch (e) {
      print('Error checking admin status: $e');
      _isAdmin = false;
    }
    
    notifyListeners();
  }

  User? get user => _user;
  bool get isLoading => _isLoading;

  // Kiểm tra xem người dùng hiện tại có phải là admin hay không
  bool get isUserAdmin => _isAdmin;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Sign up with email and password
  Future<void> signUp(String email, String password, String username) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Create user with email and password
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Create initial user document in Firestore
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'displayName': username,
          'createdAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
          'photoURL': '',
          'phoneNumber': '',
          'address': '',
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
          'studentId': null,
          'department': null,
          'studentYear': null,
          'major': null,
          'specialization': null,
          'interests': [],
          'preferredCategories': [],
          'completedSurvey': false,
          'isAdmin': false,
          'role': 'user',
        });

        // Send email verification
        await userCredential.user!.sendEmailVerification();
        
        // Kiểm tra trạng thái admin
        await _checkAdminStatus();
      }

      _isLoading = false;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Xử lý FirebaseAuthException
  String _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email này đã được sử dụng';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'operation-not-allowed':
        return 'Tài khoản email/mật khẩu chưa được kích hoạt';
      case 'weak-password':
        return 'Mật khẩu quá yếu';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa';
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này';
      case 'wrong-password':
        return 'Mật khẩu không chính xác';
      default:
        return e.message ?? 'Đã xảy ra lỗi không xác định';
    }
  }

  // Sign in with email and password
  Future<UserCredential> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = userCredential.user;
      _isLoading = false;
      notifyListeners();
      return userCredential;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _auth.sendPasswordResetEmail(email: email);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_user == null) throw Exception('No user logged in');
      await _user!.updatePassword(newPassword);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Reauthenticate user before changing password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Change password
      await user.updatePassword(newPassword);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Tạo tài khoản mới mà không tự động đăng nhập
  Future<void> createUserWithoutSignIn(String email, String password, String username) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Lưu lại thông tin người dùng hiện tại
      final currentUser = _auth.currentUser;
      
      // Create user with email and password
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Create initial user document in Firestore
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'displayName': username,
          'createdAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
          'photoURL': '',
          'phoneNumber': '',
          'address': '',
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
          'studentId': null,
          'department': null,
          'studentYear': null,
          'major': null,
          'specialization': null,
          'interests': [],
          'preferredCategories': [],
          'completedSurvey': false,
          'isAdmin': false,
          'role': 'user',
        });

        // Send email verification
        await userCredential.user!.sendEmailVerification();
      }

      // Đăng nhập lại người dùng ban đầu nếu có
      if (currentUser != null) {
        try {
          // Cách khác để đăng nhập lại (sử dụng token, không cần mật khẩu)
          // Đây chỉ là ví dụ, không phải cách thực tế làm việc với Firebase
          // Thực tế cần lưu thông tin đăng nhập của admin và đăng nhập lại
          // Nhưng code này chỉ để mô tả ý tưởng
          
          // Đáng lẽ phải dùng Custom Token hoặc phương pháp khác
          // await _auth.signInWithCustomToken(adminToken);
        } catch (e) {
          debugPrint('Error signing back in: $e');
        }
      }

      _isLoading = false;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
} 