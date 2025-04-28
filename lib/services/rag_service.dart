import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_market_nttu/services/gemini_service.dart';
import 'package:student_market_nttu/services/app_layout_service.dart';
import 'package:student_market_nttu/services/app_features_service.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:glob/glob.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'dart:convert';
import '../services/product_service.dart';

/// Lớp chứa thông tin về một thực thể trong mã nguồn
class SourceCodeEntity {
  final String name;
  final String type; // 'class', 'method', 'function', etc.
  final String documentation;
  final String code;
  final int lineNumber;
  
  SourceCodeEntity({
    required this.name,
    required this.type,
    required this.documentation,
    required this.code,
    required this.lineNumber,
  });
}

/// Lớp chứa thông tin về một file mã nguồn
class SourceFileInfo {
  final String content;
  final List<SourceCodeEntity> entities;
  
  SourceFileInfo({
    required this.content,
    required this.entities,
  });
}

/// Enum xác định loại truy vấn
enum QueryType {
  product,    // Liên quan đến sản phẩm
  category,   // Liên quan đến danh mục
  appUsage,   // Liên quan đến cách sử dụng
  general,    // Truy vấn chung
  sourceCode, // Liên quan đến mã nguồn
  roadmap,    // Liên quan đến quy trình, hướng dẫn
  productInfo, // Thông tin chi tiết sản phẩm
  appLayout,   // Liên quan đến bố cục ứng dụng
  documentation // Liên quan đến tài liệu hướng dẫn
}

class RAGService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GeminiService _geminiService;
  AppLayoutService? _appLayoutService;
  AppFeaturesService? _appFeaturesService;
  
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

  // Thêm phương thức để cập nhật AppFeaturesService
  void setAppFeaturesService(AppFeaturesService featuresService) {
    _appFeaturesService = featuresService;
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

  /// Phân tích truy vấn để xác định loại thông tin cần tìm
  QueryType _analyzeQueryType(String query) {
    query = query.toLowerCase();
    
    // Nếu truy vấn chứa các từ liên quan đến sản phẩm cụ thể, ưu tiên trả về QueryType.product
    if (query.contains('có bán') || 
        query.contains('mua được') || 
        query.contains('giá bao nhiêu') || 
        query.contains('còn hàng') ||
        query.contains('sách') ||
        query.contains('điện thoại') ||
        query.contains('laptop') ||
        query.contains('quần áo') ||
        query.contains('giày dép')) {
      return QueryType.product;
    }
    
    // Từ khóa liên quan đến sản phẩm
    final productKeywords = [
      'sản phẩm', 'mua', 'bán', 'giá', 'hàng', 'đồ', 'thanh toán', 
      'đăng bán', 'đăng sản phẩm', 'đăng đồ', 'bán đồ', 'quản lý sản phẩm',
      'chỉnh sửa sản phẩm', 'xóa sản phẩm', 'sửa sản phẩm', 'sản phẩm của tôi',
      'đăng sản phẩm mới', 'bán hàng', 'có', 'cung cấp', 'kinh doanh'
    ];
    
    // Từ khóa liên quan đến danh mục
    final categoryKeywords = [
      'danh mục', 'loại', 'thể loại', 'phân loại', 'nhóm sản phẩm',
      'thể loại sản phẩm', 'các loại', 'phân nhóm'
    ];
    
    // Từ khóa liên quan đến cách sử dụng
    final appUsageKeywords = [
      'cách', 'hướng dẫn', 'sử dụng', 'làm thế nào', 'làm sao', 'thao tác',
      'màn hình', 'giao diện', 'chức năng', 'tính năng', 'hướng dẫn sử dụng',
      'cách dùng', 'thao tác', 'sử dụng', 'truy cập', 'đi đến', 'tìm đến'
    ];
    
    // Thêm từ khóa liên quan đến mã nguồn
    final sourceCodeKeywords = [
      'mã nguồn', 'code', 'source code', 'implementation', 'triển khai', 'cài đặt',
      'class', 'lớp', 'phương thức', 'method', 'function', 'hàm', 'biến', 'variable',
      'widget', 'component', 'thành phần', 'service', 'dịch vụ', 'model', 'mô hình',
      'file', 'tệp', 'package', 'library', 'thư viện', 'import', 'module', 'dependency',
      'flutter', 'dart', 'firebase', 'API', 'thuật toán', 'algorithm'
    ];
    
    // Từ khóa liên quan đến roadmap, quy trình
    final roadmapKeywords = [
      'roadmap', 'quy trình', 'các bước', 'bước', 'trình tự', 'thứ tự',
      'như thế nào', 'làm sao để', 'bắt đầu', 'hướng dẫn chi tiết',
      'từng bước', 'tiến hành', 'thực hiện'
    ];
    
    // Kiểm tra các mẫu câu hỏi về quy trình cụ thể
    final roadmapPatterns = [
      RegExp(r'(đăng|tạo|thêm).*?(sản phẩm|bài|đồ|hàng).*?(như thế nào|thế nào|ra sao|làm sao|bằng cách nào)'),
      RegExp(r'(làm sao|làm thế nào|cách).*?(để|mà).*?(đăng|tạo|thêm).*?(sản phẩm|bài|đồ|hàng)'),
      RegExp(r'(xem|tìm|kiểm tra).*?(sản phẩm của tôi|sản phẩm đã đăng|sản phẩm mình đã đăng|đồ đã bán).*?(ở đâu|như thế nào|thế nào)'),
      RegExp(r'(chỉnh sửa|sửa|cập nhật).*?(sản phẩm|bài|đồ|hàng).*?(như thế nào|ra sao|ở đâu)'),
      RegExp(r'(xóa|gỡ).*?(sản phẩm|bài|đồ|hàng).*?(như thế nào|ra sao|ở đâu|bằng cách nào)'),
      RegExp(r'(mua|thanh toán).*?(sản phẩm|bài|đồ|hàng).*?(như thế nào|ra sao|bằng cách nào|ở đâu)'),
      RegExp(r'(trò chuyện|chat|liên hệ).*?(với|tới).*?(người bán|người mua).*?(như thế nào|ra sao|bằng cách nào)'),
    ];
    
    // Đếm số từ khóa khớp cho mỗi loại
    int productMatches = 0;
    int categoryMatches = 0;
    int appUsageMatches = 0;
    int sourceCodeMatches = 0;
    int roadmapMatches = 0;
    
    // Kiểm tra từng từ khóa
    for (final keyword in productKeywords) {
      if (query.contains(keyword)) productMatches += 2; // Tăng trọng số cho sản phẩm
    }
    
    for (final keyword in categoryKeywords) {
      if (query.contains(keyword)) categoryMatches++;
    }
    
    for (final keyword in appUsageKeywords) {
      if (query.contains(keyword)) appUsageMatches++;
    }
    
    for (final keyword in sourceCodeKeywords) {
      if (query.contains(keyword)) sourceCodeMatches++;
    }
    
    for (final keyword in roadmapKeywords) {
      if (query.contains(keyword)) roadmapMatches++;
    }
    
    // Kiểm tra các mẫu câu về roadmap
    bool isRoadmapQuery = false;
    for (final pattern in roadmapPatterns) {
      if (pattern.hasMatch(query)) {
        isRoadmapQuery = true;
        roadmapMatches += 3; // Tăng điểm đáng kể cho truy vấn roadmap
        break;
      }
    }
    
    // Phân loại dựa trên số lượng từ khóa phù hợp
    if (isRoadmapQuery || (roadmapMatches > 0 && (
        query.contains('đăng bài như thế nào') || 
        query.contains('đăng sản phẩm như thế nào') ||
        query.contains('đăng bán như thế nào') ||
        query.contains('cách đăng sản phẩm') ||
        query.contains('làm sao để đăng') ||
        query.contains('sản phẩm của tôi ở đâu') ||
        query.contains('xem sản phẩm đã đăng')))) {
      return QueryType.roadmap;
    } else if (sourceCodeMatches > 0 && (
        query.contains('tìm trong mã') || 
        query.contains('tìm trong code') || 
        query.contains('tìm kiếm mã') ||
        query.contains('tìm kiếm code') ||
        query.contains('search code') ||
        query.contains('search source') ||
        query.contains('trong mã nguồn') ||
        query.contains('tìm hiểu code') ||
        query.contains('triển khai') && (query.contains('như thế nào') || query.contains('ra sao')))) {
      return QueryType.sourceCode;
    } else if (productMatches > categoryMatches && productMatches > appUsageMatches && productMatches > sourceCodeMatches && productMatches > roadmapMatches) {
      return QueryType.product;
    } else if (categoryMatches > productMatches && categoryMatches > appUsageMatches && categoryMatches > sourceCodeMatches && categoryMatches > roadmapMatches) {
      return QueryType.category;
    } else if (appUsageMatches > productMatches && appUsageMatches > categoryMatches && appUsageMatches > sourceCodeMatches && appUsageMatches > roadmapMatches) {
      return QueryType.appUsage;
    } else if (sourceCodeMatches > productMatches && sourceCodeMatches > categoryMatches && sourceCodeMatches > appUsageMatches && sourceCodeMatches > roadmapMatches) {
      return QueryType.sourceCode;
    } else {
      // Nếu không rõ ràng, ưu tiên trả về sản phẩm
      return QueryType.product;
    }
  }

  /// Tính điểm tương đồng giữa hai chuỗi văn bản
  /// Sử dụng thuật toán kết hợp giữa cosine similarity và n-gram matching
  double _calculateSimilarity(String text1, String text2) {
    if (text1.isEmpty || text2.isEmpty) return 0.0;
    
    // Chuẩn hóa và chuyển thành chữ thường
    final normalizedText1 = text1.toLowerCase().trim();
    final normalizedText2 = text2.toLowerCase().trim();
    
    // Matching chính xác - điểm cao nhất
    if (normalizedText1 == normalizedText2) {
      return 1.0;
    }
    
    // Kiểm tra nếu một chuỗi chứa chuỗi còn lại
    if (normalizedText1.contains(normalizedText2) || normalizedText2.contains(normalizedText1)) {
      final containmentScore = 0.8 + (0.2 * math.min(normalizedText1.length, normalizedText2.length) / 
                                     math.max(normalizedText1.length, normalizedText2.length));
      return containmentScore;
    }
    
    // Chuyển chuỗi thành danh sách từ
    final words1 = normalizedText1.split(RegExp(r'\s+'));
    final words2 = normalizedText2.split(RegExp(r'\s+'));
    
    // Tạo từ điển tính tần suất
    final wordFreq1 = <String, int>{};
    final wordFreq2 = <String, int>{};
    
    for (final word in words1) {
      if (word.length > 1) { // Bỏ qua các từ quá ngắn (chỉ 1 ký tự)
        wordFreq1[word] = (wordFreq1[word] ?? 0) + 1;
      }
    }
    
    for (final word in words2) {
      if (word.length > 1) {
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
    final cosineSimilarity = dotProduct / (magnitude1 * magnitude2);
    
    // Tính điểm Jaccard (dựa trên các từ chung)
    final intersection = wordFreq1.keys.where((word) => wordFreq2.containsKey(word)).length;
    final union = allWords.length;
    final jaccardSimilarity = intersection / union;
    
    // Tính điểm cho từng cụm từ chung (bi-gram, tri-gram)
    double nGramSimilarity = 0.0;
    
    // Kiểm tra bi-gram (cụm 2 từ)
    if (words1.length >= 2 && words2.length >= 2) {
      final bigrams1 = _createNGrams(words1, 2);
      final bigrams2 = _createNGrams(words2, 2);
      
      final bigramIntersection = bigrams1.where((bg) => bigrams2.contains(bg)).length;
      final bigramUnion = bigrams1.length + bigrams2.length - bigramIntersection;
      
      if (bigramUnion > 0) {
        nGramSimilarity += (bigramIntersection / bigramUnion) * 0.3; // Trọng số 0.3 cho bi-gram
      }
    }
    
    // Kiểm tra tri-gram (cụm 3 từ)
    if (words1.length >= 3 && words2.length >= 3) {
      final trigrams1 = _createNGrams(words1, 3);
      final trigrams2 = _createNGrams(words2, 3);
      
      final trigramIntersection = trigrams1.where((tg) => trigrams2.contains(tg)).length;
      final trigramUnion = trigrams1.length + trigrams2.length - trigramIntersection;
      
      if (trigramUnion > 0) {
        nGramSimilarity += (trigramIntersection / trigramUnion) * 0.4; // Trọng số 0.4 cho tri-gram
      }
    }
    
    // Kết hợp các điểm số với trọng số
    // Cosine similarity có trọng số cao nhất
    return (cosineSimilarity * 0.6) + (jaccardSimilarity * 0.2) + (nGramSimilarity * 0.2);
  }
  
  /// Tạo n-gram từ danh sách từ
  List<String> _createNGrams(List<String> words, int n) {
    if (words.length < n) return [];
    
    final List<String> ngrams = [];
    for (int i = 0; i <= words.length - n; i++) {
      ngrams.add(words.sublist(i, i + n).join(' '));
    }
    
    return ngrams;
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
          results = await _searchAppUsage(query);
          break;
        case QueryType.sourceCode:
          results = await _searchSourceCode(query);
          break;
        case QueryType.roadmap:
          results = await _createRoadmapFromCode(query);
          break;
        case QueryType.productInfo:
          results = await _searchProductDetails(query);
          break;
        case QueryType.general:
        default:
          // Tìm kiếm chung trong tất cả nguồn
          results = await _searchGeneral(query);
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

  /// Tìm kiếm thông tin chi tiết của sản phẩm
  Future<List<Map<String, dynamic>>> _searchProductDetails(String query) async {
    try {
      final ProductService productService = ProductService();
      List<Map<String, dynamic>> results = [];
      
      // Tìm sản phẩm dựa trên từ khóa tìm kiếm
      final products = await productService.searchProductsByKeyword(query);
      
      for (var product in products) {
        Map<String, dynamic> productData = {
          'title': product.title,
          'price': product.price,
          'description': product.description,
          'category': product.category,
          'condition': product.condition,
          'seller': product.sellerName,
          'images': product.images.isNotEmpty ? product.images : null,
          'type': 'product_info',
          'id': product.id,
          'relevance': _calculateRelevance(query, '${product.title} ${product.description}')
        };
        
        results.add(productData);
      }
      
      // Sắp xếp kết quả theo độ liên quan
      results.sort((a, b) => (b['relevance'] as double).compareTo(a['relevance'] as double));
      
      return results;
    } catch (e) {
      debugPrint('Lỗi khi tìm kiếm thông tin chi tiết sản phẩm: $e');
      return [];
    }
  }

  /// Tìm kiếm thông tin sản phẩm
  Future<List<Map<String, dynamic>>> _searchProducts(String query) async {
    try {
      final productService = ProductService();
      List<Map<String, dynamic>> results = [];
      
      // Lấy danh sách sản phẩm phù hợp với từ khóa tìm kiếm
      final products = await productService.searchProductsByKeyword(query);
      
      for (var product in products) {
        // Tính điểm tương đồng
        final double similarityScore = _calculateSimilarity(query, product.title + ' ' + product.description);
        
        Map<String, dynamic> productData = {
          'title': product.title,
          'price': product.price,
          'description': product.description,
          'images': product.images.isNotEmpty ? product.images : null,
          'type': 'product',
          'id': product.id,
          'similarityScore': similarityScore
        };
        
        results.add(productData);
      }
      
      // Sắp xếp kết quả theo điểm tương đồng
      results.sort((a, b) => (b['similarityScore'] as double).compareTo(a['similarityScore'] as double));
      
      return results;
    } catch (e) {
      debugPrint('Lỗi khi tìm kiếm sản phẩm: $e');
      return [];
    }
  }

  /// Tìm kiếm thông tin danh mục
  Future<List<Map<String, dynamic>>> _searchCategories(String query) async {
    try {
      // Danh sách danh mục cứng
      final categories = [
        {'id': 'electronics', 'name': 'Điện tử', 'description': 'Sản phẩm điện tử, công nghệ'},
        {'id': 'clothing', 'name': 'Thời trang', 'description': 'Quần áo, phụ kiện thời trang'},
        {'id': 'books', 'name': 'Sách', 'description': 'Sách giáo trình, tài liệu học tập'},
        {'id': 'furniture', 'name': 'Nội thất', 'description': 'Đồ dùng, nội thất phòng trọ, ký túc xá'},
        {'id': 'sports', 'name': 'Thể thao', 'description': 'Dụng cụ thể thao, đồ tập'},
        {'id': 'vehicles', 'name': 'Phương tiện', 'description': 'Xe đạp, xe máy, phụ tùng'},
        {'id': 'services', 'name': 'Dịch vụ', 'description': 'Dịch vụ sinh viên, gia sư, sửa chữa'},
      ];
      
      List<Map<String, dynamic>> results = [];
      
      for (var category in categories) {
        final name = category['name'] as String;
        final description = category['description'] as String;
        
        // Tính điểm tương đồng
        final double similarityScore = _calculateSimilarity(
          query, 
          '${name} ${description}'
        );
        
        if (similarityScore >= _similarityThreshold) {
          results.add({
            'title': category['name'],
            'description': category['description'],
            'id': category['id'],
            'type': 'category',
            'similarityScore': similarityScore
          });
        }
      }
      
      // Sắp xếp kết quả theo điểm tương đồng
      results.sort((a, b) => (b['similarityScore'] as double).compareTo(a['similarityScore'] as double));
      
      return results;
    } catch (e) {
      debugPrint('Lỗi khi tìm kiếm danh mục: $e');
      return [];
    }
  }

  /// Tìm kiếm hướng dẫn sử dụng
  Future<List<Map<String, dynamic>>> _searchAppUsage(String query) async {
    try {
      // Danh sách hướng dẫn sử dụng cứng
      final appUsageGuides = [
        {
          'title': 'Cách đăng sản phẩm',
          'content': 'Bước 1: Đăng nhập vào tài khoản\nBước 2: Chọn "Đăng sản phẩm" từ menu\nBước 3: Điền thông tin sản phẩm\nBước 4: Tải lên hình ảnh\nBước 5: Xác nhận và đăng'
        },
        {
          'title': 'Cách tìm kiếm sản phẩm',
          'content': 'Bạn có thể tìm kiếm sản phẩm bằng cách nhập từ khóa vào ô tìm kiếm, hoặc lọc theo danh mục, giá cả, và các tiêu chí khác.'
        },
        {
          'title': 'Làm thế nào để liên hệ người bán',
          'content': 'Sau khi tìm thấy sản phẩm quan tâm, bạn có thể nhấn vào nút "Nhắn tin" để bắt đầu cuộc trò chuyện với người bán.'
        },
        {
          'title': 'Hướng dẫn thanh toán',
          'content': 'Student Market NTTU hỗ trợ nhiều phương thức thanh toán: Thanh toán khi nhận hàng (COD), chuyển khoản ngân hàng, ví điện tử.'
        },
        {
          'title': 'Cách theo dõi đơn hàng',
          'content': 'Sau khi mua hàng, bạn có thể theo dõi đơn hàng bằng cách vào phần "Đơn hàng của tôi" trong trang cá nhân.'
        },
      ];
      
      List<Map<String, dynamic>> results = [];
      
      for (var guide in appUsageGuides) {
        final title = guide['title'] as String;
        final content = guide['content'] as String;
        
        // Tính điểm tương đồng
        final double similarityScore = _calculateSimilarity(
          query, 
          '${title} ${content}'
        );
        
        if (similarityScore >= _similarityThreshold) {
          results.add({
            'title': title,
            'description': content,
            'type': 'appUsage',
            'similarityScore': similarityScore
          });
        }
      }
      
      // Sắp xếp kết quả theo điểm tương đồng
      results.sort((a, b) => (b['similarityScore'] as double).compareTo(a['similarityScore'] as double));
      
      return results;
    } catch (e) {
      debugPrint('Lỗi khi tìm kiếm hướng dẫn sử dụng: $e');
      return [];
    }
  }

  /// Tìm kiếm trong mã nguồn
  Future<List<Map<String, dynamic>>> _searchSourceCode(String query) async {
    try {
      // Trong thực tế, phương thức này sẽ phân tích mã nguồn
      // Đây là phiên bản giả lập đơn giản
      List<Map<String, dynamic>> results = [];
      
      // Danh sách mã nguồn mẫu
      final sampleCodeSnippets = [
        {
          'file': 'lib/screens/product_detail_screen.dart',
          'class': 'ProductDetailScreen',
          'method': 'build',
          'code': 'Widget build(BuildContext context) { ... }',
          'description': 'Phương thức xây dựng giao diện chi tiết sản phẩm'
        },
        {
          'file': 'lib/services/product_service.dart',
          'class': 'ProductService',
          'method': 'getProductById',
          'code': 'Future<Product> getProductById(String id) { ... }',
          'description': 'Phương thức lấy thông tin sản phẩm theo ID'
        },
        {
          'file': 'lib/services/auth_service.dart',
          'class': 'AuthService',
          'method': 'signIn',
          'code': 'Future<User?> signIn(String email, String password) { ... }',
          'description': 'Phương thức đăng nhập người dùng'
        },
      ];
      
      for (var snippet in sampleCodeSnippets) {
        final file = snippet['file'] as String;
        final className = snippet['class'] as String;
        final method = snippet['method'] as String;
        final description = snippet['description'] as String;
        
        // Tạo một chuỗi tìm kiếm từ thông tin snippet
        final searchableText = '$file $className $method $description';
        
        // Tính điểm tương đồng
        final double similarityScore = _calculateSimilarity(query, searchableText);
        
        if (similarityScore >= _similarityThreshold) {
          results.add({
            'title': '$className.$method',
            'description': description,
            'file': file,
            'code': snippet['code'],
            'type': 'sourceCode',
            'similarityScore': similarityScore
          });
        }
      }
      
      // Sắp xếp kết quả theo điểm tương đồng
      results.sort((a, b) => (b['similarityScore'] as double).compareTo(a['similarityScore'] as double));
      
      return results;
    } catch (e) {
      debugPrint('Lỗi khi tìm kiếm trong mã nguồn: $e');
      return [];
    }
  }

  /// Tạo quy trình từ mã nguồn
  Future<List<Map<String, dynamic>>> _createRoadmapFromCode(String query) async {
    try {
      // Trong thực tế, phương thức này sẽ phân tích mã nguồn để tạo quy trình
      // Đây là phiên bản giả lập đơn giản
      
      // Danh sách quy trình mẫu
      final sampleRoadmaps = [
        {
          'title': 'Quy trình đăng sản phẩm',
          'steps': [
            '1. Đăng nhập vào ứng dụng',
            '2. Chọn "Tạo sản phẩm mới" từ menu',
            '3. Điền thông tin sản phẩm: tên, mô tả, giá, danh mục',
            '4. Tải lên hình ảnh sản phẩm',
            '5. Kiểm tra và xác nhận thông tin',
            '6. Nhấn "Đăng sản phẩm"'
          ]
        },
        {
          'title': 'Quy trình mua hàng',
          'steps': [
            '1. Tìm kiếm sản phẩm cần mua',
            '2. Xem chi tiết sản phẩm',
            '3. Chọn "Mua ngay" hoặc "Thêm vào giỏ hàng"',
            '4. Nhập thông tin giao hàng',
            '5. Chọn phương thức thanh toán',
            '6. Xác nhận đơn hàng'
          ]
        },
        {
          'title': 'Quy trình đánh giá sản phẩm',
          'steps': [
            '1. Đăng nhập vào ứng dụng',
            '2. Tìm sản phẩm đã mua trong "Đơn hàng của tôi"',
            '3. Chọn "Đánh giá sản phẩm"',
            '4. Cho điểm sản phẩm (1-5 sao)',
            '5. Viết nhận xét',
            '6. Gửi đánh giá'
          ]
        }
      ];
      
      List<Map<String, dynamic>> results = [];
      
      for (var roadmap in sampleRoadmaps) {
        final title = roadmap['title'] as String;
        final steps = roadmap['steps'] as List;
        
        // Tạo một chuỗi tìm kiếm từ thông tin roadmap
        final stepsText = steps.join(' ');
        final searchableText = '$title $stepsText';
        
        // Tính điểm tương đồng
        final double similarityScore = _calculateSimilarity(query, searchableText);
        
        if (similarityScore >= _similarityThreshold) {
          results.add({
            'title': title,
            'description': steps.join('\n'),
            'type': 'roadmap',
            'similarityScore': similarityScore
          });
        }
      }
      
      // Sắp xếp kết quả theo điểm tương đồng
      results.sort((a, b) => (b['similarityScore'] as double).compareTo(a['similarityScore'] as double));
      
      return results;
    } catch (e) {
      debugPrint('Lỗi khi tạo quy trình từ mã nguồn: $e');
      return [];
    }
  }

  /// Tìm kiếm quy trình
  Future<List<Map<String, dynamic>>> _searchRoadmap(String query) async {
    // Cơ bản giống với _createRoadmapFromCode nhưng có thể được tối ưu cho việc tìm kiếm quy trình
    return _createRoadmapFromCode(query);
  }

  /// Tính điểm liên quan giữa query và text
  double _calculateRelevance(String query, String text) {
    // Có thể sử dụng thuật toán tương tự như _calculateSimilarity
    return _calculateSimilarity(query, text);
  }

  /// Tìm kiếm tổng hợp trên tất cả các nguồn
  Future<List<Map<String, dynamic>>> _searchGeneral(String query) async {
    try {
      // Lấy kết quả từ tất cả các nguồn
      final products = await _searchProducts(query);
      final categories = await _searchCategories(query);
      final appUsage = await _searchAppUsage(query);
      
      // Thêm tìm kiếm trong tính năng ứng dụng
      List<Map<String, dynamic>> appFeatures = [];
      if (_appFeaturesService != null) {
        try {
          // Lấy danh sách tính năng từ AppFeaturesService
          final features = _appFeaturesService!.existingFeatures;
          
          for (var feature in features) {
            // Tạo văn bản để tìm kiếm
            final String title = feature['name'] ?? '';
            final String description = feature['description'] ?? '';
            final String guide = feature['guide'] ?? '';
            
            final searchableText = '$title $description $guide';
            
            // Tính điểm tương đồng
            final double similarityScore = _calculateSimilarity(query, searchableText);
            
            if (similarityScore >= _similarityThreshold) {
              appFeatures.add({
                'title': title,
                'description': description,
                'id': feature['id'],
                'type': 'app_feature',
                'similarityScore': similarityScore,
                'guide': guide
              });
            }
          }
        } catch (e) {
          debugPrint('Lỗi khi tìm kiếm trong tính năng ứng dụng: $e');
        }
      }
      
      // Kết hợp tất cả các kết quả
      final List<Map<String, dynamic>> combinedResults = [
        ...products,
        ...categories,
        ...appUsage,
        ...appFeatures,
      ];
      
      // Sắp xếp theo điểm tương đồng
      combinedResults.sort((a, b) => 
        (b['similarityScore'] as double).compareTo(a['similarityScore'] as double)
      );
      
      return combinedResults;
    } catch (e) {
      debugPrint('Lỗi khi tìm kiếm tổng hợp: $e');
      return [];
    }
  }

  /// Xây dựng prompt RAG cho LLM
  String _buildRAGPrompt(
    String query, 
    String contextString, 
    QueryType queryType, 
    List<Map<String, dynamic>> contextData, 
    Map<String, dynamic> evaluationResult
  ) {
    // Tạo prompt dựa trên loại truy vấn
    String prompt = '';
    
    // Phần system prompt
    prompt += '''
Bạn là trợ lý AI của Student Market NTTU - chợ trao đổi sản phẩm dành cho sinh viên.
Hãy trả lời câu hỏi dựa CHÍNH XÁC vào ngữ cảnh được cung cấp.
Không được tự ý thêm thông tin không có trong ngữ cảnh.
''';
    
    // Phần contextual data
    prompt += "\n--- NGỮ CẢNH ---\n";
    prompt += contextString;
    prompt += "\n--- HẾT NGỮ CẢNH ---\n\n";
    
    // Phần câu hỏi
    prompt += "Câu hỏi: $query\n\n";
    
    // Thêm hướng dẫn cụ thể dựa vào loại truy vấn
    switch (queryType) {
      case QueryType.product:
        prompt += "Hãy trả lời về các sản phẩm trong ngữ cảnh, nêu rõ tên, giá, mô tả của sản phẩm.";
          break;
      case QueryType.category:
        prompt += "Hãy trả lời về danh mục trong ngữ cảnh, nêu rõ các sản phẩm thuộc danh mục này.";
          break;
      case QueryType.appUsage:
        prompt += "Hãy trả lời về cách sử dụng ứng dụng dựa vào hướng dẫn trong ngữ cảnh.";
          break;
      case QueryType.roadmap:
        prompt += "Hãy trình bày các bước theo thứ tự trong quy trình được cung cấp.";
          break;
      case QueryType.sourceCode:
        prompt += "Hãy giải thích mã nguồn dựa vào thông tin trong ngữ cảnh.";
          break;
      case QueryType.productInfo:
        prompt += "Hãy cung cấp thông tin chi tiết về sản phẩm dựa vào dữ liệu trong ngữ cảnh.";
          break;
      case QueryType.general:
        prompt += "Hãy trả lời câu hỏi dựa vào thông tin trong ngữ cảnh.";
        break;
      default:
        prompt += "Hãy trả lời câu hỏi dựa vào thông tin trong ngữ cảnh.";
          break;
      }
    
    return prompt;
  }

  /// Gọi API của LLM để xử lý truy vấn
  Future<String> _callLLMAPI(String prompt) async {
    try {
      // Sử dụng GeminiService để gọi API
      final response = await _geminiService.sendPromptedMessage(
        "Bạn là trợ lý AI của Student Market NTTU. Hãy trả lời ngắn gọn và hữu ích.",
        prompt
      );
      return response;
    } catch (e) {
      debugPrint('Lỗi khi gọi API LLM: $e');
      return 'Xin lỗi, đã xảy ra lỗi khi xử lý yêu cầu của bạn. Vui lòng thử lại sau.';
    }
  }

  /// Xây dựng ngữ cảnh cho truy vấn
  Future<Map<String, dynamic>> _buildQueryContext(String query, QueryType queryType) async {
    List<Map<String, dynamic>> contextData = [];
    String contextString = '';
    
    switch (queryType) {
      case QueryType.product:
        // Tìm kiếm sản phẩm
        contextData = await _searchProducts(query);
        break;
      
      case QueryType.category:
        // Tìm kiếm danh mục
        contextData = await _searchCategories(query);
        break;
      
      case QueryType.appUsage:
        // Tìm kiếm hướng dẫn sử dụng
        contextData = await _searchAppUsage(query);
        break;
      
      case QueryType.roadmap:
        // Tìm kiếm quy trình hướng dẫn
        contextData = await _searchRoadmap(query);
        break;
      
      case QueryType.sourceCode:
        // Tìm kiếm trong mã nguồn
        contextData = await _searchSourceCode(query);
        break;
      
      case QueryType.productInfo:
        // Tìm kiếm thông tin chi tiết sản phẩm
        contextData = await _searchProductDetails(query);
        break;
      
      case QueryType.general:
      default:
        // Tìm kiếm tổng hợp
        contextData = await _searchGeneral(query);
        break;
    }
    
    // Xây dựng chuỗi ngữ cảnh từ dữ liệu
    if (contextData.isNotEmpty) {
      switch (queryType) {
        case QueryType.product:
          contextString = 'THÔNG TIN SẢN PHẨM:\n\n';
          for (var product in contextData) {
            contextString += '- Tên: ${product['title']}\n';
            contextString += '  Giá: ${product['price']}đ\n';
            contextString += '  Mô tả: ${product['description']}\n';
            contextString += '\n';
          }
          break;
        
        case QueryType.productInfo:
          contextString = 'THÔNG TIN CHI TIẾT SẢN PHẨM:\n\n';
          for (var product in contextData) {
            contextString += '- Tên: ${product['title']}\n';
            contextString += '  Giá: ${product['price']}đ\n';
            contextString += '  Mô tả: ${product['description']}\n';
            if (product['category'] != null) {
              contextString += '  Danh mục: ${product['category']}\n';
            }
            if (product['condition'] != null) {
              contextString += '  Tình trạng: ${product['condition']}\n';
            }
            if (product['seller'] != null) {
              contextString += '  Người bán: ${product['seller']}\n';
            }
            contextString += '\n';
          }
          break;
        
        case QueryType.category:
          contextString = 'THÔNG TIN DANH MỤC:\n\n';
          for (var category in contextData) {
            contextString += '- Tên danh mục: ${category['title']}\n';
            contextString += '  Mô tả: ${category['description']}\n';
            contextString += '\n';
          }
          break;
          
        case QueryType.appUsage:
          contextString = 'HƯỚNG DẪN SỬ DỤNG:\n\n';
          for (var guide in contextData) {
            contextString += '- ${guide['title']}\n';
            contextString += '  ${guide['description']}\n';
            contextString += '\n';
          }
          break;
          
        case QueryType.roadmap:
          contextString = 'QUY TRÌNH HƯỚNG DẪN:\n\n';
          for (var roadmap in contextData) {
            contextString += '- ${roadmap['title']}\n';
            contextString += '  ${roadmap['description']}\n';
            contextString += '\n';
          }
          break;
          
        case QueryType.sourceCode:
          contextString = 'THÔNG TIN MÃ NGUỒN:\n\n';
          for (var code in contextData) {
            contextString += '- File: ${code['file']}\n';
            contextString += '  Tiêu đề: ${code['title']}\n';
            contextString += '  Mô tả: ${code['description']}\n';
            if (code['code'] != null) {
              contextString += '  Code: ${code['code']}\n';
            }
            contextString += '\n';
          }
          break;
          
        case QueryType.general:
        default:
          contextString = 'THÔNG TIN TỔNG HỢP:\n\n';
          for (var item in contextData) {
            contextString += '- ${item['title'] ?? "Không có tiêu đề"}\n';
            contextString += '  ${item['description'] ?? "Không có mô tả"}\n';
            contextString += '\n';
          }
          break;
      }
    }
    
    // Nếu không tìm thấy dữ liệu phù hợp, thêm dữ liệu mặc định
    if (contextString.isEmpty) {
      // Tạo thông tin cơ bản về ứng dụng
      contextString = '''
THÔNG TIN TỔNG QUAN:

Student Market NTTU là ứng dụng mua bán, trao đổi hàng hóa dành riêng cho sinh viên trường Đại học Nguyễn Tất Thành.

Các tính năng chính:
- Đăng bán sản phẩm mới hoặc đã qua sử dụng
- Tìm kiếm sản phẩm theo danh mục hoặc từ khóa
- Chat trực tiếp với người bán/người mua
- Quản lý đơn hàng và theo dõi trạng thái
- Đánh giá sản phẩm và người bán

Để đăng sản phẩm, người dùng cần đăng nhập vào tài khoản, chọn "Đăng sản phẩm" từ menu, điền thông tin và tải lên hình ảnh.

Mọi thắc mắc, vui lòng liên hệ hỗ trợ qua email: support@studentmarket.nttu.edu.vn
''';
      
      // Thêm dữ liệu vào contextData để có thể sử dụng sau này
      contextData.add({
        'title': 'Thông tin Student Market NTTU',
        'description': 'Ứng dụng mua bán, trao đổi hàng hóa dành riêng cho sinh viên NTTU',
        'type': 'app_info',
        'similarityScore': 0.5
      });
    }
    
    return {
      'contextData': contextData,
      'contextString': contextString
    };
  }

  /// Xử lý truy vấn của người dùng
  Future<Map<String, dynamic>> processUserQuery(String query, {bool returnRawContext = false}) async {
    // Nếu đang xử lý truy vấn khác, từ chối truy vấn mới
    if (_isProcessingQuery) {
      return {'response': 'Đang xử lý yêu cầu trước đó, vui lòng đợi trong giây lát.'};
    }
    
    // Bỏ kiểm tra truy vấn trùng lặp
    
    try {
      _safeSetState(searching: true, error: '');
      
      _isProcessingQuery = true;
      _lastProcessedQuery = query;
      
      // Phân tích loại truy vấn
      final queryType = _analyzeQueryType(query);
      debugPrint('Loại truy vấn: $queryType');
      
      // Xây dựng ngữ cảnh cho truy vấn
      final contextResult = await _buildQueryContext(query, queryType);
      final List<Map<String, dynamic>> contextData = contextResult['contextData'];
      final String contextString = contextResult['contextString'];
      
      // Lưu kết quả để có thể xem lại
      _retrievedDocuments = contextData;
      
      // Nếu yêu cầu trả về dữ liệu thô
      if (returnRawContext) {
        _safeSetState(searching: false);
        return {
          'queryType': queryType.toString(),
          'contextData': contextData,
          'contextString': contextString
        };
      }
      
      // Tạo prompt và gọi API xử lý
      Map<String, dynamic> evaluationResult = {};
      final prompt = _buildRAGPrompt(query, contextString, queryType, contextData, evaluationResult);
      
      // Gọi LLM API để xử lý
      final response = await _callLLMAPI(prompt);
      
      // Kiểm tra hallucination nếu cần thiết
      if (queryType == QueryType.product || queryType == QueryType.productInfo) {
        final hasHallucination = await _checkHallucination(response, contextData);
        if (hasHallucination) {
          _safeSetState(searching: false);
          return {
            'response': 'Xin lỗi, tôi không có đủ thông tin chính xác để trả lời câu hỏi của bạn. Vui lòng thử lại với câu hỏi cụ thể hơn.',
            'contextData': contextData, // Vẫn trả về contextData
            'queryType': queryType.toString()
          };
        }
      }
      
      _safeSetState(searching: false);
      return {
        'response': response,
        'contextData': contextData,
        'queryType': queryType.toString()
      };
    } catch (e) {
      debugPrint('Lỗi khi xử lý truy vấn: $e');
      _safeSetState(searching: false, error: 'Đã xảy ra lỗi: $e');
      return {
        'response': 'Đã xảy ra lỗi khi xử lý yêu cầu. Vui lòng thử lại sau.',
        'error': e.toString()
      };
    } finally {
      _isProcessingQuery = false;
    }
  }

  /// Phương thức tạo phản hồi RAG (Retrieval Augmented Generation)
  Future<Map<String, dynamic>> generateRAGResponse(
    String query, 
    String historyContext, 
    bool disableSearch
  ) async {
    // Nếu đang xử lý truy vấn khác, từ chối truy vấn mới
    if (_isProcessingQuery) {
      return {'response': 'Đang xử lý yêu cầu trước đó, vui lòng đợi trong giây lát.'};
    }
    
    // Bỏ kiểm tra truy vấn trùng lặp
    
    try {
      _isProcessingQuery = true;
      _lastProcessedQuery = query;
      
      // Phân tích loại truy vấn
      final queryType = _analyzeQueryType(query);
      debugPrint('Loại truy vấn: $queryType');
      
      if (disableSearch) {
        // Nếu tìm kiếm bị tắt, trả về phản hồi đơn giản
        final response = await _callLLMAPI(query);
        return {
          'response': response,
          'productDetails': []
        };
      }
      
      // Xây dựng ngữ cảnh cho truy vấn
      final contextResult = await _buildQueryContext(query, queryType);
      final List<Map<String, dynamic>> contextData = contextResult['contextData'];
      final String contextString = contextResult['contextString'];
      
      // Tạo prompt và gọi API xử lý
      Map<String, dynamic> evaluationResult = {};
      final prompt = _buildRAGPrompt(query, contextString, queryType, contextData, evaluationResult);
      
      // Thêm lịch sử cuộc trò chuyện nếu có
      String fullPrompt = prompt;
      if (historyContext.isNotEmpty) {
        fullPrompt = "$historyContext\n\n$prompt";
      }
      
      // Gọi LLM API để xử lý
      final response = await _callLLMAPI(fullPrompt);
      
      // Kiểm tra hallucination nếu cần thiết
      if (queryType == QueryType.product || queryType == QueryType.productInfo) {
        final hasHallucination = await _checkHallucination(response, contextData);
        if (hasHallucination) {
          return {
            'response': 'Xin lỗi, tôi không có đủ thông tin chính xác để trả lời câu hỏi của bạn. Vui lòng thử lại với câu hỏi cụ thể hơn.',
            'productDetails': contextData.take(3).toList() // Vẫn trả về thông tin sản phẩm
          };
        }
      }
      
      // Luôn trả về thông tin sản phẩm nếu có
      List<Map<String, dynamic>> productDetails = [];
      
      // Lấy sản phẩm từ kết quả tìm kiếm
      for (var item in contextData) {
        if (item['type'] == 'product' || item['type'] == 'product_info') {
          productDetails.add(item);
        }
      }
      
      // Giới hạn số lượng sản phẩm hiển thị
      if (productDetails.length > 3) {
        productDetails = productDetails.take(3).toList();
      }
      
      return {
        'response': response,
        'productDetails': productDetails
      };
    } catch (e) {
      debugPrint('Lỗi khi xử lý truy vấn: $e');
      return {
        'response': 'Đã xảy ra lỗi khi xử lý yêu cầu. Vui lòng thử lại sau.',
        'productDetails': []
      };
    } finally {
      _isProcessingQuery = false;
    }
  }

  /// Kiểm tra hallucination cho phản hồi
  Future<bool> _checkHallucination(String response, List<Map<String, dynamic>> contextData) async {
    try {
      // Tạo một danh sách các thuộc tính trong ngữ cảnh để so sánh
      Set<String> contextualFacts = {};
      
      // Thu thập thông tin từ ngữ cảnh
      for (var item in contextData) {
        // Thêm thông tin sản phẩm
        if (item['title'] != null) contextualFacts.add(item['title'].toString().toLowerCase());
        if (item['price'] != null) contextualFacts.add(item['price'].toString());
        if (item['category'] != null) contextualFacts.add(item['category'].toString().toLowerCase());
        if (item['condition'] != null) contextualFacts.add(item['condition'].toString().toLowerCase());
        if (item['seller'] != null) contextualFacts.add(item['seller'].toString().toLowerCase());
        
        // Thêm keywords từ mô tả
        if (item['description'] != null) {
          final desc = item['description'].toString().toLowerCase();
          final words = desc.split(' ')
              .where((word) => word.length > 3) // Chỉ xem xét từ có độ dài > 3
              .toList();
          contextualFacts.addAll(words);
        }
      }
      
      // Phân tích phản hồi
      final responseLower = response.toLowerCase();
      
      // Tách phản hồi thành các phần để phân tích
      final sentences = responseLower.split('. ');
      
      // Đếm số câu có thông tin xác thực
      int verifiedSentences = 0;
      int totalSentences = sentences.length;
      
      for (var sentence in sentences) {
        if (sentence.isEmpty) continue;
        
        // Kiểm tra xem câu có chứa thông tin từ ngữ cảnh hay không
        bool sentenceHasContext = false;
        for (var fact in contextualFacts) {
          if (sentence.contains(fact)) {
            sentenceHasContext = true;
            break;
          }
        }
        
        if (sentenceHasContext) {
          verifiedSentences++;
        }
      }
      
      // Tính tỷ lệ câu được xác minh
      if (totalSentences > 0) {
        final verificationRate = verifiedSentences / totalSentences;
        
        // Nếu tỷ lệ thấp hơn ngưỡng, coi là hallucination
        return verificationRate < 0.7; // Ngưỡng 70%
      }
      
      return false;
    } catch (e) {
      debugPrint('Lỗi khi kiểm tra hallucination: $e');
      return false; // Mặc định cho phép phản hồi trong trường hợp lỗi
    }
  }
}
