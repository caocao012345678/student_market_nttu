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

  /// Phương thức tạo phản hồi RAG và bổ sung thông tin sản phẩm nếu phát hiện
  Future<Map<String, dynamic>> generateRAGResponse(String query, {bool recordInteraction = true}) async {
    if (_disposed) return {'response': 'Service đã bị đóng', 'relevantDocsIds': []};
    
    if (_isProcessingQuery) {
      return {'response': 'Đang xử lý yêu cầu trước đó, vui lòng đợi...', 'relevantDocsIds': []};
    }
    
    try {
    _isProcessingQuery = true;
    _lastProcessedQuery = query;

      // Lớp Xử lý và Hiểu (Processing & Understanding Layer)
      final queryType = _analyzeQueryType(query);
      debugPrint('Loại truy vấn được phát hiện: ${queryType.toString()}');

      // Lớp Truy cập Thông tin và Kiến thức (Information & Knowledge Access Layer)
      final relevantDocs = await retrieveRelevantData(query);
      List<Map<String, dynamic>> productDetails = [];
      
      // Xử lý dữ liệu sản phẩm nếu có
      if (queryType == QueryType.product || query.toLowerCase().contains('mua') || query.toLowerCase().contains('sách')) {
        productDetails = await _fetchProductDetails(relevantDocs);
        debugPrint('Tìm thấy ${productDetails.length} sản phẩm liên quan');
      }
      
      // Chuẩn bị dữ liệu ngữ cảnh
      String context = '';
      List<String> relevantDocsIds = [];
      
      if (relevantDocs.isNotEmpty) {
        for (final doc in relevantDocs) {
          context += "--- ${doc['title'] ?? 'Thông tin'} ---\n";
          context += "${doc['content']}\n\n";
          
          if (doc['id'] != null) {
            relevantDocsIds.add(doc['id']);
          }
        }
      }
      
      // Lớp Tạo Phản hồi (Response Generation Layer)
      String productDetailsInfo = '';
      if (productDetails.isNotEmpty) {
        productDetailsInfo = 'DANH SÁCH SẢN PHẨM CHÍNH XÁC TỪ CƠ SỞ DỮ LIỆU:\n';
        for (var product in productDetails) {
          productDetailsInfo += """
- Tên sản phẩm: ${product['title']}
  Giá: ${product['price']}đ
  Mô tả: ${product['description']}
  Tình trạng: ${product['condition']}
  Người bán: ${product['seller']}
""";
        }
      }
      
      // Tạo hướng dẫn dựa trên loại truy vấn
      String typeSpecificInstructions = '';
      if (queryType == QueryType.product) {
        typeSpecificInstructions = """
TRẢ LỜI VỀ SẢN PHẨM - YÊU CẦU CHÍNH XÁC CAO:
1. CHỈ đề cập đến các sản phẩm trong danh sách bên trên. KHÔNG BAO GIỜ đề cập hoặc đưa thông tin về sản phẩm không có trong danh sách.
2. KHÔNG tạo ra sản phẩm mới, giá cả khác, hoặc bất kỳ thuộc tính nào khác với dữ liệu đã cung cấp.
3. Nếu không có sản phẩm nào trong danh sách, hãy nói rõ "Hiện tại chưa có sản phẩm phù hợp với yêu cầu của bạn trong hệ thống" và đề xuất danh mục hoặc từ khóa tìm kiếm khác.
4. Không bao giờ sử dụng kiến thức bên ngoài về sản phẩm; CHỈ dùng dữ liệu từ danh sách đã cung cấp.
5. Khuyến khích người dùng nhấp vào thẻ sản phẩm để xem chi tiết.
""";
      } else if (queryType == QueryType.appUsage) {
        typeSpecificInstructions = """
TRẢ LỜI VỀ CÁCH SỬ DỤNG ỨNG DỤNG:
1. Cung cấp hướng dẫn cụ thể, chi tiết và dễ làm theo.
2. Mô tả từng bước với giao diện người dùng (nút bấm, menu, v.v.).
3. Nêu rõ các lựa chọn thay thế nếu có.
4. CHỈ sử dụng thông tin về tính năng có trong ứng dụng, không đề cập đến tính năng không tồn tại.
""";
      } else {
        typeSpecificInstructions = """
LƯU Ý QUAN TRỌNG CHO MỌI LOẠI CÂU TRẢ LỜI:
1. CHỈ sử dụng thông tin đã cung cấp, KHÔNG tạo ra thông tin mới.
2. KHÔNG đưa ra thông tin về sản phẩm, danh mục, hoặc tính năng nếu không được đề cập trong ngữ cảnh.
3. Nếu không có thông tin, hãy thành thật nói rằng "Tôi không có thông tin về điều đó trong hệ thống" thay vì tạo ra câu trả lời không chính xác.
""";
      }
      
      // Vòng lặp cải thiện câu trả lời
      String response = '';
      int attemptCount = 0;
      const maxAttempts = 3; // Giới hạn số lần thử cải thiện câu trả lời
      double responseScore = 0;
      Map<String, dynamic> evaluationResult = {};
      
      // Thực hiện vòng lặp cải thiện câu trả lời
      while (attemptCount < maxAttempts) {
        // Xây dựng prompt dựa trên kết quả đánh giá trước đó (nếu có)
        String additionalGuidance = '';
        if (attemptCount > 0 && evaluationResult.isNotEmpty) {
          additionalGuidance = """
HƯỚNG DẪN CẢI THIỆN:
- ${evaluationResult['feedbackPoints'].join('\n- ')}
""";
        }
        
        // Danh sách chính xác các tên sản phẩm để kiểm tra hallucination
        final List<String> exactProductNames = productDetails.map((p) => p['title'].toString()).toList();
        final String exactProductsList = exactProductNames.isEmpty ? "KHÔNG CÓ SẢN PHẨM NÀO TRONG HỆ THỐNG PHÙ HỢP VỚI YÊU CẦU" 
                                                                  : exactProductNames.map((name) => "- $name").join("\n");
        
        // Xây dựng prompt mạnh mẽ hơn với cảnh báo về hallucination
        final ragPrompt = """
Bạn là trợ lý ảo Student Market NTTU, một ứng dụng mua bán dành cho sinh viên. Hãy trả lời dựa NGHIÊM NGẶT vào thông tin dưới đây.

THÔNG TIN TỪ CƠ SỞ DỮ LIỆU:
$context

${productDetails.isNotEmpty ? productDetailsInfo : 'KHÔNG CÓ SẢN PHẨM NÀO PHÙ HỢP TRONG HỆ THỐNG.'}

DANH SÁCH CHÍNH XÁC CÁC SẢN PHẨM THỰC:
$exactProductsList

CẢNH BÁO VỀ HALLUCINATION:
- BẠN CHỈ ĐƯỢC PHÉP ĐỀ CẬP ĐẾN CÁC SẢN PHẨM CÓ TRONG DANH SÁCH CHÍNH XÁC TRÊN.
- TUYỆT ĐỐI KHÔNG ĐƯỢC TẠO RA THÔNG TIN VỀ SẢN PHẨM KHÔNG CÓ TRONG DANH SÁCH.
- KHÔNG ĐƯỢC THÊM GIÁ, MÔ TẢ HOẶC THUỘC TÍNH KHÁC SO VỚI DỮ LIỆU ĐÃ CUNG CẤP.

CHỈ DẪN CHO CÂU TRẢ LỜI:
1. Phản hồi phải đầy đủ, chính xác và giải quyết trực tiếp câu hỏi của người dùng.
2. Văn phong thân thiện, chuyên nghiệp và trả lời ngắn gọn, súc tích.
3. Nếu không có thông tin cụ thể, thừa nhận điều đó và đề xuất cách tìm hiểu thêm.
4. Thông tin phải nhất quán và KHÔNG được tạo ra, hãy nói "Hiện tại chưa có sản phẩm phù hợp" nếu không có sản phẩm.

YÊU CẦU VỀ TÍNH LỊCH SỰ VÀ CHUYÊN NGHIỆP:
- Luôn sử dụng ngôn từ lịch sự, tôn trọng người dùng
- Thể hiện sự chuyên nghiệp và thân thiện trong cách trả lời
- Đề xuất giải pháp hữu ích khi không có đủ thông tin
- Tránh sử dụng từ ngữ tiêu cực hoặc đổ lỗi
- Cấu trúc câu trả lời rõ ràng, dễ hiểu

$typeSpecificInstructions

$additionalGuidance

CÂU HỎI CỦA NGƯỜI DÙNG: "$query"

Cung cấp câu trả lời chính xác, đáng tin cậy và hữu ích nhất có thể, CHỈ sử dụng dữ liệu đã cung cấp.
""";
        
        // Gửi prompt đến Gemini API để tạo phản hồi
        response = await _geminiService.sendMessageWithContext(ragPrompt, query);
        
        // Kiểm tra hallucination trong câu trả lời
        bool hasHallucination = await _checkForHallucination(response, productDetails);
        
        if (hasHallucination) {
          debugPrint('Phát hiện hallucination trong câu trả lời, thử lại...');
          
          // Thêm cảnh báo vào feedbackPoints
          if (evaluationResult.isEmpty) {
            evaluationResult = {
              'score': 0.0,
              'feedbackPoints': [
                'CẢNH BÁO: Câu trả lời có chứa thông tin về sản phẩm không tồn tại trong hệ thống',
                'Chỉ đề cập đến các sản phẩm trong danh sách đã cung cấp',
                'Không được tạo ra thông tin mới hoặc giá cả khác với dữ liệu thực tế'
              ]
            };
          } else {
            evaluationResult['feedbackPoints'].insert(0, 'CẢNH BÁO: Câu trả lời vẫn chứa thông tin về sản phẩm không tồn tại');
            evaluationResult['score'] = 0.0;
          }
          
          attemptCount++;
          continue;
        }
        
        // Đánh giá phản hồi
        evaluationResult = await _evaluateResponse(response, query, productDetails, context);
        responseScore = evaluationResult['score'];
        print(ragPrompt);
        
        debugPrint('Đánh giá câu trả lời (lần $attemptCount): $responseScore/10');
        
        // Nếu câu trả lời đủ tốt, thoát khỏi vòng lặp
        if (responseScore >= 7.5 || attemptCount == maxAttempts - 1) {
          break;
        }
        
        attemptCount++;
      }
      
      // Lớp Đầu ra & Định dạng (Output & Formatting Layer)
      final formattedResponse = _formatResponse(response, productDetails);
      
      // Lưu tương tác nếu cần
      if (recordInteraction) {
        _recordInteraction(query, formattedResponse, relevantDocs.length, relevantDocsIds);
      }
      
      _isProcessingQuery = false;
      
      // Trả về kết quả bao gồm phản hồi, ID tài liệu liên quan và thông tin sản phẩm
      return {
        'response': formattedResponse,
        'relevantDocsIds': relevantDocsIds,
        'productDetails': productDetails,
        'queryType': queryType.toString().split('.').last,
        'responseScore': responseScore,
        'improvementAttempts': attemptCount
      };
    } catch (e) {
      debugPrint('Lỗi RAG: $e');
      _isProcessingQuery = false;
      return {'response': 'Đã xảy ra lỗi khi xử lý truy vấn: $e', 'relevantDocsIds': []};
    }
  }
  
  /// Kiểm tra hallucination trong câu trả lời
  Future<bool> _checkForHallucination(String response, List<Map<String, dynamic>> productDetails) async {
    try {
      // Nếu không có sản phẩm, nhưng câu trả lời đề cập đến sản phẩm
      if (productDetails.isEmpty) {
        final mentionsProduct = response.toLowerCase().contains('sản phẩm') &&
                              (response.contains('đ') || response.contains('VND') || response.contains('VNĐ'));
        
        if (mentionsProduct) {
          return true; // Có hallucination vì không có sản phẩm thực nào
        }
      } else {
        // Tạo danh sách tên, giá và thuộc tính sản phẩm thực
        final realProductNames = productDetails.map((p) => p['title'].toString().toLowerCase()).toList();
        final realProductPrices = productDetails.map((p) => p['price'].toString()).toList();
        
        // Tạo prompt để kiểm tra hallucination
        final checkPrompt = """
Dưới đây là danh sách các sản phẩm THỰC có trong hệ thống:
${productDetails.map((p) => "- ${p['title']} (${p['price']}đ)").join('\n')}

Đây là câu trả lời của chatbot cho người dùng:
"$response"

NHIỆM VỤ: Kiểm tra xem câu trả lời có đề cập đến sản phẩm KHÔNG CÓ trong danh sách không.
Chỉ phản hồi "CÓ" hoặc "KHÔNG" dựa trên phân tích sau:
1. Nếu câu trả lời đề cập đến sản phẩm (tên hoặc mô tả) không có trong danh sách => "CÓ"
2. Nếu câu trả lời đề cập đến giá khác với giá trong danh sách => "CÓ"
3. Nếu câu trả lời chỉ đề cập đến sản phẩm có trong danh sách với giá chính xác => "KHÔNG"
4. Nếu câu trả lời không đề cập đến bất kỳ sản phẩm cụ thể nào => "KHÔNG"
""";

        final checkResponse = await _geminiService.sendMessageWithContext(checkPrompt, "Kiểm tra tính chính xác");
        
        // Phân tích kết quả kiểm tra
        return checkResponse.trim().toUpperCase().contains('CÓ');
      }
      
      return false;
    } catch (e) {
      debugPrint('Lỗi khi kiểm tra hallucination: $e');
      return false; // Mặc định là không có hallucination nếu có lỗi
    }
  }

  /// Đánh giá chất lượng câu trả lời
  Future<Map<String, dynamic>> _evaluateResponse(
    String response, 
    String query, 
    List<Map<String, dynamic>> productDetails,
    String context
  ) async {
    try {
      // Tạo prompt đánh giá
      final evaluationPrompt = """
Hãy đánh giá chất lượng câu trả lời dưới đây dựa trên các tiêu chí sau:
1. Mức độ giải quyết câu hỏi (0-2 điểm): Câu trả lời có giải quyết trực tiếp vấn đề người dùng hỏi không?
2. Tính chính xác (0-2 điểm): Thông tin trong câu trả lời có chính xác không?
3. Đầy đủ thông tin (0-1.5 điểm): Câu trả lời có cung cấp đầy đủ thông tin liên quan không?
4. Tính lịch sự và chuyên nghiệp (0-2.5 điểm): Câu trả lời có lịch sự, tôn trọng và chuyên nghiệp không? Ngôn ngữ có phù hợp với một trợ lý ảo chất lượng cao?
5. Tính nhất quán (0-2 điểm): Có mâu thuẫn giữa các phần trong câu trả lời không?

TIÊU CHÍ CHI TIẾT VỀ TÍNH LỊCH SỰ VÀ CHUYÊN NGHIỆP (0-2.5 điểm):
- Câu trả lời sử dụng ngôn từ lịch sự, tôn trọng người dùng (0-0.5)
- Ngữ điệu chuyên nghiệp, thân thiện nhưng không quá thân mật (0-0.5)
- Không chứa ngôn từ thô lỗ, mỉa mai hoặc tiêu cực (0-0.5)
- Đưa ra gợi ý hữu ích và thể hiện sự quan tâm đến người dùng (0-0.5)
- Cấu trúc câu và đoạn văn rõ ràng, mạch lạc (0-0.5)

CÂU HỎI CỦA NGƯỜI DÙNG: "$query"

CÂU TRẢ LỜI CẦN ĐÁNH GIÁ:
"$response"

${productDetails.isNotEmpty ? 'LƯU Ý: Câu trả lời phải đề cập đến các sản phẩm sau:\n' + productDetails.map((p) => '- ${p['title']}').join('\n') : ''}

Phân tích kỹ từng tiêu chí và chấm điểm cụ thể. Phản hồi theo định dạng:
- Điểm giải quyết câu hỏi: [điểm/2]
- Điểm tính chính xác: [điểm/2]
- Điểm đầy đủ thông tin: [điểm/1.5]
- Điểm tính lịch sự và chuyên nghiệp: [điểm/2.5]
- Điểm tính nhất quán: [điểm/2]
- Tổng điểm: [tổng/10]
- Điểm mạnh:
  - [điểm mạnh 1]
  - [điểm mạnh 2]
- Điểm yếu:
  - [điểm yếu 1]
  - [điểm yếu 2] 
- Gợi ý cải thiện:
  - [gợi ý 1]
  - [gợi ý 2]
  - [gợi ý cải thiện tính lịch sự nếu cần]
""";

      // Gửi đến Gemini để đánh giá
      final evaluationResponse = await _geminiService.sendMessageWithContext(evaluationPrompt, "Đánh giá chất lượng");
      
      // Phân tích kết quả đánh giá
      double score = 0;
      final RegExp scoreRegex = RegExp(r'Tổng điểm: (\d+(\.\d+)?)/10');
      final scoreMatch = scoreRegex.firstMatch(evaluationResponse);
      
      if (scoreMatch != null && scoreMatch.groupCount >= 1) {
        score = double.tryParse(scoreMatch.group(1) ?? '0') ?? 0;
      }
      
      // Trích xuất các điểm yếu và gợi ý cải thiện
      final List<String> feedbackPoints = [];
      
      // Tìm phần gợi ý cải thiện
      final RegExp suggestionRegex = RegExp(r'Gợi ý cải thiện:(.*?)(?=\n\n|$)', dotAll: true);
      final suggestionMatch = suggestionRegex.firstMatch(evaluationResponse);
      
      if (suggestionMatch != null) {
        final suggestions = suggestionMatch.group(1) ?? '';
        final bulletPoints = suggestions.split('\n').where((line) => line.trim().startsWith('-')).toList();
        feedbackPoints.addAll(bulletPoints.map((point) => point.replaceFirst('-', '').trim()));
      }
      
      // Tìm phần điểm yếu
      final RegExp weaknessRegex = RegExp(r'Điểm yếu:(.*?)(?=\n\n|- Gợi ý cải thiện|$)', dotAll: true);
      final weaknessMatch = weaknessRegex.firstMatch(evaluationResponse);
      
      if (weaknessMatch != null) {
        final weaknesses = weaknessMatch.group(1) ?? '';
        final bulletPoints = weaknesses.split('\n').where((line) => line.trim().startsWith('-')).toList();
        
        // Thêm các điểm yếu không trùng với gợi ý cải thiện
        for (var point in bulletPoints) {
          final cleanPoint = point.replaceFirst('-', '').trim();
          if (!feedbackPoints.contains(cleanPoint)) {
            feedbackPoints.add(cleanPoint);
          }
        }
      }
      
      return {
        'score': score,
        'feedbackPoints': feedbackPoints,
        'fullEvaluation': evaluationResponse,
      };
    } catch (e) {
      debugPrint('Lỗi khi đánh giá câu trả lời: $e');
      return {
        'score': 5.0, // Điểm mặc định nếu có lỗi
        'feedbackPoints': ['Cung cấp câu trả lời chính xác, đầy đủ và lịch sự hơn'],
        'fullEvaluation': 'Lỗi đánh giá: $e',
      };
    }
  }
  
  /// Định dạng câu trả lời cuối cùng để đảm bảo chất lượng
  String _formatResponse(String originalResponse, List<Map<String, dynamic>> productDetails) {
    // Xóa bỏ các ký tự định dạng thừa như **, *, #, - nếu có
    var response = originalResponse
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'')
        .replaceAll(RegExp(r'\*(.*?)\*'), r'');
        
    // Nếu phản hồi vẫn nói không có thông tin về sản phẩm trong khi có sản phẩm
    if (productDetails.isNotEmpty && 
        (response.contains('chưa có thông tin') || 
         response.contains('không có thông tin') ||
         response.contains('tôi không biết'))) {
      
      // Thay thế bằng phản hồi mẫu chứa thông tin sản phẩm
      response = 'Tôi đã tìm thấy một số sản phẩm phù hợp với yêu cầu của bạn:\n\n';
      
      for (var product in productDetails) {
        response += '- ${product['title']} (${product['price']}đ): ${product['description']}\n';
        if (product['condition'] != null && product['condition'].toString().isNotEmpty) {
          response += '  Tình trạng: ${product['condition']}\n';
        }
      }
      
      response += '\nBạn có thể nhấp vào thẻ sản phẩm bên trên để xem thông tin chi tiết và liên hệ với người bán.';
    }
    
    return response;
  }

  /// Phương thức lấy chi tiết sản phẩm từ danh sách tài liệu liên quan
  Future<List<Map<String, dynamic>>> _fetchProductDetails(List<Map<String, dynamic>> relevantDocs) async {
    List<Map<String, dynamic>> productDetails = [];
    
    try {
      // Tìm các ID sản phẩm từ kết quả tìm kiếm
      List<String> productIds = [];
      
      for (var doc in relevantDocs) {
        // Kiểm tra xem tài liệu có phải là sản phẩm không
        if (doc['type'] == 'product' && doc['id'] != null) {
          productIds.add(doc['id']);
        }
        
        // Hoặc kiểm tra trong nội dung xem có chứa ID sản phẩm không (trường hợp ID có trong content)
        if (doc['content'] != null) {
          final RegExp productIdRegex = RegExp(r'product_id[:\s]+"?([a-zA-Z0-9]+)"?');
          final matches = productIdRegex.allMatches(doc['content']);
          
          for (final match in matches) {
            if (match.groupCount >= 1) {
              productIds.add(match.group(1)!);
            }
          }
        }
      }
      
      // Lọc bỏ trùng lặp
      productIds = productIds.toSet().toList();
      
      // Giới hạn số lượng sản phẩm trả về (tối đa 3)
      if (productIds.length > 3) {
        productIds = productIds.sublist(0, 3);
      }
      
      // Lấy thông tin chi tiết sản phẩm từ Firestore
      for (var productId in productIds) {
        try {
          final productDoc = await _firestore.collection('products').doc(productId).get();
          
          if (productDoc.exists) {
            final data = productDoc.data()!;
            
            // Tạo một object chứa thông tin cần thiết cho product card
            productDetails.add({
              'id': productId,
              'title': data['title'] ?? 'Sản phẩm không có tiêu đề',
              'price': data['price'] ?? 0.0,
              'images': List<String>.from(data['images'] ?? []),
              'description': data['description'] ?? '',
              'category': data['category'] ?? '',
              'seller': data['sellerName'] ?? 'Không rõ người bán',
              'sellerId': data['sellerId'] ?? '',
              'condition': data['condition'] ?? 'Không rõ',
              'createdAt': data['createdAt'] != null 
                  ? (data['createdAt'] as Timestamp).toDate().toString() 
                  : DateTime.now().toString(),
            });
          }
        } catch (e) {
          debugPrint('Lỗi khi lấy thông tin sản phẩm $productId: $e');
        }
      }
    } catch (e) {
      debugPrint('Lỗi khi truy xuất chi tiết sản phẩm: $e');
    }
    
    return productDetails;
  }

  /// Ghi lại tương tác của người dùng
  Future<void> _recordInteraction(String query, String response, int docsCount, List<String> relevantDocsIds) async {
    try {
      // Tạo dữ liệu về tương tác
      final interaction = {
        'query': query,
        'response': response,
        'timestamp': FieldValue.serverTimestamp(),
        'relevantDocsCount': docsCount,
        'relevantDocsIds': relevantDocsIds,
        'queryType': _analyzeQueryType(query).toString().split('.').last,
      };
      
      // Lưu vào Firestore
      await _firestore.collection('rag_interactions').add(interaction);
      
      // Nếu không có kết quả phù hợp, lưu vào danh sách truy vấn cần cải thiện
      if (docsCount < 2) {
        await _firestore.collection('queries_to_improve').add({
          'query': query,
          'timestamp': FieldValue.serverTimestamp(),
          'relevantDocsCount': docsCount,
          'status': 'pending'
        });
      }
    } catch (e) {
      debugPrint('Lỗi khi ghi lại tương tác: $e');
    }
  }
}

/// Enum xác định loại truy vấn
enum QueryType {
  product,    // Liên quan đến sản phẩm
  category,   // Liên quan đến danh mục
  appUsage,   // Liên quan đến cách sử dụng
  general,    // Truy vấn chung
} 