import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  bool _isLoading = false;

  AuthService() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _user = _auth.currentUser;
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isLoading => _isLoading;

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
        });

        // Send email verification
        await userCredential.user!.sendEmailVerification();
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
} 