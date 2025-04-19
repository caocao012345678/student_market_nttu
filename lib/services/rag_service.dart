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

  /// Phân tích truy vấn để xác định loại thông tin cần tìm
  QueryType _analyzeQueryType(String query) {
    query = query.toLowerCase();
    
    // Từ khóa liên quan đến sản phẩm
    final productKeywords = [
      'sản phẩm', 'mua', 'bán', 'giá', 'hàng', 'đồ', 'thanh toán', 
      'đăng bán', 'đăng sản phẩm', 'đăng đồ', 'bán đồ', 'quản lý sản phẩm',
      'chỉnh sửa sản phẩm', 'xóa sản phẩm', 'sửa sản phẩm', 'sản phẩm của tôi',
      'đăng sản phẩm mới', 'bán hàng'
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
    
    // Đếm số từ khóa khớp cho mỗi loại
    int productMatches = 0;
    int categoryMatches = 0;
    int appUsageMatches = 0;
    
    // Kiểm tra từng từ khóa
    for (final keyword in productKeywords) {
      if (query.contains(keyword)) productMatches++;
    }
    
    for (final keyword in categoryKeywords) {
      if (query.contains(keyword)) categoryMatches++;
    }
    
    for (final keyword in appUsageKeywords) {
      if (query.contains(keyword)) appUsageMatches++;
    }
    
    // Phân loại dựa trên số lượng từ khóa phù hợp
    if (productMatches > categoryMatches && productMatches > appUsageMatches) {
      return QueryType.product;
    } else if (categoryMatches > productMatches && categoryMatches > appUsageMatches) {
      return QueryType.category;
    } else if (appUsageMatches > productMatches && appUsageMatches > categoryMatches) {
      return QueryType.appUsage;
    }
    
    // Trường hợp không rõ ràng hoặc có cùng số lượng từ khóa khớp
    // Phân loại dựa trên từ khóa cụ thể có mức độ ưu tiên cao
    if (query.contains('đăng bán') || query.contains('bán đồ') || 
        query.contains('đăng sản phẩm') || query.contains('quản lý sản phẩm')) {
      return QueryType.appUsage;  // Ưu tiên hướng dẫn sử dụng cho các chức năng liên quan đến sản phẩm
    }
    
    // Trường hợp chung
    return QueryType.general;
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
      
      // Tìm các từ khóa chính trong query
      final queryKeywords = lowerQuery.split(RegExp(r'\s+'))
          .where((word) => word.length > 2)  // Loại bỏ từ quá ngắn
          .toList();
      
      // Đánh dấu các truy vấn cụ thể để tăng độ ưu tiên
      final isProductManagementQuery = 
          lowerQuery.contains('đăng bán') || 
          lowerQuery.contains('quản lý sản phẩm') ||
          lowerQuery.contains('bán sản phẩm') ||
          lowerQuery.contains('bán đồ') ||
          lowerQuery.contains('đăng sản phẩm') ||
          lowerQuery.contains('chỉnh sửa sản phẩm') ||
          lowerQuery.contains('xóa sản phẩm');
          
      // Các từ khoá liên quan đến màn hình
      final isScreenQuery = lowerQuery.contains('màn hình') || 
                            lowerQuery.contains('giao diện') || 
                            lowerQuery.contains('trang');
                            
      // Các từ khoá liên quan đến chức năng
      final isFeatureQuery = lowerQuery.contains('chức năng') || 
                             lowerQuery.contains('tính năng') || 
                             lowerQuery.contains('làm thế nào') ||
                             lowerQuery.contains('làm sao') ||
                             lowerQuery.contains('cách');
      
      // Tìm kiếm ưu tiên trong user_tasks của các feature trước
      if (!isScreenQuery || isFeatureQuery || isProductManagementQuery) {
        // Ưu tiên tìm kiếm tác vụ người dùng trước
        for (var feature in _appLayoutService!.appFeatures) {
          if (feature['user_tasks'] != null && feature['user_tasks'] is List) {
            double bestTaskScore = 0;
            String bestMatchingTask = '';
            
            // Tìm tác vụ có điểm tương đồng cao nhất
            for (var task in feature['user_tasks']) {
              final taskString = task.toString().toLowerCase();
              final taskScore = _calculateSimilarity(query, taskString);
              
              // Lưu lại điểm tương đồng cao nhất
              if (taskScore > bestTaskScore) {
                bestTaskScore = taskScore;
                bestMatchingTask = taskString;
              }
              
              // Kiểm tra nếu query chứa toàn bộ task
              if (lowerQuery.contains(taskString) && taskString.length > 10) {
                bestTaskScore = math.max(bestTaskScore, 0.9); // Gán điểm rất cao
                bestMatchingTask = taskString;
              }
            }
            
            // Nếu có điểm tương đồng tác vụ tốt
            if (bestTaskScore >= 0.6) {
              final featureName = (feature['name'] ?? '').toString().toLowerCase();
              final featureDesc = (feature['description'] ?? '').toString().toLowerCase();
              final featureUsage = (feature['usage'] ?? '').toString().toLowerCase();
              
              // Cải thiện mô tả của tính năng đó với tác vụ khớp
              String enhancedDescription = feature['description'] + 
                  '\nTác vụ tương ứng: ' + bestMatchingTask;
                  
              // Tạo hướng dẫn sử dụng cho chức năng này
              final guide = _appLayoutService!.generateUsageGuideForFeature(feature['id']);
              
              // Tìm các đường dẫn đến tính năng này
              final paths = _appLayoutService!.findPathsToFeature(feature['id']);
              
              results.add({
                'id': 'feature_task_${feature['id']}',
                'type': 'app_layout',
                'subtype': 'feature',
                'data': {
                  ...feature,
                  'description': enhancedDescription,
                  'matching_task': bestMatchingTask,
                  'usage_guide': guide,
                  'navigation_paths': paths
                },
                'similarityScore': bestTaskScore * 1.2, // Tăng điểm cho kết quả khớp tác vụ
                'relevanceScore': (bestTaskScore * 12).round()
              });
            }
          }
        }
      }
      
      // Tìm kiếm qua danh sách màn hình
      if (isScreenQuery || !isFeatureQuery) {
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
      if (isFeatureQuery || !isScreenQuery || results.isEmpty) {
        for (var feature in _appLayoutService!.appFeatures) {
          final featureName = (feature['name'] ?? '').toString().toLowerCase();
          final featureDesc = (feature['description'] ?? '').toString().toLowerCase();
          final featureUsage = (feature['usage'] ?? '').toString().toLowerCase();
          final featureLocation = (feature['location'] ?? '').toString().toLowerCase();
          
          // Tính điểm tương đồng
          final nameSimilarity = _calculateSimilarity(query, featureName) * 3;
          final descSimilarity = _calculateSimilarity(query, featureDesc);
          final usageSimilarity = _calculateSimilarity(query, featureUsage) * 2;
          final locationSimilarity = _calculateSimilarity(query, featureLocation) * 2.5;
          
          var totalSimilarity = nameSimilarity + descSimilarity + usageSimilarity + locationSimilarity;
          
          // Thêm điểm nếu query chứa các từ khóa trong user_tasks
          if (feature['user_tasks'] != null && feature['user_tasks'] is List) {
            double bestTaskScore = 0;
            
            for (var task in feature['user_tasks']) {
              final taskSimilarity = _calculateSimilarity(query, task.toString().toLowerCase());
              if (taskSimilarity > bestTaskScore) {
                bestTaskScore = taskSimilarity;
              }
            }
            
            // Tăng điểm đáng kể cho các tác vụ phù hợp
            if (bestTaskScore > 0.3) {
              totalSimilarity += bestTaskScore * 3.5;  // Trọng số cao hơn cho user_tasks
              
              // Tăng thêm điểm cho các chức năng quản lý sản phẩm nếu query liên quan
              if (isProductManagementQuery && 
                  (feature['id'] == 'add_product' || 
                   feature['id'] == 'manage_products')) {
                totalSimilarity += 0.5;  // Tăng thêm điểm cho các chức năng quản lý sản phẩm
              }
            }
          }
          
          // Kiểm tra nếu từ khóa trong query xuất hiện trong tên hoặc mô tả của tính năng
          for (var keyword in queryKeywords) {
            if (keyword.length >= 4) {  // Chỉ xét các từ khóa có ý nghĩa
              if (featureName.contains(keyword)) {
                totalSimilarity += 0.3;  // Tăng điểm cho từ khóa xuất hiện trong tên
              }
              if (featureDesc.contains(keyword)) {
                totalSimilarity += 0.15;  // Tăng điểm cho từ khóa xuất hiện trong mô tả
              }
            }
          }
          
          if (totalSimilarity >= _similarityThreshold) {
            // Tạo hướng dẫn sử dụng cho chức năng này
            final guide = _appLayoutService!.generateUsageGuideForFeature(feature['id']);
            
            // Tìm các đường dẫn đến tính năng này
            final paths = _appLayoutService!.findPathsToFeature(feature['id']);
            
            results.add({
              'id': 'feature_${feature['id']}',
              'type': 'app_layout',
              'subtype': 'feature',
              'data': {
                ...feature,
                'usage_guide': guide,
                'navigation_paths': paths
              },
              'similarityScore': totalSimilarity,
              'relevanceScore': (totalSimilarity * 10).round()
            });
          }
        }
      }
      
      // Tìm kiếm đường dẫn điều hướng
      if (lowerQuery.contains('điều hướng') ||
          lowerQuery.contains('chuyển') ||
          lowerQuery.contains('đi đến') ||
          lowerQuery.contains('tìm') ||
          lowerQuery.contains('ở đâu')) {
        // Xử lý các câu hỏi kiểu "làm thế nào để đi đến X" hoặc "X ở đâu"
        // Trích xuất đích đến từ câu hỏi
        String target = '';
        
        // Phân tích câu hỏi để tìm mục tiêu
        final findTargetPatterns = [
          RegExp(r'đi đến\s+(.+?)(?:\s+ở đâu|\?|$)'),
          RegExp(r'tìm\s+(.+?)(?:\s+ở đâu|\?|$)'),
          RegExp(r'(.+?)\s+ở đâu'),
          RegExp(r'làm thế nào để.+?(?:đến|tìm|xem)\s+(.+?)(?:\?|$)'),
        ];
        
        for (var pattern in findTargetPatterns) {
          final match = pattern.firstMatch(lowerQuery);
          if (match != null && match.groupCount >= 1) {
            target = match.group(1)!.trim();
            break;
          }
        }
        
        if (target.isNotEmpty) {
          // Tìm tính năng hoặc màn hình phù hợp với target
          Map<String, dynamic>? bestMatch;
          double bestScore = 0;
          
          // Tìm trong màn hình
          for (var screen in _appLayoutService!.appScreens) {
            final screenName = (screen['name'] ?? '').toString().toLowerCase();
            final similarity = _calculateSimilarity(target, screenName);
            
            if (similarity > bestScore) {
              bestScore = similarity;
              bestMatch = {
                'type': 'screen',
                'id': screen['id'],
                'data': screen
              };
            }
          }
          
          // Tìm trong tính năng
          for (var feature in _appLayoutService!.appFeatures) {
            final featureName = (feature['name'] ?? '').toString().toLowerCase();
            final similarity = _calculateSimilarity(target, featureName);
            
            if (similarity > bestScore) {
              bestScore = similarity;
              bestMatch = {
                'type': 'feature',
                'id': feature['id'],
                'data': feature
              };
            }
          }
          
          // Nếu tìm thấy kết quả phù hợp
          if (bestMatch != null && bestScore >= 0.3) {  // Ngưỡng thấp hơn để mở rộng kết quả
            if (bestMatch['type'] == 'screen') {
              // Tìm các đường dẫn đến màn hình
              final screenId = bestMatch['id'];
              final pathsToScreen = _appLayoutService!.navigationPaths
                  .where((path) => path['to_screen_id'] == screenId)
                  .toList();
              
              if (pathsToScreen.isNotEmpty) {
                results.add({
                  'id': 'navigation_to_screen_${screenId}',
                  'type': 'app_layout',
                  'subtype': 'navigation',
                  'data': {
                    'target_screen': bestMatch['data'],
                    'paths': pathsToScreen,
                    'usage_guide': _generateNavigationGuide(pathsToScreen, _appLayoutService!.appScreens),
                  },
                  'similarityScore': 0.8 + bestScore,  // Điểm cao cho kết quả điều hướng
                  'relevanceScore': (8 + bestScore * 10).round()
                });
              }
            } else if (bestMatch['type'] == 'feature') {
              // Tìm các đường dẫn đến tính năng
              final featureId = bestMatch['id'];
              final paths = _appLayoutService!.findPathsToFeature(featureId);
              
              if (paths.isNotEmpty) {
                results.add({
                  'id': 'navigation_to_feature_${featureId}',
                  'type': 'app_layout',
                  'subtype': 'navigation',
                  'data': {
                    'target_feature': bestMatch['data'],
                    'paths': paths,
                    'usage_guide': _appLayoutService!.generateUsageGuideForFeature(featureId),
                  },
                  'similarityScore': 0.85 + bestScore,  // Điểm cao cho kết quả điều hướng
                  'relevanceScore': (8.5 + bestScore * 10).round()
                });
              }
            }
          }
        }
      }
      
      // Nếu là truy vấn chung về ứng dụng
      if (lowerQuery.contains('ứng dụng') || lowerQuery.contains('app') || results.isEmpty) {
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
          'similarityScore': lowerQuery.contains('ứng dụng') || lowerQuery.contains('app') ? 0.8 : 0.5,
          'relevanceScore': lowerQuery.contains('ứng dụng') || lowerQuery.contains('app') ? 8 : 5
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
  
  // Tạo hướng dẫn điều hướng
  String _generateNavigationGuide(List<Map<String, dynamic>> paths, List<Map<String, dynamic>> screens) {
    if (paths.isEmpty) return 'Không tìm thấy đường dẫn đến màn hình này.';
    
    String guide = 'HƯỚNG DẪN ĐIỀU HƯỚNG:\n\n';
    
    for (var path in paths) {
      final fromScreenId = path['from_screen_id'];
      final toScreenId = path['to_screen_id'];
      
      final fromScreen = screens.firstWhere(
        (s) => s['id'] == fromScreenId,
        orElse: () => {'name': 'Màn hình không xác định'},
      );
      
      final toScreen = screens.firstWhere(
        (s) => s['id'] == toScreenId,
        orElse: () => {'name': 'Màn hình không xác định'},
      );
      
      guide += 'Từ ${fromScreen['name']} đến ${toScreen['name']}:\n';
      guide += '  ${path['method']}\n\n';
    }
    
    return guide;
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
        final productCategory = (data['category'] ?? '').toString().toLowerCase();
        final searchableText = (data['searchable_text'] ?? '').toString().toLowerCase();
        final keywords = data['keywords'] is List 
            ? (data['keywords'] as List).map((k) => k.toString().toLowerCase()).join(' ')
            : '';
        
        // Tính điểm tương đồng cải tiến với nhiều nguồn dữ liệu
        final nameSimilarity = _calculateSimilarity(query, productName) * 4;  // Nhân 4 để tăng trọng số cho tên
        final descSimilarity = _calculateSimilarity(query, productDescription) * 2; // Nhân 2 cho mô tả
        final categorySimilarity = _calculateSimilarity(query, productCategory) * 1.5; // Nhân 1.5 cho danh mục
        final keywordSimilarity = _calculateSimilarity(query, keywords) * 3; // Nhân 3 cho từ khóa
        
        // Tính điểm tổng hợp
        var totalSimilarity = nameSimilarity + descSimilarity + categorySimilarity + keywordSimilarity;
        
        // Thêm điểm nếu tìm thấy trong searchableText (đã được tối ưu hóa trước)
        if (searchableText.isNotEmpty) {
          final searchTextSimilarity = _calculateSimilarity(query, searchableText);
          totalSimilarity += searchTextSimilarity * 1.5;
        }
        
        // Ưu tiên các sản phẩm có thông tin chi tiết đã được nâng cao
        if (data['rag_metadata'] != null && data['rag_metadata']['has_enhanced_data'] == true) {
          totalSimilarity *= 1.2;  // Tăng 20% điểm cho sản phẩm có dữ liệu nâng cao
        }
        
        // Ưu tiên sản phẩm mới
        if (data['createdAt'] != null) {
          try {
            final createdAt = data['createdAt'].toDate();
            final now = DateTime.now();
            final daysDifference = now.difference(createdAt).inDays;
            
            // Sản phẩm trong vòng 7 ngày được ưu tiên
            if (daysDifference <= 7) {
              totalSimilarity *= 1.1;  // Tăng 10% điểm
            }
          } catch (e) {
            // Bỏ qua lỗi khi xử lý thời gian
          }
        }
        
        // Thêm vào kết quả nếu đạt ngưỡng tương đồng
        if (totalSimilarity >= _similarityThreshold) {
          // Tạo tóm tắt sản phẩm nếu chưa có
          String productSummary = data['summary'] ?? '';
          if (productSummary.isEmpty) {
            productSummary = 'Sản phẩm: ${data['name']}\n';
            productSummary += 'Giá: ${data['price']}\n';
            productSummary += 'Mô tả: ${data['description']}\n';
            if (data['condition'] != null) {
              productSummary += 'Tình trạng: ${data['condition']}\n';
            }
          }
          
          results.add({
            'id': doc.id,
            'type': 'product',
            'data': {
              ...data,
              'summary': productSummary,
            },
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
        // Tạo hướng dẫn mô hình
        final systemPrompt = _createSystemPrompt();
        // Truyền addToHistory=false để tránh thêm trùng lặp vào lịch sử
        response = await _geminiService.sendPromptedMessage(systemPrompt, query, addToHistory: false);
      } else {
        // Tạo context từ dữ liệu đã truy xuất
        String context = _createContextFromDocs(relevantDocs);
        // Tạo hướng dẫn mô hình
        final systemPrompt = _createSystemPrompt();
        
        debugPrint('Tìm thấy ${relevantDocs.length} tài liệu có điểm tương đồng >= $_similarityThreshold');
        
        // Sử dụng context và system prompt
        response = await _geminiService.sendContextAndPrompt(context, systemPrompt, query);
      }
      
      // Tinh chỉnh câu trả lời để loại bỏ định dạng hoặc kết quả không phù hợp
      response = _refineResponse(response);
      
      // Lưu tương tác của người dùng để cải thiện dữ liệu trong tương lai
      _saveInteractionForImprovement(query, response, relevantDocs);
      
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
  
  /// Tạo hướng dẫn hệ thống để giúp mô hình sinh ra câu trả lời phù hợp
  String _createSystemPrompt() {
    return '''
    Bạn là trợ lý ảo của ứng dụng Student Market NTTU, một nền tảng mua bán đồ cũ dành riêng cho sinh viên trường Đại học Nguyễn Tất Thành.
    
    Quy tắc quan trọng khi trả lời:
    1. Chỉ trả lời các câu hỏi liên quan trực tiếp đến ứng dụng Student Market NTTU
    2. Không sử dụng định dạng đậm, nghiêng, gạch chân hoặc Markdown trong câu trả lời
    3. Tránh sử dụng các từ như "rất", "vô cùng", hay các biểu hiện cảm xúc quá mức
    4. Không đưa ra các câu trả lời chung chung hoặc mở rộng ra ngoài phạm vi ứng dụng
    5. Nếu không biết câu trả lời, nói "Tôi không có thông tin về vấn đề này trong ứng dụng Student Market NTTU"
    6. Câu trả lời ngắn gọn, súc tích, đi thẳng vào vấn đề
    7. Không sử dụng dấu hiệu như "Câu trả lời:" hoặc "Hướng dẫn:"
    
    Phạm vi ứng dụng bao gồm: đăng bán sản phẩm, tìm kiếm sản phẩm, mua hàng, nhắn tin, quản lý tài khoản và các tính năng của ứng dụng.
    
    Tránh trả lời các câu hỏi về:
    - Thông tin cá nhân người dùng
    - Các dịch vụ không liên quan đến ứng dụng
    - Câu hỏi về các sản phẩm cụ thể không có trong dữ liệu
    - Thông tin kỹ thuật chi tiết về cách ứng dụng được phát triển
    
    Luôn trả lời bằng tiếng Việt, ngắn gọn và có tính thực tiễn.
    ''';
  }
  
  /// Tinh chỉnh câu trả lời để đảm bảo phù hợp với quy định
  String _refineResponse(String response) {
    // Loại bỏ các định dạng Markdown
    var refined = response.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1'); // Bold
    refined = refined.replaceAll(RegExp(r'\*(.*?)\*'), r'$1'); // Italic
    refined = refined.replaceAll(RegExp(r'__(.*?)__'), r'$1'); // Underline
    refined = refined.replaceAll(RegExp(r'_(.*?)_'), r'$1'); // Italic underscore
    refined = refined.replaceAll(RegExp(r'```(.*?)```', dotAll: true), r'$1'); // Code blocks
    refined = refined.replaceAll(RegExp(r'`(.*?)`'), r'$1'); // Inline code
    
    // Loại bỏ các tiêu đề không cần thiết
    refined = refined.replaceAll(RegExp(r'^(Hướng dẫn|Câu trả lời|Thông tin|Giải thích):\s*', multiLine: true), '');
    
    // Loại bỏ các từ diễn đạt cảm xúc quá mức
    final excessiveWords = [
      'rất', 'vô cùng', 'tuyệt vời', 'xuất sắc', 'tuyệt đối', 
      'hoàn toàn', 'cực kỳ', 'vô số', 'đặc biệt', 'bất ngờ',
      'hoàn hảo', 'tối ưu'
    ];
    
    for (final word in excessiveWords) {
      refined = refined.replaceAll(' $word ', ' ');
    }
    
    return refined.trim();
  }
  
  /// Lưu tương tác của người dùng để cải thiện dữ liệu trong tương lai
  Future<void> _saveInteractionForImprovement(String query, String response, List<Map<String, dynamic>> retrievedDocs) async {
    try {
      // Tạo dữ liệu về tương tác
      final interaction = {
        'query': query,
        'response': response,
        'timestamp': DateTime.now().millisecondsSinceEpoch, // Thay thế FieldValue.serverTimestamp()
        'relevantDocsCount': retrievedDocs.length,
        'relevantDocsIds': retrievedDocs.map((doc) => doc['id']).toList(),
        'similarityScores': retrievedDocs.map((doc) => doc['similarityScore']).toList(),
      };
      
      // Lưu vào Firestore
      await _firestore.collection('rag_interactions').add(interaction);
      
      // Nếu không có kết quả phù hợp, lưu vào danh sách truy vấn cần cải thiện
      if (retrievedDocs.isEmpty || retrievedDocs.length < 2) {
        await _firestore.collection('queries_to_improve').add({
          'query': query,
          'timestamp': DateTime.now().millisecondsSinceEpoch, // Thay thế FieldValue.serverTimestamp()
          'relevantDocsCount': retrievedDocs.length,
          'status': 'pending'
        });
      }
    } catch (e) {
      debugPrint('Lỗi khi lưu tương tác để cải thiện: $e');
    }
  }

  /// Tạo ngữ cảnh từ các tài liệu đã truy xuất
  String _createContextFromDocs(List<Map<String, dynamic>> docs) {
    String context = '';
    
    // Thêm tiêu đề và thông tin tổng quan (loại bỏ định dạng đặc biệt)
    context += "THÔNG TIN HỖ TRỢ\n\n";
    
    // Phân loại tài liệu theo loại
    final productDocs = docs.where((doc) => doc['type'] == 'product').toList();
    final categoryDocs = docs.where((doc) => doc['type'] == 'category').toList();
    final instructionDocs = docs.where((doc) => doc['type'] == 'instruction').toList();
    final appLayoutDocs = docs.where((doc) => doc['type'] == 'app_layout').toList();
    
    // Kiểm tra xem có tài liệu task_feature không (kết quả từ tìm kiếm user_tasks)
    final taskFeatureDocs = appLayoutDocs
        .where((doc) => doc['subtype'] == 'feature' && doc['id'].toString().startsWith('feature_task_'))
        .toList();
    
    // Nếu có kết quả tác vụ cụ thể, ưu tiên hiển thị trước
    if (taskFeatureDocs.isNotEmpty) {
      context += "HƯỚNG DẪN NHIỆM VỤ CỤ THỂ\n";
      for (var doc in taskFeatureDocs) {
        final data = doc['data'];
        context += "TÁC VỤ: ${data['matching_task'] ?? 'Không xác định'}\n";
        context += "TÍNH NĂNG: ${data['name']}\n";
        context += "MÔ TẢ: ${data['description']}\n";
        context += "VỊ TRÍ: ${data['location']}\n";
        context += "CÁCH THỰC HIỆN: ${data['usage']}\n\n";
        
        // Thêm hướng dẫn chi tiết
        if (data['usage_guide'] != null && data['usage_guide'].toString().isNotEmpty) {
          context += "HƯỚNG DẪN CHI TIẾT:\n${data['usage_guide']}\n";
        }
        
        // Thêm thông tin đường dẫn nếu có
        if (data['navigation_paths'] != null && data['navigation_paths'] is List && 
            (data['navigation_paths'] as List).isNotEmpty) {
          context += "CÁCH TRUY CẬP:\n";
          for (var path in data['navigation_paths']) {
            if (path['steps'] != null && path['steps'] is List) {
              context += "- Từ ${path['from']}: \n";
              for (var step in path['steps']) {
                context += "  * $step\n";
              }
            }
          }
        }
        context += "\n";
      }
      context += "----------\n\n";
    }
    
    // Trước tiên, thêm thông tin tổng quan nếu có
    final overviewDocs = appLayoutDocs.where((doc) => doc['subtype'] == 'overview').toList();
    if (overviewDocs.isNotEmpty) {
      context += "TỔNG QUAN ỨNG DỤNG\n";
      for (var doc in overviewDocs) {
        context += "${doc['data']['content']}\n\n";
      }
      context += "----------\n\n";
    }
    
    // Thêm thông tin về các tính năng (sắp xếp theo điểm liên quan)
    final featureDocs = appLayoutDocs
        .where((doc) => doc['subtype'] == 'feature' && !doc['id'].toString().startsWith('feature_task_'))
        .toList();
    
    if (featureDocs.isNotEmpty) {
      // Sắp xếp tính năng theo điểm tương đồng giảm dần
      featureDocs.sort((a, b) => (b['similarityScore'] as double).compareTo(a['similarityScore'] as double));
      
      context += "THÔNG TIN TÍNH NĂNG\n";
      for (var doc in featureDocs) {
        final data = doc['data'];
        context += "Tính năng: ${data['name']}\n";
        context += "Mô tả: ${data['description']}\n";
        context += "Vị trí: ${data['location']}\n";
        context += "Cách sử dụng: ${data['usage']}\n";
        
        // Thêm hướng dẫn chi tiết nếu có
        if (data['usage_guide'] != null && data['usage_guide'].toString().isNotEmpty) {
          context += "Hướng dẫn chi tiết:\n${data['usage_guide']}\n";
        }
        
        // Thêm thông tin về đường dẫn đến tính năng
        if (data['navigation_paths'] != null && data['navigation_paths'] is List && 
            (data['navigation_paths'] as List).isNotEmpty) {
          context += "Cách truy cập:\n";
          for (var path in data['navigation_paths']) {
            context += "- Từ ${path['from'] ?? 'màn hình chính'}: ${path['steps'].join(' -> ')}\n";
          }
        }
        context += "\n";
      }
      context += "----------\n\n";
    }
    
    // Thêm thông tin về các màn hình
    final screenDocs = appLayoutDocs.where((doc) => doc['subtype'] == 'screen').toList();
    if (screenDocs.isNotEmpty) {
      context += "THÔNG TIN MÀN HÌNH\n";
      for (var doc in screenDocs) {
        final data = doc['data'];
        context += "Màn hình: ${data['name']}\n";
        context += "Mô tả: ${data['description']}\n";
        
        // Thêm hướng dẫn sử dụng màn hình nếu có
        if (data['usage_guide'] != null && data['usage_guide'].toString().isNotEmpty) {
          context += "Hướng dẫn sử dụng:\n${data['usage_guide']}\n";
        }
        context += "\n";
      }
      context += "----------\n\n";
    }
    
    // Thêm thông tin về điều hướng
    final navigationDocs = appLayoutDocs.where((doc) => doc['subtype'] == 'navigation').toList();
    if (navigationDocs.isNotEmpty) {
      context += "THÔNG TIN ĐIỀU HƯỚNG\n";
      for (var doc in navigationDocs) {
        final data = doc['data'];
        
        // Nếu điều hướng đến màn hình
        if (data['target_screen'] != null) {
          context += "Điều hướng đến: ${data['target_screen']['name']}\n";
          
          if (data['paths'] != null && data['paths'] is List) {
            context += "Các cách truy cập:\n";
            for (var path in data['paths']) {
              context += "- ${path['method']}\n";
            }
          }
        }
        // Nếu điều hướng đến tính năng
        else if (data['target_feature'] != null) {
          context += "Điều hướng đến tính năng: ${data['target_feature']['name']}\n";
          context += "Vị trí tính năng: ${data['target_feature']['location']}\n";
          
          if (data['paths'] != null && data['paths'] is List) {
            context += "Các bước truy cập:\n";
            for (var path in data['paths']) {
              if (path['steps'] != null && path['steps'] is List) {
                for (var i = 0; i < (path['steps'] as List).length; i++) {
                  context += "  ${i+1}. ${path['steps'][i]}\n";
                }
              }
            }
          }
        }
        
        // Thêm hướng dẫn nếu có
        if (data['usage_guide'] != null && data['usage_guide'].toString().isNotEmpty) {
          context += "Hướng dẫn:\n${data['usage_guide']}\n";
        }
        context += "\n";
      }
      context += "----------\n\n";
    }
    
    // Thêm thông tin về sản phẩm nếu có
    if (productDocs.isNotEmpty) {
      context += "THÔNG TIN SẢN PHẨM\n";
      for (var doc in productDocs) {
        final data = doc['data'];
        
        // Ưu tiên sử dụng summary đã tối ưu hóa nếu có
        if (data['summary'] != null && data['summary'].toString().isNotEmpty) {
          context += "${data['summary']}\n";
        } else {
          context += "Sản phẩm: ${data['name']}\n";
          context += "Giá: ${data['price']}\n";
          context += "Mô tả: ${data['description']}\n";
          
          // Thêm thông tin nổi bật nếu có
          if (data['highlights'] != null && data['highlights'] is Map) {
            context += "Điểm nổi bật:\n";
            (data['highlights'] as Map).forEach((key, value) {
              if (value != null) {
                context += "- $key: $value\n";
              }
            });
          }
          
          // Thêm thông tin người đăng
          if (data['postedBy'] != null) {
            context += "Đăng bởi: ${data['postedBy']}\n";
          }
        }
        context += "\n";
      }
      context += "----------\n\n";
    }
    
    // Thêm thông tin về danh mục nếu có
    if (categoryDocs.isNotEmpty) {
      context += "THÔNG TIN DANH MỤC\n";
      for (var doc in categoryDocs) {
        final data = doc['data'];
        context += "Danh mục: ${data['name']}\n";
        context += "Mô tả: ${data['description']}\n";
        
        // Thêm thông tin về danh mục liên quan nếu có
        if (data['related_categories'] != null && data['related_categories'] is List) {
          final relatedCategories = (data['related_categories'] as List).join(', ');
          if (relatedCategories.isNotEmpty) {
            context += "Danh mục liên quan: $relatedCategories\n";
          }
        }
        context += "\n";
      }
      context += "----------\n\n";
    }
    
    // Thêm thông tin về hướng dẫn sử dụng nếu có
    if (instructionDocs.isNotEmpty) {
      context += "HƯỚNG DẪN SỬ DỤNG\n";
      for (var doc in instructionDocs) {
        final data = doc['data'];
        context += "Hướng dẫn: ${data['title']}\n";
        context += "Nội dung: ${data['content']}\n\n";
      }
      context += "----------\n\n";
    }
    
    // Thêm hướng dẫn đặc biệt cho các chức năng quản lý sản phẩm
    final manageProductFeatures = featureDocs.where(
      (doc) => doc['data']['id'] == 'add_product' || doc['data']['id'] == 'manage_products'
    ).toList();
    
    if (manageProductFeatures.isNotEmpty) {
      context += "HƯỚNG DẪN QUẢN LÝ SẢN PHẨM NHANH\n";
      context += "Để đăng bán sản phẩm:\n";
      context += "1. Từ màn hình chính, nhấn nút + ở góc dưới phải màn hình\n";
      context += "2. Hoặc vào trang hồ sơ > Sản phẩm của tôi > nhấn nút 'Thêm sản phẩm'\n";
      context += "3. Điền thông tin sản phẩm: tên, mô tả, giá, danh mục, tình trạng\n";
      context += "4. Thêm hình ảnh cho sản phẩm\n";
      context += "5. Nhấn nút 'Đăng bán'\n\n";
      
      context += "Để quản lý sản phẩm đã đăng:\n";
      context += "1. Vào trang hồ sơ (tab cuối cùng ở thanh điều hướng dưới cùng)\n";
      context += "2. Chọn 'Sản phẩm của tôi'\n";
      context += "3. Tại đây, bạn có thể:\n";
      context += "   - Xem danh sách sản phẩm đã đăng\n";
      context += "   - Nhấn vào sản phẩm để xem chi tiết\n";
      context += "   - Nhấn nút 'Chỉnh sửa' để sửa thông tin sản phẩm\n";
      context += "   - Nhấn nút 'Xóa' để xóa sản phẩm\n";
      context += "   - Nhấn 'Đánh dấu đã bán' nếu sản phẩm đã được bán\n";
      context += "----------\n\n";
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