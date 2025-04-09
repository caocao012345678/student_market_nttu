import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:student_market_nttu/services/user_service.dart';

class FavoritesService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  /// Checks if a product is in the user's favorites
  Future<bool> isProductFavorite(String productId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;

      final favoriteProducts = List<String>.from(userDoc.data()?['favoriteProducts'] ?? []);
      return favoriteProducts.contains(productId);
    } catch (e) {
      debugPrint('Error checking favorite status: $e');
      return false;
    }
  }

  /// Adds a product to user's favorites
  Future<void> addToFavorites(String productId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw Exception('User document not found');

      final favoriteProducts = List<String>.from(userDoc.data()?['favoriteProducts'] ?? []);
      
      if (!favoriteProducts.contains(productId)) {
        favoriteProducts.add(productId);
        
        await _firestore.collection('users').doc(user.uid).update({
          'favoriteProducts': favoriteProducts,
        });
        
        // Increment product's favorite count
        await _updateProductFavoriteCount(productId, true);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  /// Removes a product from user's favorites
  Future<void> removeFromFavorites(String productId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw Exception('User document not found');

      final favoriteProducts = List<String>.from(userDoc.data()?['favoriteProducts'] ?? []);
      
      if (favoriteProducts.contains(productId)) {
        favoriteProducts.remove(productId);
        
        await _firestore.collection('users').doc(user.uid).update({
          'favoriteProducts': favoriteProducts,
        });
        
        // Decrement product's favorite count
        await _updateProductFavoriteCount(productId, false);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  /// Toggle a product's favorite status
  Future<bool> toggleFavorite(String productId) async {
    try {
      final isFavorite = await isProductFavorite(productId);
      
      if (isFavorite) {
        await removeFromFavorites(productId);
        return false;
      } else {
        await addToFavorites(productId);
        return true;
      }
    } catch (e) {
      throw e;
    }
  }

  /// Get all favorite products for the current user
  Future<List<String>> getUserFavorites() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return [];

      return List<String>.from(userDoc.data()?['favoriteProducts'] ?? []);
    } catch (e) {
      debugPrint('Error getting user favorites: $e');
      return [];
    }
  }

  /// Update product's favorite count
  Future<void> _updateProductFavoriteCount(String productId, bool increment) async {
    try {
      final productDoc = await _firestore.collection('products').doc(productId).get();
      if (!productDoc.exists) return;

      int favoriteCount = productDoc.data()?['favoriteCount'] ?? 0;
      
      if (increment) {
        favoriteCount++;
      } else {
        favoriteCount = favoriteCount > 0 ? favoriteCount - 1 : 0;
      }

      await _firestore.collection('products').doc(productId).update({
        'favoriteCount': favoriteCount,
      });
    } catch (e) {
      debugPrint('Error updating product favorite count: $e');
    }
  }
} 