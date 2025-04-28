import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:student_market_nttu/models/product.dart';
import 'package:student_market_nttu/models/moderation_result.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProductModerationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
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
  ProductModerationService();
  
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
      
      // 3. Kiểm tra độ dài của tiêu đề và mô tả
      if (title.length < 5) {
        contentIssues.add({
          'severity': 'medium',
          'description': 'Tiêu đề quá ngắn',
          'field': 'title',
        });
      }
      
      if (description.length < 20) {
        contentIssues.add({
          'severity': 'medium',
          'description': 'Mô tả quá ngắn',
          'field': 'description',
        });
      }
      
      // 4. Kiểm tra giá
      if (price <= 0) {
        contentIssues.add({
          'severity': 'high',
          'description': 'Giá không hợp lệ',
          'field': 'price',
        });
      }
      
      // 5. Tính điểm nội dung
      int contentScore = 100;
      
      // Trừ điểm cho mỗi vấn đề
      for (var issue in contentIssues) {
        if (issue['severity'] == 'high') {
          contentScore -= 30;
        } else if (issue['severity'] == 'medium') {
          contentScore -= 15;
        } else {
          contentScore -= 5;
        }
      }
      
      // Đảm bảo điểm không âm
      contentScore = contentScore < 0 ? 0 : contentScore;
      
      // 6. Gợi ý tags nếu không có
      List<String> suggestedTags = [];
      if (tags.isEmpty) {
        // Thêm danh mục làm tag
        suggestedTags.add(category);
        
        // Thêm các từ khóa phổ biến dựa trên tiêu đề và mô tả
        final keywords = _extractKeywords(title, description);
        suggestedTags.addAll(keywords);
      }
      
      return {
        'score': contentScore,
        'issues': contentIssues,
        'suggestedTags': suggestedTags,
        'analysis': 'Phân tích nội dung sản phẩm hoàn tất với điểm số $contentScore/100',
      };
    } catch (e) {
      debugPrint('Lỗi khi phân tích nội dung văn bản: $e');
      return {
        'score': 70, // Điểm mặc định
        'issues': [
          {
            'severity': 'medium',
            'description': 'Lỗi khi phân tích nội dung: $e',
            'field': 'general',
          }
        ],
        'analysis': 'Lỗi khi phân tích nội dung',
      };
    }
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
    return 'general';
  }
  
  // Trích xuất từ khóa từ tiêu đề và mô tả
  List<String> _extractKeywords(String title, String description) {
    final Set<String> keywords = {};
    final List<String> stopWords = ['và', 'hoặc', 'là', 'của', 'cho', 'với', 'trong', 'ngoài', 'một', 'các'];
    
    // Xử lý tiêu đề
    final titleWords = title.toLowerCase().split(' ')
        .where((word) => word.length > 3 && !stopWords.contains(word))
        .toList();
    
    // Xử lý mô tả (chỉ lấy một số từ)
    final descWords = description.toLowerCase().split(' ')
        .where((word) => word.length > 4 && !stopWords.contains(word))
        .take(5)
        .toList();
    
    // Kết hợp từ khóa
    keywords.addAll(titleWords);
    keywords.addAll(descWords);
    
    // Lấy tối đa 5 từ khóa
    return keywords.take(5).toList();
  }
  
  // Phân tích hình ảnh
  Future<Map<String, dynamic>> _analyzeImages(List<String> imageUrls) async {
    try {
      if (imageUrls.isEmpty) {
        return {
          'score': 50,
          'issues': [
            {
              'severity': 'high',
              'description': 'Không có hình ảnh sản phẩm',
              'imageIndex': -1,
            }
          ],
          'analysis': 'Sản phẩm không có hình ảnh'
        };
      }
      
      List<Map<String, dynamic>> imageResults = [];
      List<Map<String, dynamic>> imageIssues = [];
      
      // Kiểm tra từng hình ảnh
      int index = 0;
      for (String imageUrl in imageUrls) {
        try {
          // Kiểm tra kích thước và định dạng hình ảnh
          final imageDetails = await _checkImageProperties(imageUrl);
          
          // Tính điểm cho hình ảnh này
          int imageScore = 100;
          List<Map<String, dynamic>> issues = [];
          
          // Kiểm tra kích thước
          if (imageDetails['width'] < 400 || imageDetails['height'] < 400) {
            imageScore -= 20;
            issues.add({
              'severity': 'medium',
              'description': 'Hình ảnh có độ phân giải thấp (${imageDetails['width']}x${imageDetails['height']})',
            });
          }
          
          // Kiểm tra tỷ lệ kích thước
          final aspectRatio = imageDetails['width'] / imageDetails['height'];
          if (aspectRatio < 0.5 || aspectRatio > 2.0) {
            imageScore -= 10;
            issues.add({
              'severity': 'low',
              'description': 'Tỷ lệ hình ảnh không cân đối (${aspectRatio.toStringAsFixed(2)})',
            });
          }
          
          // Thêm vào danh sách kết quả
          imageResults.add({
            'url': imageUrl,
            'score': imageScore,
            'issues': issues,
            'details': imageDetails,
          });
          
          // Thêm vấn đề vào danh sách chung với chỉ số hình ảnh
          for (var issue in issues) {
            imageIssues.add({
              ...issue,
              'imageIndex': index,
            });
          }
        } catch (e) {
          debugPrint('Lỗi khi phân tích hình ảnh $index: $e');
          imageResults.add({
            'url': imageUrl,
            'score': 60,
            'issues': [
              {
                'severity': 'medium',
                'description': 'Không thể phân tích hình ảnh: $e',
              }
            ],
          });
          
          imageIssues.add({
            'severity': 'medium',
            'description': 'Lỗi khi phân tích hình ảnh: $e',
            'imageIndex': index,
          });
        }
        
        index++;
      }
      
      // Tính điểm trung bình cho tất cả hình ảnh
      int totalScore = 0;
      for (var result in imageResults) {
        totalScore += result['score'] as int;
      }
      
      int averageScore = imageResults.isNotEmpty ? (totalScore / imageResults.length).round() : 0;
      
      return {
        'score': averageScore,
        'issues': imageIssues,
        'imageResults': imageResults,
        'analysis': 'Phân tích ${imageResults.length} hình ảnh hoàn tất với điểm số trung bình $averageScore/100',
      };
    } catch (e) {
      debugPrint('Lỗi khi phân tích hình ảnh: $e');
      return {
        'score': 70,
        'issues': [
          {
            'severity': 'medium',
            'description': 'Lỗi khi phân tích hình ảnh: $e',
            'imageIndex': -1,
          }
        ],
        'analysis': 'Lỗi khi phân tích hình ảnh',
      };
    }
  }
  
  // Kiểm tra thuộc tính của hình ảnh
  Future<Map<String, dynamic>> _checkImageProperties(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      
      if (response.statusCode != 200) {
        throw Exception('Không thể tải hình ảnh (HTTP ${response.statusCode})');
      }
      
      // Kiểm tra kích thước file
      final fileSizeKB = response.bodyBytes.length / 1024;
      
      // TODO: Dùng thư viện image để lấy kích thước hình ảnh
      // Giả định kích thước trung bình cho bây giờ
      return {
        'width': 800,
        'height': 600,
        'fileSizeKB': fileSizeKB,
        'format': 'jpg', // Đoán định dạng
      };
    } catch (e) {
      throw Exception('Lỗi khi kiểm tra thuộc tính hình ảnh: $e');
    }
  }
  
  // Tính điểm tuân thủ
  int _calculateComplianceScore({
    required Map<String, dynamic> contentAnalysisResult,
    required Map<String, dynamic> imageAnalysisResult,
    required String category,
  }) {
    int score = 100;
    
    // Kiểm tra các vấn đề nghiêm trọng từ phân tích nội dung
    final contentIssues = contentAnalysisResult['issues'] as List<dynamic>? ?? [];
    for (var issue in contentIssues) {
      if (issue['severity'] == 'high') {
        score -= 30;
      }
    }
    
    // Kiểm tra các vấn đề nghiêm trọng từ phân tích hình ảnh
    final imageIssues = imageAnalysisResult['issues'] as List<dynamic>? ?? [];
    for (var issue in imageIssues) {
      if (issue['severity'] == 'high') {
        score -= 30;
      }
    }
    
    // Đảm bảo điểm không âm
    return score < 0 ? 0 : score;
  }
  
  // Tạo lý do từ chối dựa trên các vấn đề
  String _generateRejectionReason(List<ModerationIssue> issues) {
    final highSeverityIssues = issues.where((issue) => issue.severity == 'high').toList();
    final mediumSeverityIssues = issues.where((issue) => issue.severity == 'medium').toList();
    
    if (highSeverityIssues.isNotEmpty) {
      return highSeverityIssues.map((issue) => issue.description).join('. ');
    } else if (mediumSeverityIssues.isNotEmpty) {
      return 'Sản phẩm không đáp ứng các tiêu chuẩn của chúng tôi: ${mediumSeverityIssues.map((issue) => issue.description).join('. ')}';
    } else {
      return 'Sản phẩm không đáp ứng các tiêu chuẩn của nền tảng.';
    }
  }
  
  // Phương thức kiểm duyệt thủ công
  Future<void> manualModeration(String moderationId, ModerationStatus newStatus, {String? comments}) async {
    try {
      _setLoading(true);
      
      // Lấy thông tin kết quả kiểm duyệt
      final doc = await _firestore.collection('moderation_results').doc(moderationId).get();
      
      if (!doc.exists) {
        throw Exception('Không tìm thấy kết quả kiểm duyệt');
      }
      
      final data = doc.data() as Map<String, dynamic>;
      final productId = data['productId'] as String?;
      
      if (productId == null) {
        throw Exception('Thiếu thông tin productId');
      }
      
      // Cập nhật trạng thái kiểm duyệt
      await _firestore.collection('moderation_results').doc(moderationId).update({
        'status': newStatus.toString().split('.').last,
        'manualReview': true,
        'reviewComments': comments,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
      
      // Cập nhật trạng thái sản phẩm
      await _updateProductStatus(productId, newStatus, {
        'moderationId': moderationId,
        'moderationStatus': newStatus.toString().split('.').last,
        'manualReview': true,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
      
      _setLoading(false);
    } catch (e) {
      _setError('Lỗi khi thực hiện kiểm duyệt thủ công: $e');
      _setLoading(false);
      throw e;
    }
  }
  
  // Lấy danh sách các sản phẩm cần kiểm duyệt
  Stream<List<Map<String, dynamic>>> getProductsForModeration() {
    return _firestore
        .collection('moderation_results')
        .where('status', isEqualTo: ModerationStatus.in_review.toString().split('.').last)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> results = [];
          
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final productId = data['productId'] as String?;
            
            if (productId != null) {
              // Lấy thông tin sản phẩm
              try {
                final productDoc = await _firestore.collection('products').doc(productId).get();
                if (productDoc.exists) {
                  final productData = productDoc.data();
                  
                  results.add({
                    'moderation': data,
                    'product': productData,
                    'moderationId': doc.id,
                  });
                }
              } catch (e) {
                debugPrint('Lỗi khi lấy thông tin sản phẩm $productId: $e');
              }
            }
          }
          
          return results;
        });
  }
  
  // Lấy lịch sử kiểm duyệt sản phẩm
  Future<List<Map<String, dynamic>>> getModerationHistory({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('moderation_results')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      List<Map<String, dynamic>> results = [];
      
      for (var doc in snapshot.docs) {
        results.add({
          ...doc.data(),
          'id': doc.id,
        });
      }
      
      return results;
    } catch (e) {
      debugPrint('Lỗi khi lấy lịch sử kiểm duyệt: $e');
      return [];
    }
  }
} 