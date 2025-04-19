import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_market_nttu/services/app_layout_service.dart';
import 'dart:math' as math;

class DbService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection references
  final CollectionReference _productsRef;
  final CollectionReference _categoriesRef;
  final CollectionReference _appInstructionsRef;
  final CollectionReference _uiComponentsRef;
  final CollectionReference _faqRef;
  
  DbService() : 
    _productsRef = FirebaseFirestore.instance.collection('products'),
    _categoriesRef = FirebaseFirestore.instance.collection('categories'),
    _appInstructionsRef = FirebaseFirestore.instance.collection('app_instructions'),
    _uiComponentsRef = FirebaseFirestore.instance.collection('ui_components'),
    _faqRef = FirebaseFirestore.instance.collection('faq');
  
  // ===== RAG DATA MANAGEMENT =====
  
  // Đồng bộ dữ liệu UI từ AppLayoutService
  Future<void> syncUIComponentsData(AppLayoutService appLayoutService) async {
    try {
      // Đồng bộ thông tin màn hình
      final batch = _firestore.batch();
      
      // 1. Đồng bộ thông tin màn hình
      for (var screen in appLayoutService.appScreens) {
        final docRef = _appInstructionsRef.doc('screen_${screen['id']}');
        batch.set(docRef, {
          'title': 'Màn hình: ${screen['name']}',
          'content': screen['description'],
          'screen_id': screen['id'],
          'type': 'screen',
          'usage_guide': appLayoutService.generateUsageGuideForScreen(screen['id']),
          'last_updated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      
      // 2. Đồng bộ thông tin tính năng
      for (var feature in appLayoutService.appFeatures) {
        final docRef = _appInstructionsRef.doc('feature_${feature['id']}');
        batch.set(docRef, {
          'title': 'Tính năng: ${feature['name']}',
          'content': '${feature['description']}. Vị trí: ${feature['location']}. Cách sử dụng: ${feature['usage']}',
          'feature_id': feature['id'],
          'screen_id': feature['screen_id'],
          'type': 'feature',
          'usage_guide': appLayoutService.generateUsageGuideForFeature(feature['id']),
          'last_updated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      
      // 3. Đồng bộ thông tin điều hướng
      for (var path in appLayoutService.navigationPaths) {
        final fromScreen = appLayoutService.appScreens.firstWhere(
          (s) => s['id'] == path['from_screen_id'],
          orElse: () => {'name': 'Unknown'},
        );
        
        final toScreen = appLayoutService.appScreens.firstWhere(
          (s) => s['id'] == path['to_screen_id'],
          orElse: () => {'name': 'Unknown'},
        );
        
        final docRef = _appInstructionsRef.doc('navigation_${path['from_screen_id']}_to_${path['to_screen_id']}');
        batch.set(docRef, {
          'title': 'Điều hướng: Từ ${fromScreen['name']} đến ${toScreen['name']}',
          'content': path['method'],
          'from_screen_id': path['from_screen_id'],
          'to_screen_id': path['to_screen_id'],
          'type': 'navigation',
          'last_updated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      
      // 4. Đồng bộ thông tin UI components
      for (var component in appLayoutService.uiComponents) {
        final docRef = _uiComponentsRef.doc(component['id']);
        batch.set(docRef, {
          'name': component['name'],
          'type': component['type'],
          'description': component['description'],
          'locations': component['locations'],
          'child_elements': component['child_elements'],
          'last_updated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      
      // 5. Tạo tổng quan ứng dụng
      final overviewDocRef = _appInstructionsRef.doc('app_overview');
      batch.set(overviewDocRef, {
        'title': 'Tổng quan ứng dụng Student Market NTTU',
        'content': appLayoutService.generateAppOverview(),
        'type': 'overview',
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Thực hiện batch
      await batch.commit();
      debugPrint('Đồng bộ thành công dữ liệu UI cho RAG');
      
    } catch (e) {
      debugPrint('Lỗi khi đồng bộ dữ liệu UI: $e');
      throw Exception('Không thể đồng bộ dữ liệu UI: $e');
    }
  }
  
  // Nâng cao metadata sản phẩm cho RAG
  Future<void> enhanceProductMetadata() async {
    try {
      // Lấy tất cả sản phẩm
      final products = await _productsRef.get();
      
      // Tạo batch để cập nhật hàng loạt
      final batch = _firestore.batch();
      
      // Duyệt qua từng sản phẩm
      for (var productDoc in products.docs) {
        final data = productDoc.data() as Map<String, dynamic>;
        
        // Trích xuất từ khóa và tạo văn bản tìm kiếm
        final List<String> keywords = _extractKeywords(
          '${data['name'] ?? ''} ${data['description'] ?? ''} ${data['category'] ?? ''}'
        );
        
        // Trích xuất điểm nổi bật
        final Map<String, dynamic> highlights = _extractProductHighlights(
          data['description'] ?? '', 
          data['category'] ?? ''
        );
        
        // Tạo văn bản tìm kiếm
        final String searchableText = [
          data['name'] ?? '',
          data['description'] ?? '',
          data['category'] ?? '',
          ...keywords,
        ].join(' ');
        
        // Tạo tóm tắt sản phẩm
        final String summary = _generateProductSummary(data);
        
        // Cập nhật sản phẩm
        batch.update(_productsRef.doc(productDoc.id), {
          'keywords': keywords,
          'highlights': highlights,
          'searchable_text': searchableText,
          'summary': summary,
          'rag_metadata': {
            'last_enhanced': FieldValue.serverTimestamp(),
            'has_enhanced_data': true,
          }
        });
      }
      
      // Thực hiện batch
      await batch.commit();
      debugPrint('Đã nâng cao metadata cho ${products.docs.length} sản phẩm');
      
    } catch (e) {
      debugPrint('Lỗi khi nâng cao metadata sản phẩm: $e');
      throw Exception('Không thể nâng cao metadata sản phẩm: $e');
    }
  }
  
  // Tạo và đồng bộ dữ liệu FAQ cho RAG
  Future<void> syncFAQData(List<Map<String, dynamic>> faqData) async {
    try {
      final batch = _firestore.batch();
      
      for (var faq in faqData) {
        final docRef = _faqRef.doc();
        batch.set(docRef, {
          'question': faq['question'],
          'answer': faq['answer'],
          'category': faq['category'],
          'tags': faq['tags'] ?? [],
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      debugPrint('Đã đồng bộ ${faqData.length} câu hỏi thường gặp');
      
    } catch (e) {
      debugPrint('Lỗi khi đồng bộ dữ liệu FAQ: $e');
      throw Exception('Không thể đồng bộ dữ liệu FAQ: $e');
    }
  }
  
  // Tạo mối quan hệ giữa danh mục sản phẩm
  Future<void> createCategoryRelations() async {
    try {
      final categories = await _categoriesRef.get();
      final batch = _firestore.batch();
      
      // Danh sách từ điển cho các danh mục
      final categoryDictionaries = {
        'điện tử': ['công nghệ', 'điện thoại', 'máy tính', 'laptop', 'tablet', 'phụ kiện'],
        'thời trang': ['quần áo', 'giày dép', 'túi xách', 'phụ kiện thời trang', 'đồng hồ'],
        'sách': ['giáo trình', 'sách tham khảo', 'tiểu thuyết', 'truyện', 'tài liệu học tập'],
        'đồ dùng': ['nội thất', 'đồ gia dụng', 'dụng cụ học tập', 'vật dụng sinh hoạt'],
        'thể thao': ['dụng cụ thể thao', 'quần áo thể thao', 'giày thể thao'],
      };
      
      for (var categoryDoc in categories.docs) {
        final data = categoryDoc.data() as Map<String, dynamic>;
        final categoryName = (data['name'] ?? '').toString().toLowerCase();
        
        // Tìm các danh mục liên quan
        List<String> relatedCategories = [];
        List<String> commonTerms = [];
        
        categoryDictionaries.forEach((key, terms) {
          if (categoryName.contains(key) || terms.any((term) => categoryName.contains(term))) {
            // Thêm các danh mục liên quan
            relatedCategories.add(key);
            // Thêm các thuật ngữ phổ biến
            commonTerms.addAll(terms);
          }
        });
        
        // Loại bỏ trùng lặp
        relatedCategories = relatedCategories.toSet().toList();
        commonTerms = commonTerms.toSet().toList();
        
        // Cập nhật danh mục
        batch.update(_categoriesRef.doc(categoryDoc.id), {
          'related_categories': relatedCategories,
          'common_terms': commonTerms,
          'searchable_text': '${data['name']} ${data['description']} ${commonTerms.join(' ')}',
          'rag_metadata': {
            'last_enhanced': FieldValue.serverTimestamp(),
            'has_enhanced_data': true,
          }
        });
      }
      
      await batch.commit();
      debugPrint('Đã tạo mối quan hệ cho ${categories.docs.length} danh mục');
      
    } catch (e) {
      debugPrint('Lỗi khi tạo mối quan hệ danh mục: $e');
      throw Exception('Không thể tạo mối quan hệ danh mục: $e');
    }
  }
  
  // ===== HELPER METHODS =====
  
  // Trích xuất từ khóa từ văn bản
  List<String> _extractKeywords(String text) {
    if (text.isEmpty) return [];
    
    // Danh sách stop words tiếng Việt
    final stopWords = ['và', 'hoặc', 'với', 'của', 'có', 'là', 'từ', 'đến', 'trong', 'ngoài', 'trên', 'dưới'];
    
    // Chuyển text thành chữ thường và tách thành các từ
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    
    // Lọc các từ quá ngắn và stopwords
    final filteredWords = words.where((word) => 
      word.length > 2 && !stopWords.contains(word)
    ).toList();
    
    // Loại bỏ trùng lặp
    return filteredWords.toSet().toList();
  }
  
  // Trích xuất điểm nổi bật của sản phẩm
  Map<String, dynamic> _extractProductHighlights(String description, String category) {
    final highlights = <String, dynamic>{};
    
    // Từ khóa đặc trưng cho từng loại sản phẩm
    final keywordPatterns = {
      'điện tử': [
        RegExp(r'ram\s+(\d+)\s*gb', caseSensitive: false),
        RegExp(r'bộ\s+nhớ\s+(\d+)\s*gb', caseSensitive: false),
        RegExp(r'pin\s+(\d+)\s*mah', caseSensitive: false),
        RegExp(r'camera\s+(\d+)\s*mp', caseSensitive: false),
      ],
      'sách': [
        RegExp(r'tác\s+giả\s*:?\s*([^,.]+)', caseSensitive: false),
        RegExp(r'nhà\s+xuất\s+bản\s*:?\s*([^,.]+)', caseSensitive: false),
        RegExp(r'năm\s+(\d{4})', caseSensitive: false),
      ],
      'thời trang': [
        RegExp(r'chất\s+liệu\s*:?\s*([^,.]+)', caseSensitive: false),
        RegExp(r'size\s*:?\s*([^,.]+)', caseSensitive: false),
        RegExp(r'màu\s*:?\s*([^,.]+)', caseSensitive: false),
      ],
    };
    
    // Xác định loại sản phẩm dựa vào danh mục
    String productType = 'other';
    for (var type in keywordPatterns.keys) {
      if (category.toLowerCase().contains(type)) {
        productType = type;
        break;
      }
    }
    
    // Tìm các điểm nổi bật dựa trên loại sản phẩm
    if (keywordPatterns.containsKey(productType)) {
      for (var pattern in keywordPatterns[productType]!) {
        final match = pattern.firstMatch(description);
        if (match != null && match.groupCount >= 1) {
          final key = pattern.pattern.split(r'\s+')[0];
          highlights[key] = match.group(1)?.trim();
        }
      }
    }
    
    // Tìm giá (nếu có trong mô tả)
    final pricePattern = RegExp(r'giá\s*:?\s*(\d{1,3}(?:[,.]\d{3})*)\s*(?:đ|vnd|k)', caseSensitive: false);
    final priceMatch = pricePattern.firstMatch(description);
    if (priceMatch != null && priceMatch.groupCount >= 1) {
      highlights['price_mentioned'] = priceMatch.group(1)?.trim();
    }
    
    // Tìm tình trạng sản phẩm
    final conditionPattern = RegExp(r'(mới|cũ|đã sử dụng|còn mới|like new|chưa sử dụng)', caseSensitive: false);
    final conditionMatch = conditionPattern.firstMatch(description);
    if (conditionMatch != null) {
      highlights['condition'] = conditionMatch.group(0)?.trim();
    }
    
    return highlights;
  }
  
  // Tạo tóm tắt sản phẩm
  String _generateProductSummary(Map<String, dynamic> productData) {
    final name = productData['name'] ?? 'Sản phẩm không tên';
    final price = productData['price'] ?? 'Chưa có giá';
    final category = productData['category'] ?? 'Chưa phân loại';
    final condition = (productData['condition'] ?? 'Không rõ tình trạng').toString();
    
    String summary = 'Sản phẩm: $name\n';
    summary += 'Giá: $price\n';
    summary += 'Danh mục: $category\n';
    summary += 'Tình trạng: $condition\n';
    
    // Thêm điểm nổi bật nếu có
    if (productData['highlights'] != null && productData['highlights'] is Map) {
      summary += 'Điểm nổi bật:\n';
      (productData['highlights'] as Map).forEach((key, value) {
        if (value != null) {
          summary += '- $key: $value\n';
        }
      });
    }
    
    return summary;
  }
  
  // ===== UTILITIES =====
  
  // Lấy danh sách FAQ
  Future<List<Map<String, dynamic>>> getFAQs() async {
    try {
      final snapshot = await _faqRef.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      debugPrint('Lỗi khi lấy FAQ: $e');
      return [];
    }
  }
  
  // Lấy thông tin tất cả các màn hình và tính năng
  Future<Map<String, dynamic>> getAppLayoutData() async {
    try {
      final snapshot = await _appInstructionsRef.get();
      
      final screens = <Map<String, dynamic>>[];
      final features = <Map<String, dynamic>>[];
      final navigations = <Map<String, dynamic>>[];
      Map<String, dynamic>? overview;
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final type = data['type'];
        
        switch (type) {
          case 'screen':
            screens.add({
              'id': doc.id,
              ...data,
            });
            break;
            
          case 'feature':
            features.add({
              'id': doc.id,
              ...data,
            });
            break;
            
          case 'navigation':
            navigations.add({
              'id': doc.id,
              ...data,
            });
            break;
            
          case 'overview':
            overview = {
              'id': doc.id,
              ...data,
            };
            break;
        }
      }
      
      return {
        'screens': screens,
        'features': features,
        'navigations': navigations,
        'overview': overview,
      };
      
    } catch (e) {
      debugPrint('Lỗi khi lấy dữ liệu bố cục ứng dụng: $e');
      return {
        'screens': [],
        'features': [],
        'navigations': [],
        'overview': null,
      };
    }
  }
} 