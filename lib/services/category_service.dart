import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:student_market_nttu/models/category.dart';

class CategoryService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Category> _categories = [];
  List<Category> _activeCategories = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  List<Category> get categories => _categories;
  List<Category> get activeCategories => _activeCategories;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  // Constructor tự động khởi tạo danh mục khi khởi tạo service
  CategoryService() {
    initialize();
  }

  // Khởi tạo và lấy danh sách danh mục
  Future<void> initialize() async {
    if (_isInitialized) return;
    await fetchCategories();
    _isInitialized = true;
  }

  // Lấy tất cả danh mục
  Future<void> fetchCategories() async {
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      print("CategoryService: Đang tải danh mục...");
      
      // Tạo cơ chế timeout để tránh treo quá lâu
      final result = await _firestore
          .collection('categories')
          .orderBy('createdAt', descending: false)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print("CategoryService: Timeout khi tải danh mục");
              throw Exception("Timeout khi tải danh mục");
            },
          );

      print("CategoryService: Đã tải ${result.docs.length} danh mục.");
      
      // Xóa danh sách hiện tại để tránh trùng lặp
      _categories.clear();
      
      // Chuyển đổi dữ liệu
      _categories = result.docs
          .map((doc) => Category.fromMap(doc.data(), doc.id))
          .toList();

      // Nếu không có danh mục, tạo danh mục mặc định
      if (_categories.isEmpty) {
        print("CategoryService: Danh sách trống, tạo danh mục mặc định");
        await seedDefaultCategories();
        
        // Tải lại sau khi tạo
        final newResult = await _firestore.collection('categories').get();
        _categories = newResult.docs
            .map((doc) => Category.fromMap(doc.data(), doc.id))
            .toList();
      }

      // Filter chỉ lấy những danh mục active
      _activeCategories = _categories.where((cat) => cat.isActive).toList();
      _isLoading = false;
      notifyListeners();
      print("CategoryService: Tải danh mục thành công");
    } catch (e) {
      print("CategoryService: Lỗi khi tải danh mục: $e");
      _isLoading = false;
      notifyListeners();
      // Đặt một danh mục mặc định để không bị trống
      if (_categories.isEmpty) {
        _categories = [
          Category(
            id: 'default',
            name: 'Danh mục mặc định',
            iconName: 'category',
            icon: Icons.category,
            color: Colors.blue,
            createdAt: DateTime.now(),
            description: 'Danh mục mặc định khi không thể tải danh mục',
          )
        ];
        _activeCategories = List.from(_categories);
      }
    }
  }

  // Lấy danh mục theo ID
  Future<Category?> getCategoryById(String id) async {
    // Kiểm tra cache trước
    final cachedCategory = _categories.firstWhere(
      (cat) => cat.id == id,
      orElse: () => Category(
        id: '',
        name: '',
        iconName: '',
        icon: Icons.category,
        color: Colors.grey,
        createdAt: DateTime.now(),
      ),
    );
    
    if (cachedCategory.id.isNotEmpty) {
      return cachedCategory;
    }
    
    // Nếu không có trong cache, truy vấn Firestore
    try {
      final doc = await _firestore.collection('categories').doc(id).get();
      if (doc.exists) {
        return Category.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      print('Lỗi khi lấy danh mục: $e');
    }
    
    return null;
  }

  // Lấy danh mục con theo danh mục cha
  List<Category> getSubcategories(String parentId) {
    return _categories.where((category) => 
      category.parentId == parentId && category.isActive).toList();
  }

  // Lấy danh mục cha
  List<Category> getParentCategories() {
    return _categories.where((category) => 
      category.parentId.isEmpty && category.isActive).toList();
  }  

  // Tìm kiếm danh mục theo từ khóa
  List<Category> searchCategories(String query) {
    if (query.isEmpty) {
      return _activeCategories;
    }
    
    final queryLower = query.toLowerCase();
    return _activeCategories.where((cat) => 
      cat.name.toLowerCase().contains(queryLower) ||
      (cat.description?.toLowerCase().contains(queryLower) ?? false)
    ).toList();
  }

  // Lấy đường dẫn đầy đủ của danh mục (ví dụ: Electronics > Smartphones)
  String getCategoryPath(String categoryId) {
    final category = _categories.firstWhere(
      (c) => c.id == categoryId, 
      orElse: () => Category(
        id: '', 
        name: 'Unknown', 
        iconName: 'other',
        icon: Icons.help_outline,
        color: Colors.grey,
        createdAt: DateTime.now()
      )
    );
    
    if (category.parentId.isEmpty) {
      return category.name;
    }
    
    final parentCategory = _categories.firstWhere(
      (c) => c.id == category.parentId,
      orElse: () => Category(
        id: '', 
        name: 'Unknown', 
        iconName: 'other',
        icon: Icons.help_outline,
        color: Colors.grey,
        createdAt: DateTime.now()
      )
    );
    
    return '${parentCategory.name} > ${category.name}';
  }

  // Thêm danh mục mới
  Future<String> addCategory(Map<String, dynamic> categoryData) async {
    try {
      final docRef = await _firestore.collection('categories').add({
        ...categoryData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Cập nhật danh sách local
      await fetchCategories();
      
      return docRef.id;
    } catch (e) {
      throw e;
    }
  }

  // Cập nhật danh mục
  Future<void> updateCategory(String id, Map<String, dynamic> categoryData) async {
    try {
      await _firestore.collection('categories').doc(id).update({
        ...categoryData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Cập nhật danh sách local
      await fetchCategories();
    } catch (e) {
      throw e;
    }
  }

  // Kích hoạt/Vô hiệu hóa danh mục
  Future<void> toggleCategoryActive(String id, bool isActive) async {
    try {
      await _firestore.collection('categories').doc(id).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Cập nhật danh sách local
      await fetchCategories();
    } catch (e) {
      throw e;
    }
  }

  // Xóa danh mục
  Future<void> deleteCategory(String id) async {
    try {
      await _firestore.collection('categories').doc(id).delete();
      
      // Cập nhật danh sách local
      await fetchCategories();
    } catch (e) {
      throw e;
    }
  }
  
  // Tạo danh sách danh mục mặc định nếu chưa có
  Future<void> seedDefaultCategories() async {
    try {
      final snapshot = await _firestore.collection('categories').limit(1).get();
      
      // Nếu đã có danh mục thì không cần tạo mặc định
      if (snapshot.docs.isNotEmpty) return;

      _isLoading = true;
      notifyListeners();

      // Danh sách danh mục cha
      final parentCategories = [
        {
          'name': 'Sách & Tài liệu học tập',
          'iconName': 'book',
          'color': Colors.blue.value,
          'parentId': '',
          'description': 'Sách giáo trình và tài liệu học tập',
        },
        {
          'name': 'Đồ điện tử & Máy tính',
          'iconName': 'electronics',
          'color': Colors.orange.value,
          'parentId': '',
          'description': 'Các thiết bị điện tử, máy tính',
        },
        {
          'name': 'Thời trang & Phụ kiện',
          'iconName': 'clothing',
          'color': Colors.pink.value,
          'parentId': '',
          'description': 'Quần áo, giày dép và phụ kiện thời trang',
        },
        {
          'name': 'Đồ dùng học tập',
          'iconName': 'stationery',
          'color': Colors.purple.value,
          'parentId': '',
          'description': 'Văn phòng phẩm và đồ dùng học tập',
        },
        {
          'name': 'Thiết bị di động',
          'iconName': 'phone',
          'color': Colors.red.value,
          'parentId': '',
          'description': 'Điện thoại, máy tính bảng và phụ kiện',
        },
        {
          'name': 'Thể thao & Giải trí',
          'iconName': 'sports',
          'color': Colors.deepOrange.value,
          'parentId': '',
          'description': 'Dụng cụ thể thao và giải trí',
        },
        {
          'name': 'Đồ dùng cá nhân',
          'iconName': 'household',
          'color': Colors.indigo.value,
          'parentId': '',
          'description': 'Đồ dùng sinh hoạt hàng ngày',
        },
        {
          'name': 'Đồ tặng',
          'iconName': 'gift',
          'color': Colors.green.value,
          'parentId': '',
          'description': 'Các sản phẩm được tặng miễn phí',
        },
        {
          'name': 'Khác',
          'iconName': 'other',
          'color': Colors.grey.value,
          'parentId': '',
          'description': 'Các danh mục khác',
        },
        // 10 danh mục mới
        {
          'name': 'Đồ ăn & Thực phẩm',
          'iconName': 'food',
          'color': Colors.amber.value,
          'parentId': '',
          'description': 'Thực phẩm, đồ ăn vặt',
        },
        {
          'name': 'Đồ chơi & Games',
          'iconName': 'game',
          'color': Colors.deepPurple.value,
          'parentId': '',
          'description': 'Đồ chơi, trò chơi, games',
        },
        {
          'name': 'Nhạc cụ',
          'iconName': 'music',
          'color': Colors.brown.value,
          'parentId': '',
          'description': 'Các loại nhạc cụ',
        },
        {
          'name': 'Đồ thủ công & Mỹ nghệ',
          'iconName': 'art',
          'color': Colors.teal.value,
          'parentId': '',
          'description': 'Sản phẩm thủ công, handmade',
        },
        {
          'name': 'Làm đẹp & Chăm sóc cá nhân',
          'iconName': 'beauty',
          'color': Colors.pinkAccent.value,
          'parentId': '',
          'description': 'Mỹ phẩm, đồ làm đẹp',
        },
        {
          'name': 'Trang sức & Phụ kiện',
          'iconName': 'jewelry',
          'color': Colors.amberAccent.value,
          'parentId': '',
          'description': 'Trang sức và phụ kiện thời trang',
        },
        {
          'name': 'Nội thất & Trang trí',
          'iconName': 'furniture',
          'color': Colors.lime.value,
          'parentId': '',
          'description': 'Đồ nội thất, trang trí nhà cửa',
        },
        {
          'name': 'Thiết bị y tế & Sức khỏe',
          'iconName': 'accessory',
          'color': Colors.cyan.value,
          'parentId': '',
          'description': 'Thiết bị chăm sóc sức khỏe',
        },
        {
          'name': 'Vé & Voucher',
          'iconName': 'ticket',
          'color': Colors.deepOrange.value,
          'parentId': '',
          'description': 'Vé sự kiện, voucher, mã giảm giá',
        },
        {
          'name': 'Thú cưng & Phụ kiện',
          'iconName': 'pet',
          'color': Colors.lightGreen.value,
          'parentId': '',
          'description': 'Đồ dùng cho thú cưng',
        },
      ];

      // Thêm các danh mục cha
      for (var categoryData in parentCategories) {
        final docRef = await _firestore.collection('categories').add({
          ...categoryData,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Refresh lại danh sách sau khi thêm
      await fetchCategories();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error seeding default categories: $e');
    }
  }

  // Lấy tên danh mục từ ID
  String getCategoryName(String categoryId) {
    if (categoryId == 'all') return 'Tất cả';
    
    final category = _categories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => Category(
        id: categoryId, 
        name: categoryId, // Sử dụng ID làm tên nếu không tìm thấy
        iconName: 'category',
        icon: Icons.category,
        color: Colors.grey,
        createdAt: DateTime.now()
      )
    );
    
    return category.name;
  }
} 