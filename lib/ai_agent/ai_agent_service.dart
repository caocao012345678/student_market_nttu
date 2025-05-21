import 'package:flutter/foundation.dart';
import 'models/analysis_result.dart';
import 'models/review_decision.dart';
import 'services/text_analyzer.dart';
import 'services/image_analyzer.dart';
import 'services/decision_maker.dart';
import 'services/product_listener.dart';
import 'services/action_executor.dart';
import '../models/product.dart';

class AIAgentService extends ChangeNotifier {
  final TextAnalyzer _textAnalyzer;
  final ImageAnalyzer _imageAnalyzer;
  final DecisionMaker _decisionMaker;
  final ProductReviewListener _productListener;
  final ActionExecutor _actionExecutor;

  bool _isRunning = false;
  bool _isProcessing = false;
  int _totalProcessed = 0;
  int _approved = 0;
  int _rejected = 0;
  int _flaggedForReview = 0;
  
  List<String> _processingLog = [];
  int _maxLogEntries = 100;

  // Getters
  bool get isRunning => _isRunning;
  bool get isProcessing => _isProcessing;
  int get totalProcessed => _totalProcessed;
  int get approved => _approved;
  int get rejected => _rejected;
  int get flaggedForReview => _flaggedForReview;
  List<String> get processingLog => List.unmodifiable(_processingLog);

  AIAgentService({
    TextAnalyzer? textAnalyzer,
    ImageAnalyzer? imageAnalyzer,
    DecisionMaker? decisionMaker,
    ProductReviewListener? productListener,
    ActionExecutor? actionExecutor,
  }) : 
    _textAnalyzer = textAnalyzer ?? TextAnalyzer(),
    _imageAnalyzer = imageAnalyzer ?? ImageAnalyzer(),
    _decisionMaker = decisionMaker ?? DecisionMaker(),
    _actionExecutor = actionExecutor ?? ActionExecutor(),
    _productListener = productListener ?? ProductReviewListener(
      onProductNeedsReview: (productData) {
        // Callback này sẽ được ghi đè trong khởi tạo bên dưới
      }
    );

  // Khởi tạo service
  void initialize() {
    // Thiết lập callback xử lý sản phẩm
    _productListener.updateCallback((productData) async {
      final Product product = Product.fromMap(productData, productData['id']);
      await processProduct(product);
    });
    
    // Đảm bảo dừng lắng nghe trước khi khởi động lại
    _productListener.stopListening();
    
    _addToLog('AI Agent đã được khởi tạo và sẵn sàng');
  }

  // Bắt đầu lắng nghe sản phẩm mới
  void start() {
    if (_isRunning) return;
    
    _isRunning = true;
    // Thiết lập callback trực tiếp trước khi bắt đầu lắng nghe
    _productListener.startListening();
    
    _addToLog('AI Agent đã bắt đầu chạy');
    notifyListeners();
  }

  // Dừng lắng nghe
  void stop() {
    if (!_isRunning) return;
    
    _isRunning = false;
    _productListener.stopListening();
    _addToLog('AI Agent đã dừng');
    notifyListeners();
  }

  // Xử lý một sản phẩm
  Future<ReviewDecision?> processProduct(Product product) async {
    if (_isProcessing) {
      _addToLog('Đang xử lý sản phẩm khác, sẽ xử lý ${product.id} sau');
      return null;
    }
    
    try {
      _isProcessing = true;
      _addToLog('Đang xử lý bài đăng: ${product.id} - ${product.title}');
      notifyListeners();
      
      final List<AnalysisResult> analysisResults = [];
      
      // Phân tích tiêu đề
      if (product.title.isNotEmpty) {
        _addToLog('Đang phân tích tiêu đề: ${product.title}');
        final titleAnalysis = await _textAnalyzer.analyzeProductTitle(
          product.title,
          categoryId: product.category,
        );
        analysisResults.add(titleAnalysis);
        _addToLog('Phân tích tiêu đề hoàn tất: ${titleAnalysis.isCompliant ? 'OK' : 'Không phù hợp'}');
      }
      
      // Phân tích mô tả
      if (product.description.isNotEmpty) {
        _addToLog('Đang phân tích mô tả sản phẩm');
        final descriptionAnalysis = await _textAnalyzer.analyzeProductDescription(
          product.description,
          categoryId: product.category,
        );
        analysisResults.add(descriptionAnalysis);
        _addToLog('Phân tích mô tả hoàn tất: ${descriptionAnalysis.isCompliant ? 'OK' : 'Không phù hợp'}');
      }
      
      // Phân tích hình ảnh
      if (product.images.isNotEmpty) {
        for (int i = 0; i < product.images.length; i++) {
          final imageUrl = product.images[i];
          _addToLog('Đang phân tích hình ảnh ${i+1}/${product.images.length}');
          final imageAnalysis = await _imageAnalyzer.analyzeProductImage(
            imageUrl,
            productTitle: product.title,
            categoryId: product.category,
          );
          analysisResults.add(imageAnalysis);
          _addToLog('Phân tích hình ảnh ${i+1} hoàn tất: ${imageAnalysis.isCompliant ? 'OK' : 'Không phù hợp'}');
        }
      } else {
        _addToLog('Sản phẩm không có hình ảnh');
      }
      
      // Ra quyết định
      _addToLog('Đang đưa ra quyết định dựa trên phân tích');
      final decision = await _decisionMaker.makeDecision(product.id, analysisResults);
      
      // Thực thi quyết định
      _addToLog('Đang thực hiện quyết định: ${decision.decision.toString().split('.').last}');
      final success = await _actionExecutor.executeDecision(decision);
      
      if (success) {
        _totalProcessed++;
        
        // Cập nhật thống kê
        switch (decision.decision) {
          case DecisionType.approved:
            _approved++;
            break;
          case DecisionType.rejected:
            _rejected++;
            break;
          case DecisionType.flaggedForReview:
            _flaggedForReview++;
            break;
        }
        
        _addToLog('Đã xử lý bài đăng ${product.id} thành công với quyết định: ${decision.decision.toString().split('.').last}');
      } else {
        _addToLog('Không thể thực thi quyết định cho bài đăng ${product.id}');
      }
      
      _isProcessing = false;
      notifyListeners();
      
      return decision;
    } catch (e) {
      _addToLog('Lỗi khi xử lý bài đăng ${product.id}: $e');
      _isProcessing = false;
      notifyListeners();
      return null;
    }
  }
  
  // Xử lý lại một sản phẩm cụ thể
  Future<void> reprocessProduct(String productId) async {
    _productListener.resetProcessedProduct(productId);
    _addToLog('Đã đánh dấu sản phẩm $productId để xử lý lại');
    notifyListeners();
  }
  
  // Thêm vào log
  void _addToLog(String message) {
    final timestamp = DateTime.now().toString().substring(0, 19);
    _processingLog.insert(0, '[$timestamp] $message');
    
    // Giới hạn kích thước log
    if (_processingLog.length > _maxLogEntries) {
      _processingLog = _processingLog.sublist(0, _maxLogEntries);
    }
  }
  
  // Xóa log
  void clearLog() {
    _processingLog.clear();
    _addToLog('Log đã được xóa');
    notifyListeners();
  }
  
  // Reset thống kê
  void resetStats() {
    _totalProcessed = 0;
    _approved = 0;
    _rejected = 0;
    _flaggedForReview = 0;
    _addToLog('Thống kê đã được reset');
    notifyListeners();
  }
} 