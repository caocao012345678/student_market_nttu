import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service quản lý thông tin về bố cục và chức năng của ứng dụng
/// để sử dụng cho RAG (Retrieval Augmented Generation)
class AppLayoutService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Danh sách các màn hình chính trong ứng dụng
  final List<Map<String, dynamic>> _appScreens = [];
  
  // Danh sách các chức năng trong ứng dụng
  final List<Map<String, dynamic>> _appFeatures = [];
  
  // Trạng thái
  bool _isLoading = false;
  String _error = '';
  bool _isInitialized = false;
  
  // Getters
  List<Map<String, dynamic>> get appScreens => _appScreens;
  List<Map<String, dynamic>> get appFeatures => _appFeatures;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get isInitialized => _isInitialized;
  
  AppLayoutService() {
    // Tự động khởi tạo dữ liệu khi service được tạo
    initializeAppData();
  }
  
  /// Khởi tạo dữ liệu về bố cục ứng dụng
  Future<void> initializeAppData() async {
    if (_isInitialized) return;
    
    _isLoading = true;
    _error = '';
    notifyListeners();
    
    try {
      // Kiểm tra xem đã có dữ liệu trong Firestore chưa
      final layoutDoc = await _firestore.collection('app_settings').doc('layout').get();
      
      if (layoutDoc.exists) {
        // Nếu đã có, lấy dữ liệu từ Firestore
        await _loadAppDataFromFirestore();
      } else {
        // Nếu chưa có, khởi tạo dữ liệu mặc định và lưu vào Firestore
        await _initializeDefaultAppData();
      }
      
      _isInitialized = true;
    } catch (e) {
      _error = 'Lỗi khi khởi tạo dữ liệu bố cục ứng dụng: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Tạo dữ liệu mặc định về bố cục ứng dụng
  Future<void> _initializeDefaultAppData() async {
    // Danh sách màn hình chính
    _appScreens.clear();
    _appScreens.addAll([
      {
        'id': 'home_screen',
        'name': 'Trang chủ',
        'route': '/',
        'description': 'Màn hình chính hiển thị danh sách sản phẩm nổi bật, danh mục và các đề xuất.',
        'features': ['product_list', 'categories', 'search_bar', 'promotion_banner'],
        'navigation': 'bottom_nav_bar'
      },
      {
        'id': 'product_screen',
        'name': 'Chi tiết sản phẩm',
        'route': '/product/:id',
        'description': 'Hiển thị thông tin chi tiết về sản phẩm, gồm hình ảnh, mô tả, giá cả, đánh giá và các sản phẩm liên quan.',
        'features': ['product_details', 'reviews', 'add_to_cart', 'contact_seller'],
        'navigation': 'back_button'
      },
      {
        'id': 'category_screen',
        'name': 'Danh mục',
        'route': '/category/:id',
        'description': 'Hiển thị danh sách sản phẩm trong một danh mục cụ thể, có thể lọc và sắp xếp.',
        'features': ['filter', 'sort', 'product_grid', 'search_in_category'],
        'navigation': 'bottom_nav_bar'
      },
      {
        'id': 'cart_screen',
        'name': 'Giỏ hàng',
        'route': '/cart',
        'description': 'Hiển thị sản phẩm đã thêm vào giỏ hàng, cho phép cập nhật số lượng và thanh toán.',
        'features': ['cart_items', 'update_quantity', 'checkout', 'remove_item'],
        'navigation': 'bottom_nav_bar'
      },
      {
        'id': 'profile_screen',
        'name': 'Trang cá nhân',
        'route': '/profile',
        'description': 'Hiển thị thông tin cá nhân, lịch sử mua hàng, sản phẩm đã đăng và các cài đặt.',
        'features': ['user_info', 'order_history', 'posted_products', 'settings'],
        'navigation': 'bottom_nav_bar'
      },
      {
        'id': 'chat_screen',
        'name': 'Tin nhắn',
        'route': '/chat',
        'description': 'Danh sách các cuộc trò chuyện với người bán/người mua.',
        'features': ['chat_list', 'message_notification'],
        'navigation': 'bottom_nav_bar'
      },
      {
        'id': 'chatbot_screen',
        'name': 'Trợ lý ảo',
        'route': '/chatbot',
        'description': 'Trợ lý ảo sử dụng Gemini API để hỗ trợ người dùng tìm kiếm và sử dụng ứng dụng.',
        'features': ['ai_assistant', 'product_recommendations', 'app_usage_guide'],
        'navigation': 'bottom_nav_bar'
      },
      {
        'id': 'order_screen',
        'name': 'Đơn hàng',
        'route': '/order/:id',
        'description': 'Hiển thị chi tiết đơn hàng, trạng thái và thông tin vận chuyển.',
        'features': ['order_details', 'shipping_info', 'cancel_order', 'track_order'],
        'navigation': 'back_button'
      },
      {
        'id': 'search_results_screen',
        'name': 'Kết quả tìm kiếm',
        'route': '/search',
        'description': 'Hiển thị kết quả tìm kiếm sản phẩm với các bộ lọc.',
        'features': ['search_results', 'filter_options', 'sort_options'],
        'navigation': 'back_button'
      },
      {
        'id': 'notifications_screen',
        'name': 'Thông báo',
        'route': '/notifications',
        'description': 'Hiển thị danh sách thông báo về đơn hàng, khuyến mãi và cập nhật từ người bán.',
        'features': ['notification_list', 'mark_as_read', 'delete_notification'],
        'navigation': 'back_button'
      }
    ]);
    
    // Danh sách các chức năng chính
    _appFeatures.clear();
    _appFeatures.addAll([
      {
        'id': 'product_list',
        'name': 'Danh sách sản phẩm',
        'description': 'Hiển thị danh sách sản phẩm dưới dạng lưới hoặc danh sách.',
        'location': 'home_screen, category_screen, search_results_screen',
        'usage': 'Xem các sản phẩm, nhấn vào để xem chi tiết.'
      },
      {
        'id': 'search_bar',
        'name': 'Thanh tìm kiếm',
        'description': 'Cho phép tìm kiếm sản phẩm theo tên, mô tả hoặc danh mục.',
        'location': 'home_screen, appbar',
        'usage': 'Nhập từ khóa và nhấn biểu tượng tìm kiếm.'
      },
      {
        'id': 'categories',
        'name': 'Danh mục sản phẩm',
        'description': 'Hiển thị các danh mục sản phẩm để dễ dàng lọc.',
        'location': 'home_screen, drawer_menu',
        'usage': 'Nhấn vào danh mục để xem sản phẩm trong danh mục đó.'
      },
      {
        'id': 'cart_items',
        'name': 'Giỏ hàng',
        'description': 'Hiển thị sản phẩm đã thêm vào giỏ hàng.',
        'location': 'cart_screen',
        'usage': 'Cập nhật số lượng, xóa sản phẩm hoặc tiến hành thanh toán.'
      },
      {
        'id': 'checkout',
        'name': 'Thanh toán',
        'description': 'Quy trình thanh toán đơn hàng, bao gồm địa chỉ, phương thức thanh toán và xác nhận.',
        'location': 'cart_screen, checkout_screen',
        'usage': 'Nhập thông tin thanh toán và xác nhận để hoàn tất đơn hàng.'
      },
      {
        'id': 'user_info',
        'name': 'Thông tin người dùng',
        'description': 'Hiển thị và cho phép cập nhật thông tin cá nhân.',
        'location': 'profile_screen',
        'usage': 'Xem và chỉnh sửa thông tin cá nhân như tên, địa chỉ, ảnh đại diện.'
      },
      {
        'id': 'order_history',
        'name': 'Lịch sử đơn hàng',
        'description': 'Danh sách các đơn hàng đã đặt và trạng thái.',
        'location': 'profile_screen, order_history_screen',
        'usage': 'Xem chi tiết đơn hàng và theo dõi trạng thái.'
      },
      {
        'id': 'posted_products',
        'name': 'Sản phẩm đã đăng',
        'description': 'Danh sách sản phẩm người dùng đã đăng bán.',
        'location': 'profile_screen, my_products_screen',
        'usage': 'Quản lý sản phẩm đã đăng, chỉnh sửa hoặc xóa.'
      },
      {
        'id': 'chat_list',
        'name': 'Danh sách tin nhắn',
        'description': 'Hiển thị các cuộc trò chuyện với người bán/người mua.',
        'location': 'chat_screen',
        'usage': 'Nhấn vào cuộc trò chuyện để xem và gửi tin nhắn.'
      },
      {
        'id': 'ai_assistant',
        'name': 'Trợ lý ảo',
        'description': 'Trợ lý ảo sử dụng Gemini API để trả lời câu hỏi và hỗ trợ người dùng.',
        'location': 'chatbot_screen',
        'usage': 'Nhập câu hỏi và nhận câu trả lời từ trợ lý ảo.'
      },
      {
        'id': 'product_recommendations',
        'name': 'Gợi ý sản phẩm',
        'description': 'Đề xuất sản phẩm dựa trên lịch sử duyệt, mua hàng và sở thích.',
        'location': 'home_screen, product_screen, chatbot_screen',
        'usage': 'Xem sản phẩm được đề xuất và nhấn để xem chi tiết.'
      },
      {
        'id': 'filter_options',
        'name': 'Bộ lọc tìm kiếm',
        'description': 'Cho phép lọc sản phẩm theo giá, đánh giá, tình trạng, v.v.',
        'location': 'category_screen, search_results_screen',
        'usage': 'Nhấn vào biểu tượng lọc, chọn các tiêu chí và áp dụng.'
      },
      {
        'id': 'sort_options',
        'name': 'Sắp xếp kết quả',
        'description': 'Sắp xếp sản phẩm theo giá, mức độ phổ biến, đánh giá, v.v.',
        'location': 'category_screen, search_results_screen',
        'usage': 'Chọn tùy chọn sắp xếp từ menu thả xuống.'
      },
      {
        'id': 'notification_list',
        'name': 'Danh sách thông báo',
        'description': 'Hiển thị các thông báo về đơn hàng, khuyến mãi và cập nhật.',
        'location': 'notifications_screen',
        'usage': 'Xem thông báo và nhấn để xem chi tiết.'
      }
    ]);
    
    // Lưu dữ liệu vào Firestore
    await _saveAppDataToFirestore();
  }
  
  /// Lưu dữ liệu bố cục ứng dụng vào Firestore
  Future<void> _saveAppDataToFirestore() async {
    try {
      await _firestore.collection('app_settings').doc('layout').set({
        'app_screens': _appScreens,
        'app_features': _appFeatures,
        'last_updated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Lỗi khi lưu dữ liệu bố cục ứng dụng: $e');
      throw Exception('Không thể lưu dữ liệu bố cục ứng dụng: $e');
    }
  }
  
  /// Tải dữ liệu bố cục ứng dụng từ Firestore
  Future<void> _loadAppDataFromFirestore() async {
    try {
      final layoutDoc = await _firestore.collection('app_settings').doc('layout').get();
      
      if (layoutDoc.exists) {
        final data = layoutDoc.data();
        
        if (data != null) {
          // Cập nhật danh sách màn hình
          _appScreens.clear();
          
          if (data['app_screens'] != null) {
            for (var screen in data['app_screens']) {
              _appScreens.add(Map<String, dynamic>.from(screen));
            }
          }
          
          // Cập nhật danh sách chức năng
          _appFeatures.clear();
          
          if (data['app_features'] != null) {
            for (var feature in data['app_features']) {
              _appFeatures.add(Map<String, dynamic>.from(feature));
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Lỗi khi tải dữ liệu bố cục ứng dụng: $e');
      throw Exception('Không thể tải dữ liệu bố cục ứng dụng: $e');
    }
  }
  
  /// Thêm màn hình mới vào danh sách
  Future<void> addScreen(Map<String, dynamic> screen) async {
    _appScreens.add(screen);
    await _saveAppDataToFirestore();
    notifyListeners();
  }
  
  /// Thêm chức năng mới vào danh sách
  Future<void> addFeature(Map<String, dynamic> feature) async {
    _appFeatures.add(feature);
    await _saveAppDataToFirestore();
    notifyListeners();
  }
  
  /// Lấy thông tin về một màn hình cụ thể theo ID
  Map<String, dynamic>? getScreenById(String id) {
    try {
      return _appScreens.firstWhere((screen) => screen['id'] == id);
    } catch (e) {
      return null;
    }
  }
  
  /// Lấy thông tin về một chức năng cụ thể theo ID
  Map<String, dynamic>? getFeatureById(String id) {
    try {
      return _appFeatures.firstWhere((feature) => feature['id'] == id);
    } catch (e) {
      return null;
    }
  }
  
  /// Tạo hướng dẫn sử dụng ứng dụng dựa trên màn hình cụ thể
  String generateUsageGuideForScreen(String screenId) {
    final screen = getScreenById(screenId);
    if (screen == null) return 'Không tìm thấy thông tin về màn hình này.';
    
    String guide = 'Hướng dẫn sử dụng màn hình ${screen['name']}:\n\n';
    guide += '${screen['description']}\n\n';
    
    guide += 'Các chức năng có sẵn:\n';
    
    if (screen['features'] != null) {
      for (var featureId in screen['features']) {
        final feature = getFeatureById(featureId);
        if (feature != null) {
          guide += '- ${feature['name']}: ${feature['description']} - ${feature['usage']}\n';
        }
      }
    }
    
    return guide;
  }
  
  /// Tạo hướng dẫn sử dụng cho một chức năng cụ thể
  String generateUsageGuideForFeature(String featureId) {
    final feature = getFeatureById(featureId);
    if (feature == null) return 'Không tìm thấy thông tin về chức năng này.';
    
    String guide = 'Hướng dẫn sử dụng chức năng ${feature['name']}:\n\n';
    guide += '${feature['description']}\n\n';
    guide += 'Vị trí: ${feature['location']}\n';
    guide += 'Cách sử dụng: ${feature['usage']}\n';
    
    return guide;
  }
  
  /// Tạo mô tả tổng quan về ứng dụng
  String generateAppOverview() {
    String overview = 'Tổng quan về ứng dụng Student Market NTTU:\n\n';
    
    overview += 'Student Market NTTU là ứng dụng mua bán đồ cũ cho sinh viên trường Đại học Nguyễn Tất Thành. ';
    overview += 'Ứng dụng cho phép sinh viên đăng bán, tìm kiếm và mua các sản phẩm từ những sinh viên khác.\n\n';
    
    overview += 'Các màn hình chính trong ứng dụng:\n';
    for (var screen in _appScreens) {
      overview += '- ${screen['name']}: ${screen['description']}\n';
    }
    
    overview += '\nCác chức năng chính của ứng dụng:\n';
    for (var feature in _appFeatures) {
      overview += '- ${feature['name']}: ${feature['description']}\n';
    }
    
    return overview;
  }
} 