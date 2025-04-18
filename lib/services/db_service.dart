import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class DbService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Phương thức tìm kiếm tài liệu tương tự
  Future<List<Map<String, dynamic>>> searchSimilarDocuments(String query) async {
    List<Map<String, dynamic>> results = [];
    
    try {
      // Tìm kiếm sản phẩm
      final productsSnapshot = await _firestore.collection('products').limit(10).get();
      for (var doc in productsSnapshot.docs) {
        final data = doc.data();
        final name = data['name'] ?? '';
        final description = data['description'] ?? '';
        
        // Tính điểm tương đồng đơn giản
        final similarity = _calculateSimilarity(query, '$name $description');
        
        if (similarity > 0.3) {
          results.add({
            'id': doc.id,
            'title': name,
            'content': description,
            'similarity': similarity,
            'type': 'product',
            'data': data,
            'similarityScore': similarity,
          });
        }
      }
      
      // Sắp xếp kết quả theo điểm giảm dần
      results.sort((a, b) => (b['similarity'] as double).compareTo(a['similarity'] as double));
      
      return results;
    } catch (e) {
      debugPrint('Error searching documents: $e');
      return [];
    }
  }
  
  // Phương thức tính điểm tương đồng
  double _calculateSimilarity(String text1, String text2) {
    if (text1.isEmpty || text2.isEmpty) return 0.0;
    
    // Chuyển chuỗi thành danh sách từ
    final words1 = text1.toLowerCase().split(RegExp(r'\s+'));
    final words2 = text2.toLowerCase().split(RegExp(r'\s+'));
    
    // Tạo từ điển tính tần suất
    final wordFreq1 = <String, int>{};
    final wordFreq2 = <String, int>{};
    
    for (final word in words1) {
      if (word.length > 2) { // Bỏ qua các từ quá ngắn
        wordFreq1[word] = (wordFreq1[word] ?? 0) + 1;
      }
    }
    
    for (final word in words2) {
      if (word.length > 2) {
        wordFreq2[word] = (wordFreq2[word] ?? 0) + 1;
      }
    }
    
    // Tạo tập hợp tất cả các từ
    final allWords = {...wordFreq1.keys, ...wordFreq2.keys};
    if (allWords.isEmpty) return 0.0;
    
    // Tính tích vô hướng
    double dotProduct = 0.0;
    for (final word in allWords) {
      dotProduct += (wordFreq1[word] ?? 0) * (wordFreq2[word] ?? 0);
    }
    
    // Tính độ dài vector
    double magnitude1 = 0.0;
    double magnitude2 = 0.0;
    
    for (final count in wordFreq1.values) {
      magnitude1 += count * count;
    }
    
    for (final count in wordFreq2.values) {
      magnitude2 += count * count;
    }
    
    magnitude1 = math.sqrt(magnitude1);
    magnitude2 = math.sqrt(magnitude2);
    
    // Tránh chia cho 0
    if (magnitude1 == 0 || magnitude2 == 0) return 0.0;
    
    // Tính cosine similarity
    return dotProduct / (magnitude1 * magnitude2);
  }
} 