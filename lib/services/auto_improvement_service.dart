import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_market_nttu/services/gemini_service.dart';
import 'package:student_market_nttu/services/app_layout_service.dart';

/// Service tự động cải thiện dữ liệu dựa trên tương tác người dùng
class AutoImprovementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GeminiService _geminiService;
  final AppLayoutService _appLayoutService;
  
  // Cờ để kiểm soát quá trình tự động cải thiện
  bool _isImprovementRunning = false;
  Timer? _improvementTimer;
  
  AutoImprovementService(this._geminiService, this._appLayoutService);
  
  /// Khởi động quá trình tự động cải thiện dữ liệu
  void startAutoImprovement({Duration interval = const Duration(hours: 24)}) {
    // Hủy timer hiện tại nếu có
    _improvementTimer?.cancel();
    
    // Chạy cải thiện ngay lập tức
    _runImprovement();
    
    // Thiết lập timer để chạy cải thiện định kỳ
    _improvementTimer = Timer.periodic(interval, (_) {
      _runImprovement();
    });
  }
  
  /// Dừng quá trình tự động cải thiện
  void stopAutoImprovement() {
    _improvementTimer?.cancel();
    _improvementTimer = null;
  }
  
  /// Tiến hành cải thiện dữ liệu
  Future<void> _runImprovement() async {
    if (_isImprovementRunning) {
      debugPrint('Quá trình cải thiện đang chạy, bỏ qua lần chạy này');
      return;
    }
    
    _isImprovementRunning = true;
    debugPrint('Bắt đầu quá trình tự động cải thiện dữ liệu');
    
    try {
      // Phân tích các câu truy vấn cần cải thiện
      await _processQueriesToImprove();
      
      // Phân tích các tương tác để tìm xu hướng
      await _analyzeInteractions();
      
      // Tạo các tác vụ người dùng mới dựa trên dữ liệu tương tác
      await _generateNewUserTasks();
      
      // Tạo các cải thiện mô tả tính năng
      await _improveFeatureDescriptions();
      
      debugPrint('Hoàn thành quá trình tự động cải thiện dữ liệu');
    } catch (e) {
      debugPrint('Lỗi trong quá trình tự động cải thiện: $e');
    } finally {
      _isImprovementRunning = false;
    }
  }
  
  /// Xử lý các truy vấn cần cải thiện
  Future<void> _processQueriesToImprove() async {
    // Lấy các truy vấn có trạng thái "pending"
    final querySnapshot = await _firestore
        .collection('queries_to_improve')
        .where('status', isEqualTo: 'pending')
        .limit(10)
        .get();
    
    if (querySnapshot.docs.isEmpty) {
      debugPrint('Không có truy vấn nào cần cải thiện');
      return;
    }
    
    for (var doc in querySnapshot.docs) {
      final query = doc.data()['query'] as String;
      debugPrint('Đang xử lý truy vấn cần cải thiện: $query');
      
      try {
        // Phân tích truy vấn để tạo tác vụ người dùng mới
        final systemPrompt = '''
        Hãy phân tích câu truy vấn này và đề xuất cải thiện cho dữ liệu ứng dụng.
        
        Nhiệm vụ của bạn: 
        1. Xác định xem câu hỏi liên quan đến tính năng nào của ứng dụng
        2. Đề xuất 2-5 cách diễn đạt mới mà người dùng có thể sử dụng để hỏi cùng một thông tin
        3. Đề xuất các từ khóa chính liên quan đến câu hỏi này
        
        Trả về kết quả dưới dạng JSON với cấu trúc:
        {
          "related_feature": "tên_tính_năng",
          "alternative_phrases": ["cách diễn đạt 1", "cách diễn đạt 2", ...],
          "keywords": ["từ khóa 1", "từ khóa 2", ...]
        }
        ''';
        
        final response = await _geminiService.sendPromptedMessage(
          systemPrompt, 
          query,
          addToHistory: false
        );
        
        // Cập nhật trạng thái
        await doc.reference.update({
          'status': 'processed',
          'analysis_result': response,
          'processed_at': FieldValue.serverTimestamp()
        });
        
        // Thử trích xuất kết quả JSON và áp dụng cải thiện
        try {
          await _applyQueryImprovement(query, response);
        } catch (e) {
          debugPrint('Lỗi khi áp dụng cải thiện: $e');
        }
      } catch (e) {
        debugPrint('Lỗi khi xử lý truy vấn cần cải thiện: $e');
        await doc.reference.update({
          'status': 'error',
          'error_message': e.toString(),
          'processed_at': FieldValue.serverTimestamp()
        });
      }
      
      // Đợi một khoảng thời gian để tránh quá tải API
      await Future.delayed(const Duration(seconds: 2));
    }
  }
  
  /// Áp dụng cải thiện từ kết quả phân tích truy vấn
  Future<void> _applyQueryImprovement(String query, String analysisResult) async {
    // Cố gắng trích xuất JSON từ kết quả
    try {
      final resultJson = _extractJsonFromText(analysisResult);
      if (resultJson == null) {
        debugPrint('Không thể trích xuất JSON từ kết quả phân tích');
        return;
      }
      
      final relatedFeature = resultJson['related_feature'] as String?;
      final alternativePhrases = resultJson['alternative_phrases'] as List<dynamic>?;
      final keywords = resultJson['keywords'] as List<dynamic>?;
      
      if (relatedFeature == null || alternativePhrases == null || keywords == null) {
        debugPrint('Dữ liệu JSON không đầy đủ để áp dụng cải thiện');
        return;
      }
      
      // Tìm tính năng liên quan
      final features = _appLayoutService.appFeatures;
      int featureIndex = -1;
      
      for (int i = 0; i < features.length; i++) {
        if (features[i]['id'] == relatedFeature || 
            features[i]['name'].toString().toLowerCase().contains(relatedFeature.toLowerCase())) {
          featureIndex = i;
          break;
        }
      }
      
      if (featureIndex == -1) {
        debugPrint('Không tìm thấy tính năng liên quan: $relatedFeature');
        return;
      }
      
      // Cập nhật user_tasks với các cách diễn đạt mới
      await _updateFeatureUserTasks(featureIndex, alternativePhrases.cast<String>());
      
      // Lưu phân tích này để sử dụng sau
      await _firestore.collection('auto_improvements').add({
        'original_query': query,
        'related_feature': relatedFeature,
        'alternative_phrases': alternativePhrases,
        'keywords': keywords,
        'created_at': FieldValue.serverTimestamp(),
        'applied': true
      });
    } catch (e) {
      debugPrint('Lỗi khi áp dụng cải thiện truy vấn: $e');
    }
  }
  
  /// Cập nhật user_tasks của tính năng
  Future<void> _updateFeatureUserTasks(int featureIndex, List<String> newTasks) async {
    try {
      // Lấy danh sách user_tasks hiện tại
      final currentTasks = List<String>.from(_appLayoutService.appFeatures[featureIndex]['user_tasks'] ?? []);
      
      // Thêm các tác vụ mới nếu chưa có
      for (var task in newTasks) {
        if (!currentTasks.contains(task)) {
          currentTasks.add(task);
        }
      }
      
      // Cập nhật danh sách tác vụ
      await _firestore.collection('app_settings').doc('layout').update({
        'app_features.$featureIndex.user_tasks': currentTasks
      });
      
      debugPrint('Đã cập nhật user_tasks cho tính năng: ${_appLayoutService.appFeatures[featureIndex]['name']}');
    } catch (e) {
      debugPrint('Lỗi khi cập nhật user_tasks: $e');
    }
  }
  
  /// Phân tích các tương tác để tìm xu hướng
  Future<void> _analyzeInteractions() async {
    // Lấy 100 tương tác gần nhất
    final querySnapshot = await _firestore
        .collection('rag_interactions')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .get();
    
    if (querySnapshot.docs.isEmpty) {
      debugPrint('Không có tương tác nào để phân tích');
      return;
    }
    
    // Tập hợp các truy vấn và phản hồi
    final List<Map<String, dynamic>> interactions = [];
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      interactions.add({
        'query': data['query'],
        'response': data['response'],
        'relevantDocsCount': data['relevantDocsCount'] ?? 0
      });
    }
    
    // Đề xuất cải thiện dựa trên các tương tác
    final systemPrompt = '''
    Hãy phân tích các tương tác người dùng sau đây và đề xuất cải thiện cho dữ liệu ứng dụng.
    
    Nhiệm vụ của bạn:
    1. Xác định các xu hướng trong truy vấn người dùng
    2. Xác định các loại truy vấn thường xuyên
    3. Đề xuất cách cải thiện dữ liệu để đáp ứng tốt hơn các truy vấn này
    
    Tập trung vào các truy vấn có ít tài liệu liên quan (relevantDocsCount thấp).
    
    Trả về kết quả dưới dạng JSON với cấu trúc:
    {
      "trends": ["xu hướng 1", "xu hướng 2", ...],
      "common_queries": ["loại truy vấn 1", "loại truy vấn 2", ...],
      "improvement_suggestions": [
        {
          "query_type": "loại truy vấn",
          "suggestions": ["đề xuất 1", "đề xuất 2", ...]
        },
        ...
      ]
    }
    ''';
    
    try {
      final interactionsText = interactions.map((e) => 
        "Query: ${e['query']}\nResponse: ${e['response']}\nRelevantDocsCount: ${e['relevantDocsCount']}"
      ).join("\n\n");
      
      final response = await _geminiService.sendPromptedMessage(
        systemPrompt, 
        interactionsText,
        addToHistory: false
      );
      
      // Lưu kết quả phân tích
      await _firestore.collection('interaction_analysis').add({
        'analysis_result': response,
        'interactions_count': interactions.length,
        'created_at': FieldValue.serverTimestamp()
      });
      
      // Cố gắng áp dụng các đề xuất cải thiện
      try {
        await _applyInteractionAnalysisImprovements(response);
      } catch (e) {
        debugPrint('Lỗi khi áp dụng cải thiện từ phân tích tương tác: $e');
      }
    } catch (e) {
      debugPrint('Lỗi khi phân tích tương tác: $e');
    }
  }
  
  /// Áp dụng cải thiện từ phân tích tương tác
  Future<void> _applyInteractionAnalysisImprovements(String analysisResult) async {
    try {
      final resultJson = _extractJsonFromText(analysisResult);
      if (resultJson == null) {
        debugPrint('Không thể trích xuất JSON từ kết quả phân tích tương tác');
        return;
      }
      
      final improvementSuggestions = resultJson['improvement_suggestions'] as List<dynamic>?;
      if (improvementSuggestions == null) {
        debugPrint('Không có đề xuất cải thiện trong kết quả phân tích');
        return;
      }
      
      // Cập nhật Firestore với các gợi ý
      for (var suggestion in improvementSuggestions) {
        final queryType = suggestion['query_type'] as String?;
        final suggestions = suggestion['suggestions'] as List<dynamic>?;
        
        if (queryType != null && suggestions != null) {
          await _firestore.collection('improvement_suggestions').add({
            'query_type': queryType,
            'suggestions': suggestions,
            'created_at': FieldValue.serverTimestamp(),
            'status': 'pending'
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi khi áp dụng cải thiện từ phân tích tương tác: $e');
    }
  }
  
  /// Tạo các tác vụ người dùng mới dựa trên dữ liệu tương tác
  Future<void> _generateNewUserTasks() async {
    // Lấy các từ khóa truy vấn phổ biến
    final querySnapshot = await _firestore
        .collection('rag_interactions')
        .orderBy('timestamp', descending: true)
        .limit(200)
        .get();
    
    if (querySnapshot.docs.isEmpty) return;
    
    final List<String> queries = [];
    for (var doc in querySnapshot.docs) {
      queries.add(doc.data()['query'] as String);
    }
    
    // Tạo prompt để phân tích và tạo user tasks
    final systemPrompt = '''
    Hãy phân tích các truy vấn người dùng sau đây và tạo ra các tác vụ người dùng phù hợp.
    
    Nhiệm vụ của bạn:
    1. Nhóm các truy vấn tương tự
    2. Tạo ra các tác vụ người dùng đại diện cho từng nhóm
    3. Gán mỗi tác vụ cho một tính năng phù hợp
    
    Danh sách tính năng:
    - product_search: Tìm kiếm sản phẩm
    - add_to_cart: Thêm vào giỏ hàng
    - chat_with_seller: Trò chuyện với người bán
    - add_product: Đăng bán sản phẩm
    - manage_products: Quản lý sản phẩm đã đăng
    - favorite_product: Yêu thích sản phẩm
    - checkout: Thanh toán
    - view_orders: Xem đơn hàng
    - edit_profile: Chỉnh sửa hồ sơ
    - activate_darkmode: Chế độ tối
    - rate_product: Đánh giá sản phẩm
    
    Trả về kết quả dưới dạng JSON với cấu trúc:
    {
      "user_tasks": [
        {
          "feature_id": "id của tính năng",
          "tasks": ["tác vụ 1", "tác vụ 2", ...]
        },
        ...
      ]
    }
    ''';
    
    try {
      final response = await _geminiService.sendPromptedMessage(
        systemPrompt, 
        queries.join("\n"),
        addToHistory: false
      );
      
      // Cố gắng áp dụng các tác vụ mới
      try {
        await _applyNewUserTasks(response);
      } catch (e) {
        debugPrint('Lỗi khi áp dụng tác vụ người dùng mới: $e');
      }
      
      // Lưu kết quả phân tích
      await _firestore.collection('user_tasks_generation').add({
        'analysis_result': response,
        'queries_count': queries.length,
        'created_at': FieldValue.serverTimestamp()
      });
    } catch (e) {
      debugPrint('Lỗi khi tạo tác vụ người dùng mới: $e');
    }
  }
  
  /// Áp dụng tác vụ người dùng mới
  Future<void> _applyNewUserTasks(String result) async {
    try {
      final resultJson = _extractJsonFromText(result);
      if (resultJson == null) {
        debugPrint('Không thể trích xuất JSON từ kết quả tác vụ người dùng');
        return;
      }
      
      final userTasks = resultJson['user_tasks'] as List<dynamic>?;
      if (userTasks == null) {
        debugPrint('Không có tác vụ người dùng trong kết quả');
        return;
      }
      
      // Áp dụng các tác vụ mới cho từng tính năng
      for (var taskGroup in userTasks) {
        final featureId = taskGroup['feature_id'] as String?;
        final tasks = taskGroup['tasks'] as List<dynamic>?;
        
        if (featureId != null && tasks != null) {
          // Tìm tính năng trong appFeatures
          final features = _appLayoutService.appFeatures;
          int featureIndex = -1;
          
          for (int i = 0; i < features.length; i++) {
            if (features[i]['id'] == featureId) {
              featureIndex = i;
              break;
            }
          }
          
          if (featureIndex != -1) {
            await _updateFeatureUserTasks(featureIndex, tasks.cast<String>());
          }
        }
      }
    } catch (e) {
      debugPrint('Lỗi khi áp dụng tác vụ người dùng mới: $e');
    }
  }
  
  /// Cải thiện mô tả tính năng
  Future<void> _improveFeatureDescriptions() async {
    final features = _appLayoutService.appFeatures;
    
    // Chọn một số tính năng để cải thiện mô tả
    final featuresToImprove = features.take(3).toList();
    
    for (var feature in featuresToImprove) {
      try {
        final systemPrompt = '''
        Hãy cải thiện mô tả cho tính năng này để giúp người dùng hiểu rõ hơn.
        
        Tính năng: ${feature['name']}
        Mô tả hiện tại: ${feature['description']}
        Vị trí: ${feature['location']}
        Cách sử dụng: ${feature['usage']}
        
        Nhiệm vụ của bạn:
        1. Tạo một mô tả mới chi tiết hơn
        2. Tạo hướng dẫn sử dụng cụ thể và rõ ràng hơn
        
        Lưu ý: Mô tả phải ngắn gọn, dễ hiểu nhưng thông tin đầy đủ hơn.
        
        Trả về kết quả dưới dạng JSON với cấu trúc:
        {
          "improved_description": "mô tả mới",
          "improved_usage": "hướng dẫn sử dụng mới"
        }
        ''';
        
        final response = await _geminiService.sendPromptedMessage(
          systemPrompt, 
          "Cải thiện mô tả cho tính năng ${feature['name']}",
          addToHistory: false
        );
        
        // Cố gắng áp dụng mô tả mới
        try {
          await _applyImprovedDescription(feature['id'] as String, response);
        } catch (e) {
          debugPrint('Lỗi khi áp dụng mô tả cải thiện: $e');
        }
        
        // Đợi một khoảng thời gian để tránh quá tải API
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        debugPrint('Lỗi khi cải thiện mô tả tính năng: $e');
      }
    }
  }
  
  /// Áp dụng mô tả cải thiện
  Future<void> _applyImprovedDescription(String featureId, String result) async {
    try {
      final resultJson = _extractJsonFromText(result);
      if (resultJson == null) {
        debugPrint('Không thể trích xuất JSON từ kết quả mô tả cải thiện');
        return;
      }
      
      final improvedDescription = resultJson['improved_description'] as String?;
      final improvedUsage = resultJson['improved_usage'] as String?;
      
      if (improvedDescription == null && improvedUsage == null) {
        debugPrint('Không có mô tả cải thiện trong kết quả');
        return;
      }
      
      // Tìm tính năng trong appFeatures
      final features = _appLayoutService.appFeatures;
      int featureIndex = -1;
      
      for (int i = 0; i < features.length; i++) {
        if (features[i]['id'] == featureId) {
          featureIndex = i;
          break;
        }
      }
      
      if (featureIndex == -1) {
        debugPrint('Không tìm thấy tính năng: $featureId');
        return;
      }
      
      // Cập nhật mô tả và hướng dẫn sử dụng
      final updates = <String, dynamic>{};
      if (improvedDescription != null) {
        updates['app_features.$featureIndex.description'] = improvedDescription;
      }
      if (improvedUsage != null) {
        updates['app_features.$featureIndex.usage'] = improvedUsage;
      }
      
      if (updates.isNotEmpty) {
        await _firestore.collection('app_settings').doc('layout').update(updates);
        debugPrint('Đã cập nhật mô tả cho tính năng: $featureId');
      }
    } catch (e) {
      debugPrint('Lỗi khi áp dụng mô tả cải thiện: $e');
    }
  }
  
  /// Trích xuất JSON từ văn bản
  Map<String, dynamic>? _extractJsonFromText(String text) {
    try {
      // Tìm JSON trong văn bản
      final jsonPattern = RegExp(r'\{[\s\S]*\}');
      final match = jsonPattern.firstMatch(text);
      
      if (match == null) {
        debugPrint('Không tìm thấy cấu trúc JSON trong văn bản');
        return null;
      }
      
      final jsonString = match.group(0);
      if (jsonString == null) return null;
      
      // Parse JSON
      return Map<String, dynamic>.from(
        jsonDecode(jsonString) as Map<String, dynamic>
      );
    } catch (e) {
      debugPrint('Lỗi khi trích xuất JSON: $e');
      return null;
    }
  }
} 