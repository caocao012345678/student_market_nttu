import 'package:cloud_firestore/cloud_firestore.dart';

class KnowledgeDocument {
  final String id;
  final String title;
  final String content;
  final List<String> keywords;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int order; // Thứ tự hiển thị

  KnowledgeDocument({
    required this.id,
    required this.title,
    required this.content,
    this.keywords = const [],
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.order = 0,
  });

  factory KnowledgeDocument.fromMap(Map<String, dynamic> map, String id) {
    return KnowledgeDocument(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      keywords: List<String>.from(map['keywords'] ?? []),
      category: map['category'] ?? 'general',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'keywords': keywords,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'order': order,
    };
  }
}

class KnowledgeVector {
  final String id;
  final String documentId;
  final List<double> embedding;
  final String text;
  final String chunk; // Đoạn văn bản được lưu

  KnowledgeVector({
    required this.id,
    required this.documentId,
    required this.embedding,
    required this.text,
    required this.chunk,
  });

  factory KnowledgeVector.fromMap(Map<String, dynamic> map, String id) {
    return KnowledgeVector(
      id: id,
      documentId: map['documentId'] ?? '',
      embedding: List<double>.from(map['embedding'] ?? []),
      text: map['text'] ?? '',
      chunk: map['chunk'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'documentId': documentId,
      'embedding': embedding,
      'text': text,
      'chunk': chunk,
    };
  }
} 