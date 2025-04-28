import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service quản lý thông tin về các chức năng của ứng dụng
/// Đóng vai trò là "ground truth" để tránh hallucination từ LLM
class AppFeaturesService extends ChangeNotifier {
  // Danh sách các chức năng có trong ứng dụng
  final List<Map<String, dynamic>> _existingFeatures = [
    {
      'id': 'add_product',
      'name': 'Đăng bán sản phẩm',
      'description': 'Cho phép người dùng đăng bán sản phẩm mới trên ứng dụng',
      'available': true,
      'location': 'Nút "+" ở góc dưới phải hoặc từ trang hồ sơ "Sản phẩm của tôi"',
      'guide': '''
1. Trên màn hình chính, nhấn vào nút "+" ở góc dưới phải hoặc vào trang hồ sơ và chọn "Sản phẩm của tôi"
2. Trong màn hình Sản phẩm của tôi, nhấn nút "Thêm sản phẩm mới"
3. Điền đầy đủ thông tin sản phẩm:
   - Tên sản phẩm
   - Giá bán
   - Mô tả chi tiết
   - Danh mục phù hợp
   - Tình trạng sản phẩm (mới/đã qua sử dụng)
4. Thêm hình ảnh sản phẩm (tối đa 5 ảnh, ảnh đầu tiên sẽ là ảnh chính)
5. Kiểm tra lại thông tin và nhấn "Đăng bán"
6. Sau khi đăng bán, sản phẩm sẽ xuất hiện trong mục "Sản phẩm của tôi" và hiển thị trên sàn
''',
      'source_code': {
        'main_file': 'lib/screens/add_product_screen.dart',
        'related_files': [
          'lib/services/product_service.dart',
          'lib/widgets/product_form.dart'
        ],
        'key_functions': '''
// AddProductScreen - Màn hình chính để thêm sản phẩm
class AddProductScreen extends StatefulWidget {
  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

// ProductService - Phương thức thêm sản phẩm
Future<String?> addProduct(Product product, List<File> images) async {
  try {
    // Upload sản phẩm lên Firestore
    // Upload hình ảnh lên Firebase Storage
    return productId;
  } catch (e) {
    return null;
  }
}

// ProductForm - Widget hiển thị form nhập thông tin sản phẩm
class ProductForm extends StatefulWidget {
  // Cho phép người dùng nhập thông tin và chọn hình ảnh
}
'''
      },
      'code_analysis': '''
Chức năng "Đăng bán sản phẩm" được triển khai chủ yếu qua 3 thành phần:
1. AddProductScreen: Màn hình chính hiển thị form
2. ProductForm: Widget quản lý các trường nhập liệu
3. ProductService: Service xử lý việc lưu trữ và đăng tải sản phẩm

Quá trình thêm sản phẩm bao gồm các bước:
- Người dùng điền thông tin vào form
- Chọn và crop hình ảnh sản phẩm
- Hệ thống validate thông tin trước khi lưu
- Upload hình ảnh lên Firebase Storage
- Lưu thông tin sản phẩm lên Firestore
'''
    },
    {
      'id': 'manage_products',
      'name': 'Quản lý sản phẩm đã đăng',
      'description': 'Cho phép người dùng xem, chỉnh sửa, hoặc xóa các sản phẩm đã đăng bán',
      'available': true,
      'location': 'Mục "Sản phẩm của tôi" trong trang hồ sơ',
      'guide': '''
1. Vào trang hồ sơ bằng cách nhấn vào tab "Tài khoản" ở thanh điều hướng dưới cùng
2. Chọn "Sản phẩm của tôi" trong danh sách tùy chọn
3. Xem danh sách các sản phẩm đã đăng
4. Nhấn vào sản phẩm cần chỉnh sửa hoặc xóa
5. Chọn "Chỉnh sửa" để cập nhật thông tin hoặc "Xóa" để gỡ sản phẩm khỏi sàn
''',
      'source_code': {
        'main_file': 'lib/screens/my_products_screen.dart',
        'related_files': [
          'lib/services/product_service.dart',
          'lib/screens/edit_product_screen.dart'
        ],
        'key_functions': '''
// MyProductsScreen - Màn hình hiển thị sản phẩm của người dùng
class MyProductsScreen extends StatefulWidget {
  @override
  _MyProductsScreenState createState() => _MyProductsScreenState();
}

// ProductService - Các phương thức quản lý sản phẩm
Future<List<Product>> getUserProducts(String userId) async {
  // Lấy danh sách sản phẩm của người dùng từ Firestore
}

Future<bool> updateProduct(String productId, Product updatedProduct) async {
  // Cập nhật thông tin sản phẩm trong Firestore
}

Future<bool> deleteProduct(String productId) async {
  // Xóa sản phẩm khỏi Firestore và các hình ảnh từ Storage
}
'''
      },
      'code_analysis': '''
Chức năng "Quản lý sản phẩm đã đăng" được triển khai qua:
1. MyProductsScreen: Hiển thị danh sách sản phẩm của người dùng
2. EditProductScreen: Cho phép chỉnh sửa thông tin sản phẩm
3. ProductService: Xử lý logic CRUD với Firestore

Cấu trúc dữ liệu sản phẩm trong Firestore:
- Collection "products" chứa tất cả sản phẩm
- Mỗi sản phẩm có trường "sellerId" liên kết với người bán
- Khi xóa sản phẩm, hệ thống cũng xóa hình ảnh liên quan trong Storage
'''
    },
    {
      'id': 'chat',
      'name': 'Trò chuyện',
      'description': 'Cho phép người dùng nhắn tin với người bán hoặc người mua',
      'available': true,
      'location': 'Tab "Chat" ở thanh điều hướng dưới cùng hoặc từ trang chi tiết sản phẩm',
      'guide': '''
1. Để chat với người bán: Vào trang chi tiết sản phẩm và nhấn "Chat với người bán"
2. Để xem các cuộc trò chuyện: Nhấn vào tab "Chat" ở thanh điều hướng dưới cùng
3. Chọn cuộc trò chuyện cần xem hoặc tiếp tục
4. Nhập tin nhắn vào ô nhập liệu phía dưới và nhấn biểu tượng gửi
''',
    },
    {
      'id': 'search',
      'name': 'Tìm kiếm sản phẩm',
      'description': 'Cho phép tìm kiếm sản phẩm theo từ khóa, danh mục và bộ lọc',
      'available': true,
      'location': 'Ô tìm kiếm ở thanh trên cùng của màn hình chính hoặc tab Tìm kiếm',
      'guide': '''
1. Nhấn vào ô tìm kiếm ở phía trên màn hình chính
2. Nhập từ khóa tìm kiếm
3. Sử dụng bộ lọc để lọc theo danh mục, giá, tình trạng sản phẩm
4. Xem kết quả tìm kiếm và nhấn vào sản phẩm để xem chi tiết
''',
    },
    {
      'id': 'purchase',
      'name': 'Mua hàng',
      'description': 'Cho phép thêm sản phẩm vào giỏ hàng và thanh toán',
      'available': true,
      'location': 'Từ trang chi tiết sản phẩm hoặc tab Giỏ hàng',
      'guide': '''
1. Vào trang chi tiết sản phẩm muốn mua
2. Nhấn "Thêm vào giỏ hàng" hoặc "Mua ngay"
3. Nếu thêm vào giỏ hàng, vào tab "Giỏ hàng" để xem
4. Nhấn "Thanh toán" để tiến hành thanh toán
5. Chọn phương thức thanh toán, nhập địa chỉ giao hàng và xác nhận đơn hàng
''',
    },
    {
      'id': 'review',
      'name': 'Đánh giá sản phẩm',
      'description': 'Cho phép đánh giá và cho điểm sản phẩm đã mua',
      'available': true,
      'location': 'Từ trang chi tiết đơn hàng đã hoàn thành hoặc trang chi tiết sản phẩm',
      'guide': '''
1. Vào trang "Đơn hàng" từ trang hồ sơ
2. Chọn đơn hàng đã hoàn thành
3. Nhấn "Đánh giá" bên cạnh sản phẩm
4. Cho điểm từ 1-5 sao và viết nhận xét về sản phẩm
5. Có thể đính kèm hình ảnh thực tế của sản phẩm (không bắt buộc)
6. Nhấn "Gửi đánh giá" để hoàn tất
''',
    },
  ];

  // Danh sách các chức năng chưa hỗ trợ nhưng dự định phát triển trong tương lai
  final List<Map<String, dynamic>> _plannedFeatures = [
    {
      'id': 'auction',
      'name': 'Đấu giá sản phẩm',
      'description': 'Cho phép người dùng tạo phiên đấu giá cho sản phẩm',
      'available': false,
      'planned_release': 'Quý 3/2027',
    },
    {
      'id': 'group_buy',
      'name': 'Mua hàng theo nhóm',
      'description': 'Cho phép người dùng tạo nhóm mua hàng để được giá ưu đãi',
      'available': false,
      'planned_release': 'Quý 4/2027',
    },
  ];

  // Đối tượng quản lý và phân tích mã nguồn
  final Map<String, String> _sourceCodeCache = {};
  final Map<String, dynamic> _codeAnalysisResults = {};

  // Thêm các phương thức liên quan đến mã nguồn
  
  /// Lấy mã nguồn của một chức năng
  Map<String, dynamic>? getFeatureSourceCode(String featureId) {
    for (var feature in _existingFeatures) {
      if (feature['id'] == featureId && feature.containsKey('source_code')) {
        return Map<String, dynamic>.from(feature['source_code']);
      }
    }
    return null;
  }
  
  /// Lấy phân tích mã nguồn của một chức năng
  String getFeatureCodeAnalysis(String featureId) {
    for (var feature in _existingFeatures) {
      if (feature['id'] == featureId && feature.containsKey('code_analysis')) {
        return feature['code_analysis'];
      }
    }
    return 'Chưa có phân tích mã nguồn cho chức năng này.';
  }
  
  /// Cập nhật phân tích mã nguồn cho một chức năng
  Future<void> updateFeatureCodeAnalysis(String featureId, String analysis) async {
    for (int i = 0; i < _existingFeatures.length; i++) {
      if (_existingFeatures[i]['id'] == featureId) {
        _existingFeatures[i]['code_analysis'] = analysis;
        
        // Cập nhật vào local storage và Firestore
        await _updateFeaturesData();
        
        notifyListeners();
        return;
      }
    }
  }
  
  /// Lấy toàn bộ mã nguồn của một file
  Future<String?> getSourceCodeFile(String filePath) async {
    // Kiểm tra trong cache trước
    if (_sourceCodeCache.containsKey(filePath)) {
      return _sourceCodeCache[filePath];
    }
    
    try {
      // Trong môi trường thực, có thể đọc file từ assets hoặc tải từ repository
      // Đây là mô phỏng - trong ứng dụng thực tế sẽ cần triển khai khác
      final snapshot = await _firestore.collection('source_code').doc(filePath.replaceAll('/', '_')).get();
      
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data.containsKey('content')) {
          _sourceCodeCache[filePath] = data['content'];
          return data['content'];
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Lỗi khi tải mã nguồn: $e');
      return null;
    }
  }
  
  /// Đăng tải mã nguồn lên Firestore (chỉ dành cho admin)
  Future<bool> uploadSourceCode(String filePath, String content) async {
    try {
      await _firestore.collection('source_code').doc(filePath.replaceAll('/', '_')).set({
        'content': content,
        'path': filePath,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      // Cập nhật cache
      _sourceCodeCache[filePath] = content;
      
      return true;
    } catch (e) {
      debugPrint('Lỗi khi đăng tải mã nguồn: $e');
      return false;
    }
  }
  
  /// Phân tích mã nguồn của một chức năng
  Future<String> analyzeFeatureCode(String featureId) async {
    final sourceCode = getFeatureSourceCode(featureId);
    if (sourceCode == null) {
      return 'Không có mã nguồn cho chức năng này.';
    }
    
    // Lấy nội dung của file chính
    final mainFile = sourceCode['main_file'];
    final mainContent = await getSourceCodeFile(mainFile);
    
    if (mainContent == null) {
      return 'Không thể tải mã nguồn của file chính.';
    }
    
    // Đơn giản hóa - trong thực tế sẽ dùng công cụ phân tích phức tạp hơn
    String analysis = 'Phân tích mã nguồn cho chức năng "$featureId":\n\n';
    
    // Phân tích đơn giản dựa trên các từ khóa
    if (mainContent.contains('class')) {
      analysis += '- Định nghĩa các class để xây dựng UI và logic\n';
    }
    
    if (mainContent.contains('setState')) {
      analysis += '- Sử dụng StatefulWidget để quản lý trạng thái\n';
    }
    
    if (mainContent.contains('FirebaseFirestore') || mainContent.contains('Firestore')) {
      analysis += '- Tích hợp với Firestore để lưu trữ dữ liệu\n';
    }
    
    if (mainContent.contains('Storage')) {
      analysis += '- Sử dụng Firebase Storage để lưu trữ hình ảnh\n';
    }
    
    // Lưu kết quả phân tích
    _codeAnalysisResults[featureId] = analysis;
    
    // Cập nhật vào feature
    await updateFeatureCodeAnalysis(featureId, analysis);
    
    return analysis;
  }
  
  /// Phân tích tất cả các chức năng có mã nguồn
  Future<Map<String, String>> analyzeAllFeaturesCode() async {
    final Map<String, String> results = {};
    
    for (var feature in _existingFeatures) {
      if (feature.containsKey('source_code')) {
        final analysis = await analyzeFeatureCode(feature['id']);
        results[feature['id']] = analysis;
      }
    }
    
    return results;
  }

  // Cache cho thông tin chức năng
  Map<String, dynamic> _featuresCache = {};
  
  // Kết nối Firestore (nếu lưu trữ thông tin trên cloud)
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Flag kiểm tra đã tải dữ liệu chưa
  bool _isLoaded = false;
  
  // Constructor
  AppFeaturesService() {
    _loadFeatureData();
  }
  
  // Getter cho danh sách chức năng
  List<Map<String, dynamic>> get existingFeatures => _existingFeatures;
  List<Map<String, dynamic>> get plannedFeatures => _plannedFeatures;
  
  // Phương thức để tải dữ liệu chức năng từ Firestore hoặc local storage
  Future<void> _loadFeatureData() async {
    if (_isLoaded) return;
    
    try {
      // Thử lấy từ local storage trước
      final prefs = await SharedPreferences.getInstance();
      final featureData = prefs.getString('app_features_data');
      
      if (featureData != null) {
        _featuresCache = json.decode(featureData);
        _isLoaded = true;
        notifyListeners();
        return;
      }
      
      // Nếu không có trong local, thử lấy từ Firestore
      try {
        final snapshot = await _firestore.collection('app_features').doc('config').get();
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null) {
            _featuresCache = data;
            
            // Lưu vào local storage để dùng offline
            await prefs.setString('app_features_data', json.encode(data));
            
            _isLoaded = true;
            notifyListeners();
            return;
          }
        }
      } catch (e) {
        debugPrint('Lỗi khi tải dữ liệu từ Firestore: $e');
      }
      
      // Nếu không lấy được từ đâu, sử dụng dữ liệu mặc định
      await _saveDefaultFeatures();
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Lỗi khi tải dữ liệu chức năng: $e');
    }
  }
  
  // Lưu dữ liệu mặc định
  Future<void> _saveDefaultFeatures() async {
    try {
      // Tạo dữ liệu mặc định
      final defaultData = {
        'existing_features': _existingFeatures,
        'planned_features': _plannedFeatures,
        'last_updated': DateTime.now().millisecondsSinceEpoch,
      };
      
      // Lưu vào local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_features_data', json.encode(defaultData));
      
      // Lưu vào Firestore nếu có thể
      try {
        await _firestore.collection('app_features').doc('config').set(defaultData);
      } catch (e) {
        debugPrint('Lỗi khi lưu dữ liệu lên Firestore: $e');
      }
      
      _featuresCache = defaultData;
    } catch (e) {
      debugPrint('Lỗi khi lưu dữ liệu mặc định: $e');
    }
  }
  
  // Cập nhật dữ liệu chức năng
  Future<void> _updateFeaturesData() async {
    try {
      // Cập nhật dữ liệu
      final updatedData = {
        'existing_features': _existingFeatures,
        'planned_features': _plannedFeatures,
        'last_updated': DateTime.now().millisecondsSinceEpoch,
      };
      
      // Lưu vào local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_features_data', json.encode(updatedData));
      
      // Cập nhật lên Firestore
      try {
        await _firestore.collection('app_features').doc('config').update(updatedData);
      } catch (e) {
        debugPrint('Lỗi khi cập nhật dữ liệu lên Firestore: $e');
      }
      
      _featuresCache = updatedData;
    } catch (e) {
      debugPrint('Lỗi khi cập nhật dữ liệu chức năng: $e');
    }
  }
  
  /// Kiểm tra xem một chức năng có tồn tại không
  bool isFeatureAvailable(String featureId) {
    // Tìm trong danh sách chức năng hiện có
    for (var feature in _existingFeatures) {
      if (feature['id'] == featureId && feature['available'] == true) {
        return true;
      }
    }
    return false;
  }
  
  /// Lấy thông tin hướng dẫn sử dụng chức năng
  String getFeatureGuide(String featureId) {
    // Tìm chức năng trong danh sách
    for (var feature in _existingFeatures) {
      if (feature['id'] == featureId) {
        return feature['guide'] ?? 'Chưa có hướng dẫn cho chức năng này.';
      }
    }
    return 'Không tìm thấy thông tin về chức năng này.';
  }
  
  /// Lấy thông tin về tất cả các chức năng hiện có
  String getAllFeaturesInfo() {
    String info = 'THÔNG TIN VỀ CÁC CHỨC NĂNG CỦA ỨNG DỤNG:\n\n';
    
    for (var feature in _existingFeatures) {
      info += '- ${feature['name']}: ${feature['description']}\n';
      info += '  Vị trí: ${feature['location']}\n\n';
    }
    
    return info;
  }
  
  /// Lấy thông tin chi tiết về một chức năng
  Map<String, dynamic>? getFeatureDetails(String featureId) {
    // Tìm trong danh sách chức năng hiện có
    for (var feature in _existingFeatures) {
      if (feature['id'] == featureId) {
        return Map<String, dynamic>.from(feature);
      }
    }
    
    // Tìm trong danh sách chức năng dự kiến
    for (var feature in _plannedFeatures) {
      if (feature['id'] == featureId) {
        return Map<String, dynamic>.from(feature);
      }
    }
    
    return null;
  }
  
  /// Tìm kiếm chức năng theo từ khóa
  List<Map<String, dynamic>> searchFeatures(String keyword) {
    final List<Map<String, dynamic>> results = [];
    final lowercaseKeyword = keyword.toLowerCase();
    
    // Tìm trong danh sách chức năng hiện có
    for (var feature in _existingFeatures) {
      if (feature['name'].toString().toLowerCase().contains(lowercaseKeyword) ||
          feature['description'].toString().toLowerCase().contains(lowercaseKeyword)) {
        results.add(Map<String, dynamic>.from(feature));
      }
    }
    
    return results;
  }
  
  /// Cập nhật thông tin về chức năng (cho admin)
  Future<void> updateFeature(String featureId, Map<String, dynamic> newData) async {
    try {
      // Tìm và cập nhật trong danh sách chức năng hiện có
      for (int i = 0; i < _existingFeatures.length; i++) {
        if (_existingFeatures[i]['id'] == featureId) {
          _existingFeatures[i] = {..._existingFeatures[i], ...newData};
          
          // Cập nhật dữ liệu
          await _updateFeaturesData();
          
          notifyListeners();
          return;
        }
      }
      
      // Tìm và cập nhật trong danh sách chức năng dự kiến
      for (int i = 0; i < _plannedFeatures.length; i++) {
        if (_plannedFeatures[i]['id'] == featureId) {
          _plannedFeatures[i] = {..._plannedFeatures[i], ...newData};
          
          // Cập nhật dữ liệu
          await _updateFeaturesData();
          
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      debugPrint('Lỗi khi cập nhật chức năng: $e');
    }
  }
  
  /// Kiểm tra và cập nhật dữ liệu định kỳ
  Future<void> refreshFeatureData() async {
    try {
      // Kiểm tra xem dữ liệu có cần làm mới không
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('app_features_data');
      
      if (cachedData != null) {
        final cachedJson = json.decode(cachedData);
        final lastUpdated = cachedJson['last_updated'] ?? 0;
        
        // Nếu dữ liệu đã được cập nhật trong vòng 24 giờ, không cần làm mới
        if (DateTime.now().millisecondsSinceEpoch - lastUpdated < 24 * 60 * 60 * 1000) {
          return;
        }
      }
      
      // Lấy dữ liệu mới từ Firestore
      try {
        final snapshot = await _firestore.collection('app_features').doc('config').get();
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null) {
            // Cập nhật dữ liệu
            if (data['existing_features'] != null) {
              // Chuyển đổi từ dynamic -> List<Map<String, dynamic>>
              final List<dynamic> dynamicList = data['existing_features'];
              final List<Map<String, dynamic>> typedList = dynamicList.map((item) => 
                Map<String, dynamic>.from(item)).toList();
              
              // Cập nhật danh sách
              _existingFeatures.clear();
              _existingFeatures.addAll(typedList);
            }
            
            if (data['planned_features'] != null) {
              // Chuyển đổi từ dynamic -> List<Map<String, dynamic>>
              final List<dynamic> dynamicList = data['planned_features'];
              final List<Map<String, dynamic>> typedList = dynamicList.map((item) => 
                Map<String, dynamic>.from(item)).toList();
              
              // Cập nhật danh sách
              _plannedFeatures.clear();
              _plannedFeatures.addAll(typedList);
            }
            
            // Lưu vào local storage
            await prefs.setString('app_features_data', json.encode(data));
            
            _featuresCache = data;
            notifyListeners();
          }
        }
      } catch (e) {
        debugPrint('Lỗi khi làm mới dữ liệu từ Firestore: $e');
      }
    } catch (e) {
      debugPrint('Lỗi khi làm mới dữ liệu chức năng: $e');
    }
  }
} 