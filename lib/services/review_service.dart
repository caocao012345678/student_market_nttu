import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/review.dart';

class ReviewService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // Add a new review
  Future<String> addReview(Review review) async {
    try {
      _isLoading = true;
      notifyListeners();

      final docRef = await _firestore.collection('reviews').add(review.toMap());

      // Update product rating
      await _updateProductRating(review.productId);

      _isLoading = false;
      notifyListeners();

      return docRef.id;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Get reviews by product id
  Stream<List<Review>> getReviewsByProductId(String productId) {
    return _firestore
        .collection('reviews')
        .where('productId', isEqualTo: productId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Add comment to review
  Future<void> addComment(String reviewId, Comment comment) async {
    try {
      _isLoading = true;
      notifyListeners();

      final reviewDoc = await _firestore.collection('reviews').doc(reviewId).get();
      if (!reviewDoc.exists) throw Exception('Review not found');

      final comments = List<Comment>.from(
        (reviewDoc.data()?['comments'] as List? ?? [])
            .map((x) => Comment.fromMap(x)),
      );

      comments.add(comment);

      await _firestore.collection('reviews').doc(reviewId).update({
        'comments': comments.map((x) => x.toMap()).toList(),
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Toggle like on review
  Future<void> toggleReviewLike(String reviewId, String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final reviewDoc = await _firestore.collection('reviews').doc(reviewId).get();
      if (!reviewDoc.exists) throw Exception('Review not found');

      final likes = List<String>.from(reviewDoc.data()?['likes'] ?? []);

      if (likes.contains(userId)) {
        likes.remove(userId);
      } else {
        likes.add(userId);
      }

      await _firestore.collection('reviews').doc(reviewId).update({
        'likes': likes,
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Toggle like on comment
  Future<void> toggleCommentLike(
      String reviewId, int commentIndex, String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final reviewDoc = await _firestore.collection('reviews').doc(reviewId).get();
      if (!reviewDoc.exists) throw Exception('Review not found');

      final comments = List<Comment>.from(
        (reviewDoc.data()?['comments'] as List? ?? [])
            .map((x) => Comment.fromMap(x)),
      );

      if (commentIndex >= comments.length) {
        throw Exception('Comment not found');
      }

      final likes = List<String>.from(comments[commentIndex].likes);

      if (likes.contains(userId)) {
        likes.remove(userId);
      } else {
        likes.add(userId);
      }

      comments[commentIndex] = Comment(
        userId: comments[commentIndex].userId,
        userEmail: comments[commentIndex].userEmail,
        text: comments[commentIndex].text,
        createdAt: comments[commentIndex].createdAt,
        likes: likes,
      );

      await _firestore.collection('reviews').doc(reviewId).update({
        'comments': comments.map((x) => x.toMap()).toList(),
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Update product rating
  Future<void> _updateProductRating(String productId) async {
    try {
      final reviews = await _firestore
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .get();

      if (reviews.docs.isEmpty) return;

      final totalRating = reviews.docs
          .map((doc) => (doc.data()['rating'] as num).toDouble())
          .fold(0.0, (prev, rating) => prev + rating);

      final averageRating = totalRating / reviews.docs.length;

      await _firestore.collection('products').doc(productId).update({
        'rating': averageRating,
        'reviewCount': reviews.docs.length,
      });
    } catch (e) {
      throw e;
    }
  }

  // Get user reviews
  Stream<List<Review>> getUserReviews(String userId) {
    return _firestore
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Delete review
  Future<void> deleteReview(String reviewId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final reviewDoc = await _firestore.collection('reviews').doc(reviewId).get();
      if (!reviewDoc.exists) throw Exception('Review not found');

      final productId = reviewDoc.data()?['productId'] as String;

      await _firestore.collection('reviews').doc(reviewId).delete();

      // Update product rating
      await _updateProductRating(productId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }
} 