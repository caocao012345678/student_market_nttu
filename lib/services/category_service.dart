import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:student_market_nttu/models/category.dart';

class CategoryService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Category> _categories = [];
  List<Category> _activeCategories = [];
  bool _isLoading = false;

  List<Category> get categories => _categories;
  List<Category> get activeCategories => _activeCategories;
  bool get isLoading => _isLoading;

  // Khởi tạo và lấy danh sách danh mục
  Future<void> initialize() async {
    await fetchCategories();
  }

  // Lấy tất cả danh mục
  Future<void> fetchCategories() async {
    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await _firestore.collection('categories').get();
      _categories = snapshot.docs
          .map((doc) => Category.fromMap(doc.data(), doc.id))
          .toList();
      
      // If categories are empty, seed default categories
      if (_categories.isEmpty) {
        await seedDefaultCategories();
        // Fetch again after seeding
        final newSnapshot = await _firestore.collection('categories').get();
        _categories = newSnapshot.docs
            .map((doc) => Category.fromMap(doc.data(), doc.id))
            .toList();
      }
      
      // Lọc ra các danh mục đang hoạt động
      _activeCategories = _categories.where((category) => category.isActive).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error fetching categories: $e');
    }
  }

  // Lấy danh mục theo ID
  Future<Category?> getCategoryById(String categoryId) async {
    try {
      final doc = await _firestore.collection('categories').doc(categoryId).get();
      if (!doc.exists) return null;
      return Category.fromMap(doc.data()!, doc.id);
    } catch (e) {
      print('Error getting category by id: $e');
      return null;
    }
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

  // Tạo danh mục mới
  Future<void> createCategory(Category category) async {
    try {
      _isLoading = true;
      notifyListeners();

      final docRef = await _firestore.collection('categories').add(category.toMap());
      
      // Cập nhật danh mục với ID của nó
      await docRef.update({'id': docRef.id});

      await fetchCategories(); // Cập nhật lại danh sách
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error creating category: $e');
      throw e;
    }
  }

  // Cập nhật danh mục
  Future<void> updateCategory(Category category) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('categories')
          .doc(category.id)
          .update(category.toMap());

      await fetchCategories(); // Cập nhật lại danh sách
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error updating category: $e');
      throw e;
    }
  }

  // Vô hiệu hóa danh mục (thay vì xóa)
  Future<void> disableCategory(String categoryId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('categories')
          .doc(categoryId)
          .update({
            'isActive': false,
            'updatedAt': DateTime.now()
          });

      await fetchCategories(); // Cập nhật lại danh sách
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error disabling category: $e');
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
        },
        {
          'name': 'Đồ điện tử & Máy tính',
          'iconName': 'electronics',
          'color': Colors.orange.value,
          'parentId': '',
        },
        {
          'name': 'Thời trang & Phụ kiện',
          'iconName': 'clothing',
          'color': Colors.pink.value,
          'parentId': '',
        },
        {
          'name': 'Đồ dùng học tập',
          'iconName': 'stationery',
          'color': Colors.purple.value,
          'parentId': '',
        },
        {
          'name': 'Thiết bị di động',
          'iconName': 'phone',
          'color': Colors.red.value,
          'parentId': '',
        },
        {
          'name': 'Thể thao & Giải trí',
          'iconName': 'sports',
          'color': Colors.green.value,
          'parentId': '',
        },
        {
          'name': 'Đồ dùng cá nhân',
          'iconName': 'household',
          'color': Colors.indigo.value,
          'parentId': '',
        },
        {
          'name': 'Khác',
          'iconName': 'other',
          'color': Colors.grey.value,
          'parentId': '',
        },
        // 10 danh mục mới
        {
          'name': 'Đồ ăn & Thực phẩm',
          'iconName': 'food',
          'color': Colors.amber.value,
          'parentId': '',
        },
        {
          'name': 'Đồ chơi & Games',
          'iconName': 'game',
          'color': Colors.deepPurple.value,
          'parentId': '',
        },
        {
          'name': 'Nhạc cụ',
          'iconName': 'music',
          'color': Colors.brown.value,
          'parentId': '',
        },
        {
          'name': 'Đồ thủ công & Mỹ nghệ',
          'iconName': 'art',
          'color': Colors.teal.value,
          'parentId': '',
        },
        {
          'name': 'Làm đẹp & Chăm sóc cá nhân',
          'iconName': 'beauty',
          'color': Colors.pinkAccent.value,
          'parentId': '',
        },
        {
          'name': 'Trang sức & Phụ kiện',
          'iconName': 'jewelry',
          'color': Colors.amberAccent.value,
          'parentId': '',
        },
        {
          'name': 'Nội thất & Trang trí',
          'iconName': 'furniture',
          'color': Colors.lime.value,
          'parentId': '',
        },
        {
          'name': 'Thiết bị y tế & Sức khỏe',
          'iconName': 'accessory',
          'color': Colors.cyan.value,
          'parentId': '',
        },
        {
          'name': 'Vé & Voucher',
          'iconName': 'ticket',
          'color': Colors.deepOrange.value,
          'parentId': '',
        },
        {
          'name': 'Thú cưng & Phụ kiện',
          'iconName': 'pet',
          'color': Colors.lightGreen.value,
          'parentId': '',
        },
      ];

      // Thêm các danh mục cha
      for (var categoryData in parentCategories) {
        final docRef = await _firestore.collection('categories').add({
          ...categoryData,
          'isActive': true,
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        });

        await docRef.update({'id': docRef.id});
      }

      // Refresh lại danh sách sau khi thêm
      await fetchCategories();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error seeding default categories: $e');
    }
  }

  // Tìm kiếm danh mục theo từ khóa
  List<Category> searchCategories(String keyword) {
    if (keyword.isEmpty) return _activeCategories;
    
    final searchTerm = keyword.toLowerCase();
    return _activeCategories.where((category) => 
      category.name.toLowerCase().contains(searchTerm)).toList();
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
} 