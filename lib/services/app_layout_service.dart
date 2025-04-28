import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service quản lý thông tin về bố cục và chức năng của ứng dụng
/// để sử dụng cho RAG (Retrieval Augmented Generation)
class AppLayoutService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Danh sách màn hình trong ứng dụng
  final List<Map<String, dynamic>> _appScreens = [
    {
      'id': 'home',
      'name': 'Màn hình chính',
      'description': 'Hiển thị sản phẩm nổi bật, danh mục và các tính năng chính',
      'route': '/home',
      'component_path': 'lib/screens/home_screen.dart',
    },
    {
      'id': 'search',
      'name': 'Tìm kiếm',
      'description': 'Cho phép tìm kiếm sản phẩm theo từ khóa, danh mục và bộ lọc',
      'route': '/search',
      'component_path': 'lib/screens/search_screen.dart',
    },
    {
      'id': 'product_detail',
      'name': 'Chi tiết sản phẩm',
      'description': 'Hiển thị thông tin chi tiết về một sản phẩm cụ thể',
      'route': '/product/:id',
      'component_path': 'lib/screens/product_detail_screen.dart',
    },
    {
      'id': 'cart',
      'name': 'Giỏ hàng',
      'description': 'Quản lý sản phẩm trong giỏ hàng và tiến hành thanh toán',
      'route': '/cart',
      'component_path': 'lib/screens/cart_screen.dart',
    },
    {
      'id': 'chat',
      'name': 'Trò chuyện',
      'description': 'Cho phép nhắn tin với người bán hoặc người mua',
      'route': '/chat',
      'component_path': 'lib/screens/chat_list_screen.dart',
    },
    {
      'id': 'chat_detail',
      'name': 'Chi tiết trò chuyện',
      'description': 'Màn hình nhắn tin với một người dùng cụ thể',
      'route': '/chat/:id',
      'component_path': 'lib/screens/chat_screen.dart',
    },
    {
      'id': 'profile',
      'name': 'Hồ sơ cá nhân',
      'description': 'Xem và chỉnh sửa thông tin cá nhân, quản lý sản phẩm và đơn hàng',
      'route': '/profile',
      'component_path': 'lib/screens/profile_screen.dart',
    },
    {
      'id': 'add_product',
      'name': 'Thêm sản phẩm',
      'description': 'Đăng bán sản phẩm mới',
      'route': '/add-product',
      'component_path': 'lib/screens/add_product_screen.dart',
    },
    {
      'id': 'my_products',
      'name': 'Sản phẩm của tôi',
      'description': 'Quản lý các sản phẩm đã đăng bán',
      'route': '/my-products',
      'component_path': 'lib/screens/my_products_screen.dart',
    },
    {
      'id': 'favorites',
      'name': 'Sản phẩm yêu thích',
      'description': 'Xem các sản phẩm đã đánh dấu yêu thích',
      'route': '/favorites',
      'component_path': 'lib/screens/favorite_products_screen.dart',
    },
    {
      'id': 'orders',
      'name': 'Lịch sử đơn hàng',
      'description': 'Xem lịch sử các đơn hàng đã mua và bán',
      'route': '/orders',
      'component_path': 'lib/screens/order_history_screen.dart',
    },
    {
      'id': 'settings',
      'name': 'Cài đặt',
      'description': 'Thay đổi cài đặt ứng dụng, ngôn ngữ và chế độ màu',
      'route': '/settings',
      'component_path': 'lib/screens/settings_screen.dart',
    },
    {
      'id': 'chatbot',
      'name': 'Trợ lý ảo',
      'description': 'Tương tác với trợ lý ảo để được hỗ trợ',
      'route': '/chatbot',
      'component_path': 'lib/screens/chatbot_screen.dart',
    },
  ];

  // Danh sách chi tiết về các tính năng
  final List<Map<String, dynamic>> _appFeatures = [
    {
      'id': 'product_search',
      'name': 'Tìm kiếm sản phẩm',
      'description': 'Cho phép tìm kiếm sản phẩm theo từ khóa, danh mục và bộ lọc',
      'location': 'Nút kính lúp ở góc phải trên cùng của màn hình chính hoặc tab Tìm kiếm',
      'usage': 'Nhấn vào nút, nhập từ khóa và nhấn Enter để tìm kiếm',
      'screen_id': 'search',
      'user_tasks': ['Tìm sản phẩm cụ thể', 'Lọc sản phẩm theo giá', 'Tìm theo danh mục', 'Tìm kiếm sản phẩm', 'Tra cứu sản phẩm', 'Tìm đồ', 'Tìm đồ cũ'],
    },
    {
      'id': 'add_to_cart',
      'name': 'Thêm vào giỏ hàng',
      'description': 'Thêm sản phẩm vào giỏ hàng để mua sau',
      'location': 'Nút "Thêm vào giỏ hàng" trên màn hình chi tiết sản phẩm',
      'usage': 'Xem chi tiết sản phẩm, chọn số lượng và nhấn "Thêm vào giỏ hàng"',
      'screen_id': 'product_detail',
      'user_tasks': ['Mua sản phẩm', 'Tích lũy giỏ hàng', 'Thêm đồ vào giỏ', 'Thêm vào giỏ', 'Mua hàng'],
    },
    {
      'id': 'chat_with_seller',
      'name': 'Trò chuyện với người bán',
      'description': 'Liên hệ trực tiếp với người bán để trao đổi về sản phẩm',
      'location': 'Nút "Chat với người bán" trên màn hình chi tiết sản phẩm',
      'usage': 'Xem chi tiết sản phẩm, nhấn "Chat với người bán", nhập tin nhắn và gửi',
      'screen_id': 'product_detail',
      'user_tasks': ['Hỏi thông tin sản phẩm', 'Thương lượng giá', 'Kiểm tra tình trạng', 'Chat với người bán', 'Liên hệ người bán', 'Nhắn tin người bán'],
    },
    {
      'id': 'add_product',
      'name': 'Đăng bán sản phẩm',
      'description': 'Đăng thông tin sản phẩm để bán trên sàn',
      'location': 'Nút "+" ở góc dưới phải hoặc từ trang hồ sơ "Sản phẩm của tôi"',
      'usage': 'Nhấn nút +, điền thông tin sản phẩm, thêm hình ảnh và nhấn "Đăng bán"',
      'screen_id': 'add_product',
      'user_tasks': ['Đăng sản phẩm mới', 'Đăng lại sản phẩm', 'Bán đồ', 'Đăng bán', 'Bán sản phẩm', 'Làm sao để đăng bán', 'Cách đăng sản phẩm', 'Đăng bán sản phẩm', 'Bán hàng', 'Tôi muốn bán đồ'],
    },
    {
      'id': 'manage_products',
      'name': 'Quản lý sản phẩm đã đăng',
      'description': 'Xem, chỉnh sửa, hoặc xóa các sản phẩm đã đăng bán',
      'location': 'Mục "Sản phẩm của tôi" trong trang hồ sơ',
      'usage': 'Vào trang hồ sơ, chọn "Sản phẩm của tôi", sau đó có thể chỉnh sửa hoặc xóa sản phẩm',
      'screen_id': 'my_products',
      'user_tasks': ['Quản lý sản phẩm', 'Sửa thông tin sản phẩm', 'Xóa sản phẩm', 'Kiểm tra sản phẩm đã đăng', 'Xem sản phẩm của tôi', 'Làm sao để quản lý sản phẩm', 'Xem đồ đang bán'],
    },
    {
      'id': 'favorite_product',
      'name': 'Yêu thích sản phẩm',
      'description': 'Lưu sản phẩm vào danh sách yêu thích để xem sau',
      'location': 'Biểu tượng trái tim trên thẻ sản phẩm hoặc trang chi tiết',
      'usage': 'Nhấn vào biểu tượng trái tim để thêm/xóa khỏi yêu thích',
      'screen_id': 'product_detail',
      'user_tasks': ['Lưu sản phẩm để xem sau', 'Theo dõi giá', 'Thêm vào yêu thích', 'Đánh dấu sản phẩm', 'Lưu đồ yêu thích'],
    },
    {
      'id': 'checkout',
      'name': 'Thanh toán',
      'description': 'Hoàn tất quá trình mua hàng và thanh toán',
      'location': 'Nút "Thanh toán" ở phía dưới màn hình giỏ hàng',
      'usage': 'Kiểm tra giỏ hàng, nhấn "Thanh toán", chọn phương thức thanh toán và xác nhận',
      'screen_id': 'cart',
      'user_tasks': ['Hoàn tất mua hàng', 'Chọn địa chỉ giao hàng', 'Chọn phương thức thanh toán', 'Thanh toán đơn hàng', 'Mua hàng', 'Trả tiền', 'Cách thanh toán'],
    },
    {
      'id': 'view_orders',
      'name': 'Xem đơn hàng',
      'description': 'Xem lịch sử đơn hàng đã mua và đã bán',
      'location': 'Tab "Đơn hàng" trong trang hồ sơ',
      'usage': 'Vào trang hồ sơ, chọn "Đơn hàng" để xem danh sách',
      'screen_id': 'orders',
      'user_tasks': ['Kiểm tra tình trạng đơn hàng', 'Xem lịch sử mua hàng', 'Lịch sử đơn hàng', 'Đơn hàng của tôi', 'Xem các đơn đã đặt', 'Xem đơn hàng đã bán'],
    },
    {
      'id': 'edit_profile',
      'name': 'Chỉnh sửa hồ sơ',
      'description': 'Cập nhật thông tin cá nhân và hồ sơ người dùng',
      'location': 'Nút "Chỉnh sửa" trong trang hồ sơ',
      'usage': 'Vào trang hồ sơ, nhấn "Chỉnh sửa", thay đổi thông tin và lưu',
      'screen_id': 'profile',
      'user_tasks': ['Cập nhật thông tin cá nhân', 'Thay đổi ảnh đại diện', 'Sửa tên người dùng', 'Cập nhật số điện thoại', 'Sửa địa chỉ', 'Sửa hồ sơ'],
    },
    {
      'id': 'activate_darkmode',
      'name': 'Chế độ tối',
      'description': 'Chuyển đổi giao diện ứng dụng giữa chế độ sáng và tối',
      'location': 'Công tắc trong trang cài đặt',
      'usage': 'Vào trang cài đặt, bật/tắt công tắc "Chế độ tối"',
      'screen_id': 'settings',
      'user_tasks': ['Thay đổi giao diện', 'Giảm ánh sáng màn hình', 'Bật chế độ tối', 'Chuyển sang màu tối', 'Đổi giao diện'],
    },
    {
      'id': 'rate_product',
      'name': 'Đánh giá sản phẩm',
      'description': 'Viết đánh giá và cho điểm sản phẩm đã mua',
      'location': 'Nút "Đánh giá" trong lịch sử đơn hàng hoặc trang chi tiết sản phẩm',
      'usage': 'Vào đơn hàng đã hoàn thành, chọn "Đánh giá", cho điểm và viết nhận xét',
      'screen_id': 'product_detail',
      'user_tasks': ['Cho điểm sản phẩm', 'Viết nhận xét', 'Chia sẻ hình ảnh thực tế', 'Đánh giá người bán', 'Review sản phẩm', 'Viết review'],
    },
  ];

  // Thông tin về việc điều hướng giữa các màn hình
  final List<Map<String, dynamic>> navigationPaths = [
    {
      'from_screen_id': 'home',
      'to_screen_id': 'search',
      'method': 'Nhấn vào biểu tượng kính lúp ở thanh tìm kiếm phía trên',
      'ui_elements': ['search_bar', 'search_icon'],
    },
    {
      'from_screen_id': 'home',
      'to_screen_id': 'cart',
      'method': 'Nhấn vào biểu tượng giỏ hàng ở góc phải trên cùng hoặc tab Giỏ hàng',
      'ui_elements': ['cart_icon', 'bottom_nav_cart'],
    },
    {
      'from_screen_id': 'home',
      'to_screen_id': 'profile',
      'method': 'Nhấn vào tab Tài khoản ở thanh điều hướng dưới cùng',
      'ui_elements': ['bottom_nav_profile'],
    },
    {
      'from_screen_id': 'home',
      'to_screen_id': 'product_detail',
      'method': 'Nhấn vào bất kỳ sản phẩm nào trên màn hình chính',
      'ui_elements': ['product_card'],
    },
    {
      'from_screen_id': 'home',
      'to_screen_id': 'chat',
      'method': 'Nhấn vào tab Chat ở thanh điều hướng dưới cùng',
      'ui_elements': ['bottom_nav_chat'],
    },
    {
      'from_screen_id': 'home',
      'to_screen_id': 'chatbot',
      'method': 'Nhấn vào biểu tượng trợ lý ảo ở góc dưới phải',
      'ui_elements': ['chatbot_fab'],
    },
    {
      'from_screen_id': 'profile',
      'to_screen_id': 'my_products',
      'method': 'Nhấn vào mục "Sản phẩm của tôi" trong trang hồ sơ',
      'ui_elements': ['my_products_tile'],
    },
    {
      'from_screen_id': 'profile',
      'to_screen_id': 'orders',
      'method': 'Nhấn vào mục "Đơn hàng" trong trang hồ sơ',
      'ui_elements': ['orders_tile'],
    },
    {
      'from_screen_id': 'product_detail',
      'to_screen_id': 'cart',
      'method': 'Nhấn vào nút "Thêm vào giỏ hàng" và sau đó vào biểu tượng giỏ hàng',
      'ui_elements': ['add_to_cart_button', 'cart_icon'],
    },
    {
      'from_screen_id': 'cart',
      'to_screen_id': 'checkout',
      'method': 'Nhấn vào nút "Thanh toán" ở dưới cùng của màn hình giỏ hàng',
      'ui_elements': ['checkout_button'],
    },
  ];

  // Thông tin về các UI component chính
  final List<Map<String, dynamic>> uiComponents = [
    {
      'id': 'bottom_navigation',
      'name': 'Thanh điều hướng dưới cùng',
      'type': 'BottomNavigationBar',
      'description': 'Thanh điều hướng chính giữa các màn hình',
      'locations': ['Phần dưới cùng của ứng dụng'],
      'child_elements': ['home_tab', 'search_tab', 'cart_tab', 'chat_tab', 'profile_tab'],
    },
    {
      'id': 'app_drawer',
      'name': 'Menu trượt',
      'type': 'Drawer',
      'description': 'Menu trượt từ trái sang phải chứa các tùy chọn',
      'locations': ['Có thể truy cập từ biểu tượng menu ở góc trái trên cùng'],
      'child_elements': ['home_item', 'categories_item', 'settings_item', 'help_item'],
    },
    {
      'id': 'product_card',
      'name': 'Thẻ sản phẩm',
      'type': 'Card',
      'description': 'Hiển thị thông tin tóm tắt về sản phẩm',
      'locations': ['Màn hình chính', 'Kết quả tìm kiếm', 'Danh mục sản phẩm'],
      'child_elements': ['product_image', 'product_name', 'product_price', 'favorite_button'],
    },
    {
      'id': 'search_bar',
      'name': 'Thanh tìm kiếm',
      'type': 'TextField',
      'description': 'Cho phép nhập từ khóa để tìm kiếm',
      'locations': ['Phía trên màn hình chính', 'Đầu trang tìm kiếm'],
      'child_elements': ['search_input', 'search_icon', 'filter_button'],
    },
  ];
  
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
    // Không cần clear và addAll khi chúng là giá trị mặc định
    // và đã được khởi tạo khi class được tạo
    
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
            if (data['app_screens'] is List) {
              for (var screen in data['app_screens']) {
                _appScreens.add(Map<String, dynamic>.from(screen));
              }
            } else if (data['app_screens'] is Map) {
              // Xử lý trường hợp khi nhận được Map thay vì List
              debugPrint('app_screens là Map thay vì List, dùng dữ liệu mặc định');
            }
          }
          
          // Cập nhật danh sách chức năng
          _appFeatures.clear();
          
          if (data['app_features'] != null) {
            if (data['app_features'] is List) {
              for (var feature in data['app_features']) {
                _appFeatures.add(Map<String, dynamic>.from(feature));
              }
            } else if (data['app_features'] is Map) {
              // Xử lý trường hợp khi nhận được Map thay vì List
              debugPrint('app_features là Map thay vì List, dùng dữ liệu mặc định');
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

  // Tìm đường dẫn đến một tính năng từ bất kỳ màn hình nào
  List<Map<String, dynamic>> findPathsToFeature(String featureId) {
    final feature = _appFeatures.firstWhere(
      (feature) => feature['id'] == featureId,
      orElse: () => {'id': '', 'screen_id': ''},
    );
    
    if (feature['id'].isEmpty || feature['screen_id'] == null) {
      return [];
    }
    
    final targetScreenId = feature['screen_id'];
    List<Map<String, dynamic>> paths = [];
    
    // Duyệt qua tất cả các màn hình để tìm đường đi đến màn hình chứa tính năng
    for (var screen in _appScreens) {
      if (screen['id'] == targetScreenId) continue; // Bỏ qua nếu đã ở màn hình đích
      
      // Tìm đường đi trực tiếp từ màn hình hiện tại đến màn hình đích
      final directPath = navigationPaths.firstWhere(
        (path) => path['from_screen_id'] == screen['id'] && path['to_screen_id'] == targetScreenId,
        orElse: () => {},
      );
      
      if (directPath.isNotEmpty) {
        paths.add({
          'from': screen['name'],
          'to': feature['name'],
          'steps': [
            '1. ${directPath['method']}',
            '2. ${feature['usage']}'
          ],
          'screens_involved': [screen['id'], targetScreenId],
        });
      }
    }
    
    return paths;
  }

  // Phương thức giúp trích xuất các thành phần UI cần thiết cho một tác vụ
  Map<String, dynamic> getUIComponentsForTask(String taskDescription) {
    // Phân tích mô tả tác vụ để tìm ra các từ khóa liên quan
    final keywords = taskDescription.toLowerCase().split(' ');
    
    // Danh sách các tính năng có thể liên quan
    List<Map<String, dynamic>> relevantFeatures = [];
    
    // Tìm các tính năng phù hợp nhất với mô tả
    for (var feature in _appFeatures) {
      int matchScore = 0;
      
      // Tính điểm dựa trên sự xuất hiện của từ khóa
      for (var keyword in keywords) {
        if (feature['name'].toString().toLowerCase().contains(keyword)) matchScore += 3;
        if (feature['description'].toString().toLowerCase().contains(keyword)) matchScore += 2;
        
        // Kiểm tra trong user_tasks nếu có
        if (feature['user_tasks'] != null) {
          for (var task in feature['user_tasks']) {
            if (task.toString().toLowerCase().contains(keyword)) matchScore += 4;
          }
        }
      }
      
      if (matchScore > 0) {
        relevantFeatures.add({
          ...feature,
          'match_score': matchScore,
        });
      }
    }
    
    // Sắp xếp theo điểm phù hợp
    relevantFeatures.sort((a, b) => (b['match_score'] as int).compareTo(a['match_score'] as int));
    
    // Lấy tính năng phù hợp nhất
    if (relevantFeatures.isEmpty) {
      return {
        'found': false,
        'message': 'Không tìm thấy tính năng phù hợp với mô tả tác vụ.'
      };
    }
    
    final bestFeature = relevantFeatures.first;
    final screenId = bestFeature['screen_id'] ?? '';
    
    // Tìm màn hình và đường dẫn
    final screen = _appScreens.firstWhere(
      (s) => s['id'] == screenId,
      orElse: () => {'name': 'Không xác định'},
    );
    
    // Tìm đường dẫn đến tính năng
    final paths = findPathsToFeature(bestFeature['id']);
    
    return {
      'found': true,
      'feature': bestFeature,
      'screen': screen,
      'navigation_paths': paths,
      'usage_guide': generateUsageGuideForFeature(bestFeature['id']),
    };
  }
} 