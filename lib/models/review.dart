import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String productId;
  final String userId;
  final String userEmail;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final List<String>? images;
  final List<String> likes;
  final List<Comment> comments;

  Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userEmail,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.images,
    required this.likes,
    required this.comments,
  });

  factory Review.fromMap(Map<String, dynamic> map, String id) {
    return Review(
      id: id,
      productId: map['productId'] as String,
      userId: map['userId'] as String,
      userEmail: map['userEmail'] as String,
      rating: (map['rating'] as num).toDouble(),
      comment: map['comment'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      images: map['images'] != null ? List<String>.from(map['images']) : null,
      likes: List<String>.from(map['likes'] ?? []),
      comments: map['comments'] != null
          ? List<Comment>.from(
              (map['comments'] as List).map((x) => Comment.fromMap(x)))
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'userId': userId,
      'userEmail': userEmail,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'images': images,
      'likes': likes,
      'comments': comments.map((x) => x.toMap()).toList(),
    };
  }
}

class Comment {
  final String userId;
  final String userEmail;
  final String text;
  final DateTime createdAt;
  final List<String> likes;

  Comment({
    required this.userId,
    required this.userEmail,
    required this.text,
    required this.createdAt,
    required this.likes,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      userId: map['userId'] as String,
      userEmail: map['userEmail'] as String,
      text: map['text'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      likes: List<String>.from(map['likes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
    };
  }
} 