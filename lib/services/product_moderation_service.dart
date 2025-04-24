import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:student_market_nttu/models/product.dart';
import 'package:student_market_nttu/models/moderation_result.dart';
import 'package:student_market_nttu/services/gemini_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProductModerationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GeminiService _geminiService;
  
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Danh sách các từ khóa không phù hợp
  final List<String> _bannedKeywords = [
    'vũ khí', 'súng', 'dao', 'ma túy', 'cần sa', 'cocaine', 'heroin',
    'khỏa thân', 'khiêu dâm', 'cờ bạc', 'viagra', 'thuốc lá điện tử',
    // Thêm các từ khóa khác
  ];
  
  // Danh sách danh mục bị cấm
  final List<String> _bannedCategories = [
    'vũ khí', 'chất kích thích', 'thuốc lá', 'đồ 18+', 'cờ bạc'
  ];
  
  // Constructor
  ProductModerationService(this._geminiService);
  
  // Getters
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  
  // Thiết lập trạng thái loading
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  // Thiết lập thông báo lỗi
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  // Kiểm duyệt sản phẩm mới
  Future<ModerationResult> moderateProduct({
    required String productId,
    required String title,
    required String description,
    required String category,
    required double price,
    required List<String> tags,
    required List<String> imageUrls,
    required Map<String, String> specifications,
  }) async {
    _setLoading(true);
    _setError('');
    
    try {
      // 1. Tạo ID mới cho kết quả kiểm duyệt
      final String moderationId = _firestore.collection('moderation_results').doc().id;
      
      // 2. Phân tích nội dung văn bản
      final contentAnalysisResult = await _analyzeTextContent(
        title: title,
        description: description,
        category: category,
        tags: tags,
        specifications: specifications,
        price: price,
      );
      
      // 3. Phân tích hình ảnh
      final imageAnalysisResult = await _analyzeImages(imageUrls);
      
      // 4. Tổng hợp kết quả và tính điểm
      int contentScore = contentAnalysisResult['score'] as int;
      int imageScore = imageAnalysisResult['score'] as int;
      int complianceScore = _calculateComplianceScore(
        contentAnalysisResult: contentAnalysisResult,
        imageAnalysisResult: imageAnalysisResult,
        category: category,
      );
      
      // Tính tổng điểm (trọng số: nội dung 40%, hình ảnh 40%, tuân thủ 20%)
      int totalScore = ((contentScore * 0.4) + (imageScore * 0.4) + (complianceScore * 0.2)).round();
      
      // 5. Tạo danh sách vấn đề (nếu có)
      List<ModerationIssue> issues = [];
      
      // Thêm vấn đề từ phân tích nội dung
      if (contentAnalysisResult['issues'] != null) {
        List<dynamic> contentIssues = contentAnalysisResult['issues'] as List<dynamic>;
        for (var issue in contentIssues) {
          issues.add(ModerationIssue(
            type: 'content',
            severity: issue['severity'] ?? 'low',
            description: issue['description'] ?? '',
            field: issue['field'],
          ));
        }
      }
      
      // Thêm vấn đề từ phân tích hình ảnh
      if (imageAnalysisResult['issues'] != null) {
        List<dynamic> imageIssues = imageAnalysisResult['issues'] as List<dynamic>;
        for (var issue in imageIssues) {
          issues.add(ModerationIssue(
            type: 'image',
            severity: issue['severity'] ?? 'low',
            description: issue['description'] ?? '',
            imageIndex: issue['imageIndex'],
          ));
        }
      }
      
      // 6. Xác định trạng thái kiểm duyệt dựa trên điểm số
      ModerationStatus status;
      String? rejectionReason;
      
      if (totalScore >= 85) {
        status = ModerationStatus.approved;
      } else if (totalScore < 60) {
        status = ModerationStatus.rejected;
        rejectionReason = _generateRejectionReason(issues);
      } else {
        status = ModerationStatus.in_review;  // Cần kiểm duyệt viên xem xét
      }
      
      // 7. Tạo đối tượng kết quả kiểm duyệt
      final result = ModerationResult(
        id: moderationId,
        productId: productId,
        status: status,
        createdAt: DateTime.now(),
        imageScore: imageScore,
        contentScore: contentScore,
        complianceScore: complianceScore,
        totalScore: totalScore,
        issues: issues.isNotEmpty ? issues : null,
        suggestedTags: contentAnalysisResult['suggestedTags'] as List<String>?,
        rejectionReason: rejectionReason,
        imageAnalysis: imageAnalysisResult,
        contentAnalysis: contentAnalysisResult,
      );
      
      // 8. Lưu kết quả vào Firestore
      await _firestore.collection('moderation_results').doc(moderationId).set(result.toMap());
      
      // 9. Cập nhật trạng thái sản phẩm
      await _updateProductStatus(productId, status, {
        'moderationId': moderationId,
        'moderationScore': totalScore,
        'moderationTimestamp': FieldValue.serverTimestamp(),
      });
      
      _setLoading(false);
      return result;
    } catch (e) {
      _setError('Lỗi trong quá trình kiểm duyệt: $e');
      _setLoading(false);
      
      // Tạo kết quả lỗi
      return ModerationResult(
        id: 'error',
        productId: productId,
        status: ModerationStatus.in_review,  // Chuyển sang kiểm duyệt thủ công khi có lỗi
        createdAt: DateTime.now(),
        imageScore: 0,
        contentScore: 0,
        complianceScore: 0,
        totalScore: 0,
        issues: [
          ModerationIssue(
            type: 'system',
            severity: 'high',
            description: 'Lỗi xử lý: $e',
          )
        ],
      );
    }
  }
  
  // Cập nhật trạng thái sản phẩm dựa trên kết quả kiểm duyệt
  Future<void> _updateProductStatus(
    String productId, 
    ModerationStatus moderationStatus,
    Map<String, dynamic> moderationInfo
  ) async {
    ProductStatus productStatus;
    
    // Ánh xạ trạng thái kiểm duyệt sang trạng thái sản phẩm
    switch (moderationStatus) {
      case ModerationStatus.approved:
        productStatus = ProductStatus.available;
        break;
      case ModerationStatus.rejected:
        productStatus = ProductStatus.rejected;
        break;
      case ModerationStatus.in_review:
      case ModerationStatus.pending:
      default:
        productStatus = ProductStatus.pending_review;
        break;
    }
    
    // Cập nhật trạng thái sản phẩm
    await _firestore.collection('products').doc(productId).update({
      'status': productStatus.toString().split('.').last,
      'moderationInfo': moderationInfo,
    });
  }
  
  // Phân tích nội dung văn bản
  Future<Map<String, dynamic>> _analyzeTextContent({
    required String title,
    required String description,
    required String category,
    required List<String> tags,
    required Map<String, String> specifications,
    required double price,
  }) async {
    try {
      // 1. Kiểm tra từ khóa không phù hợp
      List<Map<String, dynamic>> contentIssues = [];
      String combinedText = '$title $description ${tags.join(' ')}';
      combinedText = combinedText.toLowerCase();
      
      for (String keyword in _bannedKeywords) {
        if (combinedText.contains(keyword.toLowerCase())) {
          contentIssues.add({
            'severity': 'high',
            'description': 'Nội dung chứa từ khóa bị cấm: $keyword',
            'field': _determineIssueField(keyword, title, description, tags),
          });
        }
      }
      
      // 2. Kiểm tra danh mục bị cấm
      if (_bannedCategories.contains(category.toLowerCase())) {
        contentIssues.add({
          'severity': 'high',
          'description': 'Danh mục sản phẩm không được phép: $category',
          'field': 'category',
        });
      }
      
      // 3. Kiểm tra giá trị giá cả
      if (price <= 0) {
        contentIssues.add({
          'severity': 'medium',
          'description': 'Giá không hợp lệ: $price',
          'field': 'price',
        });
      } else if (price > 100000000) { // Giá quá cao (100 triệu)
        contentIssues.add({
          'severity': 'medium',
          'description': 'Giá có vẻ quá cao: $price',
          'field': 'price',
        });
      }
      
      // 4. Kiểm tra độ dài tiêu đề và mô tả
      if (title.length < 5) {
        contentIssues.add({
          'severity': 'low',
          'description': 'Tiêu đề quá ngắn',
          'field': 'title',
        });
      }
      
      if (description.length < 20) {
        contentIssues.add({
          'severity': 'low',
          'description': 'Mô tả quá ngắn',
          'field': 'description',
        });
      }
      
      // 5. Sử dụng Gemini để phân tích ngữ nghĩa nâng cao
      Map<String, dynamic> geminiAnalysis = await _geminiTextAnalysis(
        title: title,
        description: description,
        category: category,
        tags: tags,
      );
      
      // 6. Đánh giá mức độ liên quan giữa tiêu đề, mô tả và danh mục
      int relevanceScore = geminiAnalysis['relevanceScore'] ?? 70;
      
      // 7. Gợi ý tags nếu cần
      List<String> suggestedTags = [];
      if (tags.isEmpty || tags.length < 3) {
        suggestedTags = geminiAnalysis['suggestedTags'] ?? [];
      }
      
      // 8. Bổ sung issues từ kết quả phân tích Gemini
      if (geminiAnalysis['issues'] != null) {
        contentIssues.addAll(geminiAnalysis['issues']);
      }
      
      // 9. Tính điểm nội dung dựa trên nhiều yếu tố
      int contentScore = _calculateContentScore(
        relevanceScore: relevanceScore,
        titleLength: title.length,
        descriptionLength: description.length,
        tagsCount: tags.length,
        specificationsCount: specifications.length,
        issues: contentIssues,
      );
      
      // 10. Tạo kết quả phân tích
      return {
        'score': contentScore,
        'issues': contentIssues,
        'suggestedTags': suggestedTags,
        'relevanceScore': relevanceScore,
        'geminiAnalysis': geminiAnalysis,
      };
    } catch (e) {
      debugPrint('Lỗi phân tích nội dung: $e');
      return {
        'score': 60, // Điểm mặc định khi có lỗi
        'issues': [{
          'severity': 'medium',
          'description': 'Lỗi khi phân tích nội dung: $e',
          'field': 'content',
        }],
      };
    }
  }
  
  // Phân tích hình ảnh
  Future<Map<String, dynamic>> _analyzeImages(List<String> imageUrls) async {
    try {
      if (imageUrls.isEmpty) {
        return {
          'score': 0,
          'issues': [{
            'severity': 'high',
            'description': 'Không có hình ảnh nào được cung cấp',
          }],
        };
      }
      
      List<Map<String, dynamic>> imageIssues = [];
      List<Map<String, dynamic>> imageResults = [];
      
      // Kiểm tra số lượng hình ảnh
      if (imageUrls.length < 2) {
        imageIssues.add({
          'severity': 'low',
          'description': 'Khuyến nghị cung cấp nhiều hình ảnh hơn để tăng độ tin cậy',
        });
      }
      
      // Phân tích từng hình ảnh
      for (int i = 0; i < imageUrls.length; i++) {
        String url = imageUrls[i];
        
        // Phân tích hình ảnh bằng Vision API hoặc Gemini
        Map<String, dynamic> imageAnalysis = await _analyzeImageContent(url, i);
        imageResults.add(imageAnalysis);
        
        // Kiểm tra vấn đề với hình ảnh
        if (imageAnalysis['issues'] != null) {
          for (var issue in imageAnalysis['issues']) {
            issue['imageIndex'] = i;
            imageIssues.add(issue);
          }
        }
      }
      
      // Tính điểm trung bình cho hình ảnh
      int totalScore = 0;
      for (var result in imageResults) {
        totalScore += (result['score'] as int? ?? 0);
      }
      int averageScore = imageResults.isNotEmpty ? (totalScore / imageResults.length).round() : 0;
      
      return {
        'score': averageScore,
        'issues': imageIssues,
        'results': imageResults,
      };
    } catch (e) {
      debugPrint('Lỗi phân tích hình ảnh: $e');
      return {
        'score': 60, // Điểm mặc định khi có lỗi
        'issues': [{
          'severity': 'medium',
          'description': 'Lỗi khi phân tích hình ảnh: $e',
        }],
      };
    }
  }
  
  // Phân tích hình ảnh sử dụng Gemini hoặc Vision API
  Future<Map<String, dynamic>> _analyzeImageContent(String imageUrl, int index) async {
    try {
      // Sử dụng Gemini để phân tích hình ảnh
      return await _geminiImageAnalysis(imageUrl);
    } catch (e) {
      debugPrint('Lỗi phân tích hình ảnh $index: $e');
      return {
        'score': 60,
        'issues': [{
          'severity': 'medium', 
          'description': 'Không thể phân tích hình ảnh này',
          'imageIndex': index,
        }],
      };
    }
  }
  
  // Phân tích văn bản với Gemini
  Future<Map<String, dynamic>> _geminiTextAnalysis({
    required String title,
    required String description,
    required String category,
    required List<String> tags,
  }) async {
    try {
      // Tạo prompt cho Gemini
      String prompt = '''
      Phân tích nội dung sản phẩm sau và đánh giá tính phù hợp:
      
      Tiêu đề: $title
      Mô tả: $description
      Danh mục: $category
      Tags: ${tags.join(', ')}
      
      Phân tích các khía cạnh sau:
      1. Mức độ phù hợp giữa tiêu đề, mô tả và danh mục (thang điểm 0-100)
      2. Phát hiện nội dung không phù hợp, vi phạm hoặc lừa đảo
      3. Đề xuất 3-5 tags liên quan nếu người dùng chưa cung cấp đủ
      
      Trả về kết quả dưới dạng JSON với cấu trúc:
      {
        "relevanceScore": 85,
        "suggestedTags": ["tag1", "tag2", "tag3"],
        "issues": [
          {"severity": "high/medium/low", "description": "Mô tả vấn đề", "field": "title/description/tags"}
        ],
        "analysis": "Phân tích tổng quan và nhận xét"
      }
      ''';
      
      // Gửi prompt đến Gemini
      String response = await _geminiService.sendPromptedMessage(prompt, '', addToHistory: false);
      
      // Trích xuất JSON từ phản hồi
      String jsonString = _extractJsonFromText(response);
      if (jsonString.isEmpty) {
        return {'relevanceScore': 70};
      }
      
      Map<String, dynamic> result = jsonDecode(jsonString);
      return result;
    } catch (e) {
      debugPrint('Lỗi khi phân tích văn bản với Gemini: $e');
      return {'relevanceScore': 70};
    }
  }
  
  // Phân tích hình ảnh với Gemini
  Future<Map<String, dynamic>> _geminiImageAnalysis(String imageUrl) async {
    try {
      // Tạo prompt cho Gemini
      String prompt = '''
      Phân tích hình ảnh sản phẩm này và đánh giá tính phù hợp:
      
      1. Xác định vật phẩm chính trong hình ảnh
      2. Đánh giá chất lượng hình ảnh (rõ nét, ánh sáng, góc chụp)
      3. Phát hiện nội dung không phù hợp hoặc vi phạm (hàng cấm, vũ khí, nội dung người lớn, v.v.)
      4. Đánh giá mức độ phù hợp cho một nền tảng mua bán cho học sinh, sinh viên
      
      Trả về kết quả dưới dạng JSON với cấu trúc:
      {
        "objects": ["đối tượng1", "đối tượng2"],
        "score": 85,
        "quality": "high/medium/low",
        "issues": [
          {"severity": "high/medium/low", "description": "Mô tả vấn đề"}
        ],
        "analysis": "Phân tích tổng quan và nhận xét"
      }
      ''';
      
      // Gửi prompt cùng với hình ảnh đến Gemini
      String response = await _geminiService.sendImageAnalysisPrompt(prompt, imageUrl);
      
      // Trích xuất JSON từ phản hồi
      String jsonString = _extractJsonFromText(response);
      if (jsonString.isEmpty) {
        return {'score': 70};
      }
      
      Map<String, dynamic> result = jsonDecode(jsonString);
      return result;
    } catch (e) {
      debugPrint('Lỗi khi phân tích hình ảnh với Gemini: $e');
      return {'score': 70};
    }
  }
  
  // Phân tích hình ảnh với Google Cloud Vision API
  Future<Map<String, dynamic>> _cloudVisionImageAnalysis(String imageUrl) async {
    try {
      final apiKey = dotenv.env['VISION_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API key cho Vision không được cấu hình');
      }
      
      final visionApiUrl = 'https://vision.googleapis.com/v1/images:annotate?key=$apiKey';
      
      // Chuẩn bị request body
      final requestBody = {
        'requests': [
          {
            'image': {
              'source': {
                'imageUri': imageUrl
              }
            },
            'features': [
              {'type': 'LABEL_DETECTION', 'maxResults': 10},
              {'type': 'SAFE_SEARCH_DETECTION'},
              {'type': 'IMAGE_PROPERTIES'},
              {'type': 'OBJECT_LOCALIZATION', 'maxResults': 5},
            ]
          }
        ]
      };
      
      // Gửi request đến Vision API
      final response = await http.post(
        Uri.parse(visionApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Vision API trả về lỗi: ${response.body}');
      }
      
      // Phân tích kết quả
      final responseData = jsonDecode(response.body);
      final annotations = responseData['responses'][0];
      
      // Phân tích SafeSearch
      final safeSearch = annotations['safeSearchAnnotation'];
      List<Map<String, dynamic>> issues = [];
      int safetyScore = 100;
      
      // Kiểm tra kết quả SafeSearch
      if (safeSearch != null) {
        // Kiểm tra các nhãn an toàn (adult, violence, racy, etc.)
        final adultRating = safeSearch['adult'] ?? 'UNKNOWN';
        final violenceRating = safeSearch['violence'] ?? 'UNKNOWN';
        final racyRating = safeSearch['racy'] ?? 'UNKNOWN';
        
        if (['LIKELY', 'VERY_LIKELY'].contains(adultRating)) {
          issues.add({
            'severity': 'high',
            'description': 'Hình ảnh có thể chứa nội dung người lớn',
          });
          safetyScore -= 50;
        }
        
        if (['LIKELY', 'VERY_LIKELY'].contains(violenceRating)) {
          issues.add({
            'severity': 'high',
            'description': 'Hình ảnh có thể chứa nội dung bạo lực',
          });
          safetyScore -= 40;
        }
        
        if (['LIKELY', 'VERY_LIKELY'].contains(racyRating)) {
          issues.add({
            'severity': 'medium',
            'description': 'Hình ảnh có thể chứa nội dung nhạy cảm',
          });
          safetyScore -= 30;
        }
      }
      
      // Kiểm tra labels
      final labels = annotations['labelAnnotations'] ?? [];
      List<String> objects = [];
      
      for (var label in labels) {
        String description = label['description'] ?? '';
        objects.add(description);
        
        // Kiểm tra xem có nhãn liên quan đến vật phẩm bị cấm không
        for (String keyword in _bannedKeywords) {
          if (description.toLowerCase().contains(keyword.toLowerCase())) {
            issues.add({
              'severity': 'high',
              'description': 'Hình ảnh có thể chứa vật phẩm bị cấm: $description',
            });
            safetyScore -= 50;
            break;
          }
        }
      }
      
      // Đánh giá chất lượng hình ảnh
      final imageProps = annotations['imagePropertiesAnnotation'];
      String quality = 'medium';
      
      if (imageProps != null) {
        // Logic phức tạp hơn có thể được thêm vào đây để đánh giá chất lượng
        quality = 'high';
      }
      
      return {
        'objects': objects,
        'score': safetyScore,
        'quality': quality,
        'issues': issues,
        'raw_response': annotations
      };
    } catch (e) {
      debugPrint('Lỗi khi sử dụng Vision API: $e');
      return {'score': 70};
    }
  }
  
  // Tính điểm nội dung
  int _calculateContentScore({
    required int relevanceScore,
    required int titleLength,
    required int descriptionLength,
    required int tagsCount,
    required int specificationsCount,
    required List<Map<String, dynamic>> issues,
  }) {
    int baseScore = relevanceScore;
    
    // Đánh giá độ dài tiêu đề
    if (titleLength < 5) {
      baseScore -= 10;
    } else if (titleLength < 10) {
      baseScore -= 5;
    } else if (titleLength > 50) {
      baseScore -= 5;
    }
    
    // Đánh giá độ dài mô tả
    if (descriptionLength < 20) {
      baseScore -= 15;
    } else if (descriptionLength < 50) {
      baseScore -= 10;
    } else if (descriptionLength > 100) {
      baseScore += 5;
    }
    
    // Đánh giá số lượng tags
    if (tagsCount == 0) {
      baseScore -= 10;
    } else if (tagsCount < 3) {
      baseScore -= 5;
    } else if (tagsCount >= 5) {
      baseScore += 5;
    }
    
    // Đánh giá số lượng thông số kỹ thuật
    if (specificationsCount > 0) {
      baseScore += specificationsCount * 2;
    }
    
    // Trừ điểm cho mỗi vấn đề được phát hiện
    for (var issue in issues) {
      String severity = issue['severity'] ?? 'low';
      if (severity == 'high') {
        baseScore -= 30;
      } else if (severity == 'medium') {
        baseScore -= 15;
      } else {
        baseScore -= 5;
      }
    }
    
    // Giới hạn điểm trong khoảng 0-100
    return baseScore.clamp(0, 100);
  }
  
  // Tính điểm tuân thủ
  int _calculateComplianceScore({
    required Map<String, dynamic> contentAnalysisResult,
    required Map<String, dynamic> imageAnalysisResult,
    required String category,
  }) {
    int baseScore = 100;
    
    // Kiểm tra danh mục bị cấm
    if (_bannedCategories.contains(category.toLowerCase())) {
      baseScore -= 100;  // Không tuân thủ hoàn toàn
      return 0;
    }
    
    // Kiểm tra vấn đề nội dung
    List<dynamic> contentIssues = contentAnalysisResult['issues'] ?? [];
    for (var issue in contentIssues) {
      String severity = issue['severity'] ?? 'low';
      if (severity == 'high') {
        baseScore -= 40;
      } else if (severity == 'medium') {
        baseScore -= 20;
      } else {
        baseScore -= 10;
      }
    }
    
    // Kiểm tra vấn đề hình ảnh
    List<dynamic> imageIssues = imageAnalysisResult['issues'] ?? [];
    for (var issue in imageIssues) {
      String severity = issue['severity'] ?? 'low';
      if (severity == 'high') {
        baseScore -= 40;
      } else if (severity == 'medium') {
        baseScore -= 20;
      } else {
        baseScore -= 10;
      }
    }
    
    // Giới hạn điểm trong khoảng 0-100
    return baseScore.clamp(0, 100);
  }
  
  // Tạo lý do từ chối
  String _generateRejectionReason(List<ModerationIssue> issues) {
    if (issues.isEmpty) {
      return 'Sản phẩm không đáp ứng các tiêu chuẩn của nền tảng.';
    }
    
    // Tìm và ưu tiên vấn đề nghiêm trọng
    List<ModerationIssue> highSeverityIssues = issues.where((i) => i.severity == 'high').toList();
    if (highSeverityIssues.isNotEmpty) {
      return highSeverityIssues.map((i) => i.description).join('. ');
    }
    
    // Nếu không có vấn đề nghiêm trọng, liệt kê tất cả vấn đề
    return 'Sản phẩm bị từ chối vì các lý do sau: ${issues.map((i) => i.description).join('; ')}';
  }
  
  // Xác định trường có vấn đề
  String _determineIssueField(String keyword, String title, String description, List<String> tags) {
    if (title.toLowerCase().contains(keyword.toLowerCase())) {
      return 'title';
    } else if (description.toLowerCase().contains(keyword.toLowerCase())) {
      return 'description';
    } else {
      for (String tag in tags) {
        if (tag.toLowerCase().contains(keyword.toLowerCase())) {
          return 'tags';
        }
      }
    }
    return 'content';
  }
  
  // Trích xuất JSON từ phản hồi văn bản
  String _extractJsonFromText(String text) {
    try {
      // Tìm vị trí bắt đầu và kết thúc của JSON
      int startIndex = text.indexOf('{');
      int endIndex = text.lastIndexOf('}') + 1;
      
      if (startIndex >= 0 && endIndex > startIndex) {
        return text.substring(startIndex, endIndex);
      }
      return '';
    } catch (e) {
      debugPrint('Lỗi khi trích xuất JSON: $e');
      return '';
    }
  }
} 