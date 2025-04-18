import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_market_nttu/services/gemini_service.dart';
import 'package:student_market_nttu/services/app_layout_service.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

class RAGService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GeminiService _geminiService;
  AppLayoutService? _appLayoutService;
  
  // Lưu trữ kết quả tìm kiếm tạm thời
  List<Map<String, dynamic>> _retrievedDocuments = [];
  bool _isSearching = false;
  String _searchError = '';
  
  // Thêm cờ để theo dõi trạng thái dispose
  bool _disposed = false;
  
  // Cờ để ngăn chặn việc xử lý truy vấn trùng lặp
  bool _isProcessingQuery = false;
  String _lastProcessedQuery = '';
  
  // Thiết lập tham số tìm kiếm
  final double _similarityThreshold = 0.5;  // Ngưỡng điểm giống nhau tối thiểu
  final int _maxResults = 3;                // Số kết quả tối đa trả về cho mỗi loại
  
  // Getter
  List<Map<String, dynamic>> get retrievedDocuments => _retrievedDocuments;
  bool get isSearching => _isSearching;
  String get searchError => _searchError;
  bool get isProcessingQuery => _isProcessingQuery;
  int get retrievedDocsCount => _retrievedDocuments.length;

  // Cấu trúc constructor đơn giản
  RAGService(this._geminiService);

  // Thêm phương thức để cập nhật AppLayoutService
  void setAppLayoutService(AppLayoutService layoutService) {
    _appLayoutService = layoutService;
  }

  // Ghi đè phương thức notifyListeners để kiểm tra trạng thái dispose
  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  // Ghi đè phương thức dispose
  @override
  void dispose() {
    _disposed = true;
    _isProcessingQuery = false;
    super.dispose();
  }

  // Phương thức cập nhật state an toàn
  void _safeSetState({
    List<Map<String, dynamic>>? documents,
    bool? searching,
    String? error,
  }) {
    if (_disposed) return;
    
    if (documents != null) _retrievedDocuments = documents;
    if (searching != null) _isSearching = searching;
    if (error != null) _searchError = error;
    
    notifyListeners();
  }

  /// Tính điểm tương đồng giữa hai chuỗi văn bản
  /// Sử dụng thuật toán Cosine Similarity đơn giản
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

  /// Tìm kiếm và truy xuất dữ liệu từ Firebase
  Future<List<Map<String, dynamic>>> retrieveRelevantData(String query) async {
    if (_disposed) return [];
    
    // Không đặt _isProcessingQuery = true ở đây, để tránh xung đột với generateRAGResponse
    debugPrint('Thực hiện tìm kiếm dữ liệu cho: $query');
    
    try {
      _safeSetState(
        searching: true,
        error: '',
        documents: [],
      );
      
      // Phân tích truy vấn để xác định loại thông tin cần tìm
      final queryType = _analyzeQueryType(query);
      
      List<Map<String, dynamic>> results = [];
      
      // Tìm kiếm dựa vào loại truy vấn
      switch (queryType) {
        case QueryType.product:
          results = await _searchProducts(query);
          break;
        case QueryType.category:
          results = await _searchCategories(query);
          break;
        case QueryType.appUsage:
          results = await _searchAppInstructions(query);
          // Thêm thông tin từ AppLayoutService
          results.addAll(await _searchAppLayout(query));
          break;
        case QueryType.general:
          // Kết hợp tìm kiếm từ tất cả các nguồn
          final products = await _searchProducts(query);
          final categories = await _searchCategories(query);
          final instructions = await _searchAppInstructions(query);
          final layoutInfo = await _searchAppLayout(query);
          results = [...products, ...categories, ...instructions, ...layoutInfo];
          break;
      }
      
      if (_disposed) return [];
      
      // Lọc kết quả dựa trên ngưỡng similarity
      results = results.where((doc) => 
          doc['similarityScore'] != null && 
          (doc['similarityScore'] as double) >= _similarityThreshold
      ).toList();
      
      // Giới hạn tổng số kết quả
      if (results.length > _maxResults * 3) {
        results = results.take(_maxResults * 3).toList();
      }
      
      _safeSetState(
        documents: results,
        searching: false,
      );
      return results;
    } catch (e) {
      if (_disposed) return [];
      
      final errorMsg = 'Lỗi khi tìm kiếm: $e';
      debugPrint('RAG Retrieval Error: $errorMsg');
      
      _safeSetState(
        error: errorMsg,
        searching: false,
      );
      return [];
    }
  }

  /// Tìm kiếm thông tin trong AppLayoutService
  Future<List<Map<String, dynamic>>> _searchAppLayout(String query) async {
    try {
      if (_appLayoutService == null) return [];
      
      List<Map<String, dynamic>> results = [];
      
      // Phân tích query để xác định nên tìm màn hình hay chức năng
      final lowerQuery = query.toLowerCase();
      
      // Các từ khoá liên quan đến màn hình
      final isScreenQuery = lowerQuery.contains('màn hình') || 
                            lowerQuery.contains('giao diện') || 
                            lowerQuery.contains('trang');
                            
      // Các từ khoá liên quan đến chức năng
      final isFeatureQuery = lowerQuery.contains('chức năng') || 
                             lowerQuery.contains('tính năng') || 
                             lowerQuery.contains('làm thế nào') ||
                             lowerQuery.contains('cách');
                             
      // Tìm kiếm qua danh sách màn hình
      if (isScreenQuery) {
        for (var screen in _appLayoutService!.appScreens) {
          final screenName = (screen['name'] ?? '').toString().toLowerCase();
          final screenDesc = (screen['description'] ?? '').toString().toLowerCase();
          
          // Tính điểm tương đồng sử dụng cosine similarity
          final nameSimilarity = _calculateSimilarity(query, screenName) * 3;  // Đánh trọng số cao cho tên
          final descSimilarity = _calculateSimilarity(query, screenDesc);
          
          final totalSimilarity = nameSimilarity + descSimilarity;
          
          if (totalSimilarity >= _similarityThreshold) {
            // Tạo hướng dẫn sử dụng cho màn hình này
            final guide = _appLayoutService!.generateUsageGuideForScreen(screen['id']);
            
            results.add({
              'id': 'screen_${screen['id']}',
              'type': 'app_layout',
              'subtype': 'screen',
              'data': {
                ...screen,
                'usage_guide': guide
              },
              'similarityScore': totalSimilarity,
              'relevanceScore': (totalSimilarity * 10).round() // Giữ lại để tương thích ngược
            });
          }
        }
      }
      
      // Tìm kiếm qua danh sách chức năng
      if (isFeatureQuery) {
        for (var feature in _appLayoutService!.appFeatures) {
          final featureName = (feature['name'] ?? '').toString().toLowerCase();
          final featureDesc = (feature['description'] ?? '').toString().toLowerCase();
          final featureUsage = (feature['usage'] ?? '').toString().toLowerCase();
          
          // Tính điểm tương đồng
          final nameSimilarity = _calculateSimilarity(query, featureName) * 3;
          final descSimilarity = _calculateSimilarity(query, featureDesc);
          final usageSimilarity = _calculateSimilarity(query, featureUsage) * 2;
          
          final totalSimilarity = nameSimilarity + descSimilarity + usageSimilarity;
          
          if (totalSimilarity >= _similarityThreshold) {
            // Tạo hướng dẫn sử dụng cho chức năng này
            final guide = _appLayoutService!.generateUsageGuideForFeature(feature['id']);
            
            results.add({
              'id': 'feature_${feature['id']}',
              'type': 'app_layout',
              'subtype': 'feature',
              'data': {
                ...feature,
                'usage_guide': guide
              },
              'similarityScore': totalSimilarity,
              'relevanceScore': (totalSimilarity * 10).round()
            });
          }
        }
      }
      
      // Nếu là truy vấn chung về ứng dụng
      if (lowerQuery.contains('ứng dụng') || lowerQuery.contains('app')) {
        final overview = _appLayoutService!.generateAppOverview();
        
        results.add({
          'id': 'app_overview',
          'type': 'app_layout',
          'subtype': 'overview',
          'data': {
            'name': 'Tổng quan ứng dụng',
            'description': 'Thông tin tổng quan về Student Market NTTU',
            'content': overview
          },
          'similarityScore': 0.8, // Đánh giá cao cho tổng quan khi có từ khoá "ứng dụng"
          'relevanceScore': 8
        });
      }
      
      // Sắp xếp theo điểm tương đồng giảm dần
      results.sort((a, b) => (b['similarityScore'] as double).compareTo(a['similarityScore'] as double));
      
      // Giới hạn số lượng kết quả
      return results.take(_maxResults).toList();
    } catch (e) {
      debugPrint('Error searching app layout data: $e');
      return [];
    }
  }

  /// Phân tích truy vấn để xác định loại thông tin cần tìm
  QueryType _analyzeQueryType(String query) {
    query = query.toLowerCase();
    
    // Kiểm tra truy vấn liên quan đến sản phẩm
    if (query.contains('sản phẩm') || 
        query.contains('mua') || 
        query.contains('bán') || 
        query.contains('giá') ||
        query.contains('hàng')) {
      return QueryType.product;
    }
    
    // Kiểm tra truy vấn liên quan đến danh mục
    else if (query.contains('danh mục') || 
             query.contains('loại') || 
             query.contains('thể loại') ||
             query.contains('phân loại')) {
      return QueryType.category;
    }
    
    // Kiểm tra truy vấn liên quan đến cách sử dụng
    else if (query.contains('cách') || 
             query.contains('hướng dẫn') || 
             query.contains('sử dụng') ||
             query.contains('làm thế nào') ||
             query.contains('thao tác') ||
             query.contains('màn hình') ||
             query.contains('giao diện') ||
             query.contains('chức năng') ||
             query.contains('tính năng')) {
      return QueryType.appUsage;
    }
    
    // Trường hợp khác
    return QueryType.general;
  }

  /// Tìm kiếm sản phẩm
  Future<List<Map<String, dynamic>>> _searchProducts(String query) async {
    if (_disposed) return [];
    
    try {
      // Tìm kiếm trong collection products
      final productsSnapshot = await _firestore.collection('products').get();
      
      if (_disposed) return [];
      
      // Lọc kết quả phù hợp
      List<Map<String, dynamic>> results = [];
      
      for (var doc in productsSnapshot.docs) {
        final data = doc.data();
        final productName = (data['name'] ?? '').toString().toLowerCase();
        final productDescription = (data['description'] ?? '').toString().toLowerCase();
        
        // Tính điểm tương đồng sử dụng cosine similarity
        final nameSimilarity = _calculateSimilarity(query, productName) * 3;  // Nhân 3 để tăng trọng số cho tên
        final descSimilarity = _calculateSimilarity(query, productDescription);
        
        final totalSimilarity = nameSimilarity + descSimilarity;
        
        if (totalSimilarity >= _similarityThreshold) {
          results.add({
            'id': doc.id,
            'type': 'product',
            'data': data,
            'similarityScore': totalSimilarity,
            'relevanceScore': (totalSimilarity * 10).round() // Giữ lại để tương thích ngược
          });
        }
      }
      
      // Sắp xếp theo điểm tương đồng giảm dần
      results.sort((a, b) => (b['similarityScore'] as double).compareTo(a['similarityScore'] as double));
      
      // Giới hạn số lượng kết quả
      return results.take(_maxResults).toList();
    } catch (e) {
      debugPrint('Error searching products: $e');
      return [];
    }
  }

  /// Tìm kiếm danh mục
  Future<List<Map<String, dynamic>>> _searchCategories(String query) async {
    if (_disposed) return [];
    
    try {
      final categoriesSnapshot = await _firestore.collection('categories').get();
      
      if (_disposed) return [];
      
      List<Map<String, dynamic>> results = [];
      
      for (var doc in categoriesSnapshot.docs) {
        final data = doc.data();
        final categoryName = (data['name'] ?? '').toString().toLowerCase();
        final categoryDescription = (data['description'] ?? '').toString().toLowerCase();
        
        // Tính điểm tương đồng
        final nameSimilarity = _calculateSimilarity(query, categoryName) * 3;
        final descSimilarity = _calculateSimilarity(query, categoryDescription);
        
        final totalSimilarity = nameSimilarity + descSimilarity;
        
        if (totalSimilarity >= _similarityThreshold) {
          results.add({
            'id': doc.id,
            'type': 'category',
            'data': data,
            'similarityScore': totalSimilarity,
            'relevanceScore': (totalSimilarity * 10).round()
          });
        }
      }
      
      // Sắp xếp theo điểm tương đồng giảm dần
      results.sort((a, b) => (b['similarityScore'] as double).compareTo(a['similarityScore'] as double));
      
      // Giới hạn số lượng kết quả
      return results.take(_maxResults).toList();
    } catch (e) {
      debugPrint('Error searching categories: $e');
      return [];
    }
  }

  /// Tìm kiếm hướng dẫn sử dụng
  Future<List<Map<String, dynamic>>> _searchAppInstructions(String query) async {
    if (_disposed) return [];
    
    try {
      final instructionsSnapshot = await _firestore.collection('app_instructions').get();
      
      if (_disposed) return [];
      
      List<Map<String, dynamic>> results = [];
      
      for (var doc in instructionsSnapshot.docs) {
        final data = doc.data();
        final title = (data['title'] ?? '').toString().toLowerCase();
        final content = (data['content'] ?? '').toString().toLowerCase();
        
        // Tính điểm tương đồng
        final titleSimilarity = _calculateSimilarity(query, title) * 3;
        final contentSimilarity = _calculateSimilarity(query, content);
        
        final totalSimilarity = titleSimilarity + contentSimilarity;
        
        if (totalSimilarity >= _similarityThreshold) {
          results.add({
            'id': doc.id,
            'type': 'instruction',
            'data': data,
            'similarityScore': totalSimilarity,
            'relevanceScore': (totalSimilarity * 10).round()
          });
        }
      }
      
      // Sắp xếp theo điểm tương đồng giảm dần
      results.sort((a, b) => (b['similarityScore'] as double).compareTo(a['similarityScore'] as double));
      
      // Giới hạn số lượng kết quả
      return results.take(_maxResults).toList();
    } catch (e) {
      debugPrint('Error searching app instructions: $e');
      return [];
    }
  }

  /// Tạo câu trả lời với RAG
  Future<String> generateRAGResponse(String query) async {
    if (_disposed) {
      return 'Không thể xử lý yêu cầu vì service đã bị hủy. Vui lòng thử lại.';
    }
    
    // Kiểm tra xem đang xử lý query không và nếu là cùng một truy vấn
    if (_isProcessingQuery) {
      if (query == _lastProcessedQuery) {
        debugPrint('Đang xử lý truy vấn trùng lặp, bỏ qua: $query');
        return 'Đang xử lý câu hỏi này, vui lòng đợi...';
      } else {
        // Nếu đang xử lý một truy vấn khác, trả về thông báo rõ ràng hơn
        debugPrint('Đang xử lý truy vấn khác: $_lastProcessedQuery, bỏ qua truy vấn mới: $query');
        return 'Đang xử lý một câu hỏi khác, vui lòng đợi...';
      }
    }

    // Đánh dấu đang xử lý query và lưu lại query hiện tại
    _isProcessingQuery = true;
    _lastProcessedQuery = query;
    notifyListeners();

    try {
      debugPrint('Đang thực hiện tìm kiếm cho: $query');

      // Tìm kiếm các tài liệu liên quan
      final relevantDocs = await retrieveRelevantData(query);
      
      if (_disposed) {
        _isProcessingQuery = false;
        notifyListeners();
        return 'Không thể xử lý yêu cầu vì service đã bị hủy. Vui lòng thử lại.';
      }
      
      String response = '';
      
      // Nếu không có dữ liệu truy xuất được, sử dụng mô hình thông thường
      if (relevantDocs.isEmpty) {
        debugPrint('Không tìm thấy dữ liệu liên quan, chuyển sang sử dụng Gemini trực tiếp');
        // Truyền addToHistory=false để tránh thêm trùng lặp vào lịch sử
        response = await _geminiService.sendMessage(query, addToHistory: false);
      } else {
        // Tạo context từ dữ liệu đã truy xuất
        String context = _createContextFromDocs(relevantDocs);
        
        debugPrint('Tìm thấy ${relevantDocs.length} tài liệu có điểm tương đồng >= $_similarityThreshold');
        
        // Sử dụng sendMessageWithContext trực tiếp thay vì qua sendMessage
        response = await _geminiService.sendMessageWithContext(context, query);
      }
      
      _isProcessingQuery = false;
      notifyListeners();
      return response;
    } catch (e) {
      if (_disposed) {
        return 'Không thể xử lý yêu cầu vì service đã bị hủy. Vui lòng thử lại.';
      }
      
      final errorMsg = 'Lỗi tạo câu trả lời RAG: $e';
      _isProcessingQuery = false;
      notifyListeners();
      debugPrint('RAG Error: $errorMsg');
      return 'Lỗi xử lý yêu cầu: $e';
    }
  }

  /// Tạo ngữ cảnh từ các tài liệu đã truy xuất
  String _createContextFromDocs(List<Map<String, dynamic>> docs) {
    String context = '';
    
    for (var doc in docs) {
      String docType = doc['type'];
      Map<String, dynamic> data = doc['data'];
      
      switch (docType) {
        case 'product':
          context += 'Sản phẩm: ${data['name']}\n';
          context += 'Mô tả: ${data['description']}\n';
          context += 'Giá: ${data['price']}\n';
          context += 'Đăng bởi: ${data['postedBy']}\n\n';
          break;
        case 'category':
          context += 'Danh mục: ${data['name']}\n';
          context += 'Mô tả: ${data['description']}\n\n';
          break;
        case 'instruction':
          context += 'Hướng dẫn: ${data['title']}\n';
          context += 'Nội dung: ${data['content']}\n\n';
          break;
        case 'app_layout':
          String subtype = doc['subtype'];
          
          switch (subtype) {
            case 'screen':
              context += 'Thông tin màn hình: ${data['name']}\n';
              context += 'Mô tả: ${data['description']}\n';
              context += 'Hướng dẫn sử dụng:\n${data['usage_guide']}\n\n';
              break;
            case 'feature':
              context += 'Thông tin chức năng: ${data['name']}\n';
              context += 'Mô tả: ${data['description']}\n';
              context += 'Vị trí: ${data['location']}\n';
              context += 'Cách sử dụng: ${data['usage']}\n';
              if (data['usage_guide'] != null) {
                context += 'Hướng dẫn chi tiết:\n${data['usage_guide']}\n\n';
              }
              break;
            case 'overview':
              context += 'Tổng quan ứng dụng:\n';
              context += '${data['content']}\n\n';
              break;
          }
          break;
      }
    }
    
    return context;
  }
}

/// Enum xác định loại truy vấn
enum QueryType {
  product,    // Liên quan đến sản phẩm
  category,   // Liên quan đến danh mục
  appUsage,   // Liên quan đến cách sử dụng
  general,    // Truy vấn chung
} 