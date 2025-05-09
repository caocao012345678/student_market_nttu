import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_market_nttu/models/product.dart';
import 'package:student_market_nttu/widgets/product_card_standard.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:student_market_nttu/services/product_service.dart';
import 'package:student_market_nttu/services/category_service.dart';
import 'package:student_market_nttu/services/location_service.dart';
import 'package:student_market_nttu/models/category.dart';
import 'package:student_market_nttu/models/location.dart';
import 'package:student_market_nttu/screens/search_screen.dart';
import 'package:student_market_nttu/screens/cart_screen.dart';
import 'package:student_market_nttu/widgets/cart_badge.dart';
import 'package:student_market_nttu/widgets/common_app_bar.dart';
import 'package:student_market_nttu/widgets/app_drawer.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedCategory = 'Tất cả';
  String _selectedCategoryId = 'all';
  String _sortBy = 'newest';
  bool _isGridView = true;
  final PageController _pageController = PageController();
  int _currentBannerIndex = 0;
  bool _isLoadingCategories = true;
  bool _isLoadingProducts = true;
  List<Category> _availableCategories = [];
  bool _disposed = false;
  
  // Biến cho lọc địa điểm
  LocationModel? _selectedLocation;
  List<LocationModel> _availableLocations = [];
  bool _isLoadingLocations = true;

  final List<String> _bannerImages = [
    'https://firebasestorage.googleapis.com/v0/b/student-market-nttu.appspot.com/o/banners%2Fbanner1.jpg?alt=media',
    'https://firebasestorage.googleapis.com/v0/b/student-market-nttu.appspot.com/o/banners%2Fbanner2.jpg?alt=media',
    'https://firebasestorage.googleapis.com/v0/b/student-market-nttu.appspot.com/o/banners%2Fbanner3.jpg?alt=media',
  ];

  final List<Map<String, dynamic>> _sortOptions = [
    {'id': 'newest', 'name': 'Mới nhất'},
    {'id': 'price_asc', 'name': 'Giá tăng dần'},
    {'id': 'price_desc', 'name': 'Giá giảm dần'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _loadLocations();
  }

  Future<void> _fetchInitialData() async {
    if (_disposed) return;
    
    setState(() {
      _isLoadingCategories = true;
    });
    
    try {
      await _initializeCategories();
    } catch (e) {
      print('Lỗi khi tải dữ liệu ban đầu: $e');
    } finally {
      if (!_disposed) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  Future<void> _initializeCategories() async {
    if (_disposed) return;
    
    final categoryService = Provider.of<CategoryService>(context, listen: false);
    
    // Đảm bảo danh mục đã được khởi tạo
    if (!categoryService.isInitialized || categoryService.categories.isEmpty) {
      await categoryService.seedDefaultCategories();
      await categoryService.fetchCategories();
    }
    
    // Lấy tất cả danh mục active
    await _getAllActiveCategories();
  }

  Future<void> _getAllActiveCategories() async {
    if (_disposed) return;
    
    try {
      // Lấy thông tin các danh mục từ dịch vụ
      final categoryService = Provider.of<CategoryService>(context, listen: false);
      
      // Chờ nếu categories đang tải
      if (categoryService.isLoading) {
        await Future.delayed(const Duration(milliseconds: 500));
        return _getAllActiveCategories();
      }
      
      // Sử dụng tất cả các danh mục active, không cần lọc theo sản phẩm
      _availableCategories = List.from(categoryService.activeCategories);
      
      // Thêm danh mục "Tất cả" vào đầu danh sách
      _availableCategories.insert(
        0,
        Category(
          id: 'all',
          name: 'Tất cả',
          iconName: 'category',
          icon: Icons.category,
          color: Colors.blue[900]!,
          createdAt: DateTime.now(),
        ),
      );
      
      if (!_disposed) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      print('Lỗi khi lấy danh mục: $e');
      if (!_disposed) {
        setState(() {
          _isLoadingCategories = false;
          // Tạo danh mục "Tất cả" mặc định nếu có lỗi
          _availableCategories = [
            Category(
              id: 'all',
              name: 'Tất cả',
              iconName: 'category',
              icon: Icons.category,
              color: Colors.blue[900]!,
              createdAt: DateTime.now(),
            ),
          ];
        });
      }
    }
  }

  void _updateSelectedCategory(String id, String name) {
    if (!_disposed) {
      setState(() {
        _selectedCategoryId = id;
        _selectedCategory = name;
        _isLoadingProducts = true;
      });
      
      print('Đã chọn danh mục: $_selectedCategory với ID: $_selectedCategoryId');
    }
  }

  void _showSortOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sắp xếp sản phẩm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _sortOptions.map((option) {
            return RadioListTile<String>(
              title: Text(option['name']),
              value: option['id'],
              groupValue: _sortBy,
              onChanged: (value) {
                if (!_disposed) {
                  setState(() {
                    _sortBy = value!;
                  });
                }
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  // Phương thức tải danh sách địa điểm
  Future<void> _loadLocations() async {
    if (_disposed) return;
    
    setState(() {
      _isLoadingLocations = true;
    });
    
    try {
      final locationService = Provider.of<LocationService>(context, listen: false);
      
      // Lấy danh sách địa điểm từ stream và chuyển thành list
      final locationsStream = locationService.getAllLocations();
      final locations = await locationsStream.first;
      
      if (!_disposed) {
        setState(() {
          _availableLocations = locations;
          _isLoadingLocations = false;
        });
      }
    } catch (e) {
      print('Lỗi khi tải danh sách địa điểm: $e');
      if (!_disposed) {
        setState(() {
          _isLoadingLocations = false;
        });
      }
    }
  }
  
  // Phương thức hiển thị dialog chọn địa điểm
  void _showLocationFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lọc theo cơ sở'),
        content: _isLoadingLocations 
          ? const Center(child: CircularProgressIndicator())
          : SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tùy chọn bỏ lọc địa điểm
                  ListTile(
                    title: const Text('Tất cả cơ sở'),
                    trailing: _selectedLocation == null ? const Icon(Icons.check_circle, color: Colors.green) : null,
                    onTap: () {
                      setState(() {
                        _selectedLocation = null;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(),
                  
                  // Danh sách địa điểm có thể chọn
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _availableLocations.length,
                      itemBuilder: (context, index) {
                        final location = _availableLocations[index];
                        final isSelected = _selectedLocation?.id == location.id;
                        
                        return ListTile(
                          title: Text(location.name),
                          subtitle: Text('${location.district} - ${location.address}'),
                          trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                          onTap: () {
                            setState(() {
                              _selectedLocation = location;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productService = Provider.of<ProductService>(context);
    
    return Scaffold(
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Categories in Grid format
          _buildCategoriesSection(),
          
          // Products
          Expanded(
            child: _buildProductsSection(productService),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    if (_isLoadingCategories) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_availableCategories.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text('Không có danh mục nào'),
        ),
      );
    }

    return Container(
      height: 100,
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _availableCategories.length,
        itemBuilder: (context, index) {
          final category = _availableCategories[index];
          final isSelected = _selectedCategoryId == category.id;
          
          return Container(
            margin: const EdgeInsets.only(right: 12),
            width: 80,
            child: InkWell(
              onTap: () => _updateSelectedCategory(category.id, category.name),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? category.color.withOpacity(0.2) : category.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: isSelected 
                          ? Border.all(color: category.color, width: 1.5)
                          : null,
                    ),
                    child: Icon(
                      category.icon,
                      color: category.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? category.color : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsSection(ProductService productService) {
    return StreamBuilder<List<Product>>(
      stream: productService.getProductsByCategory(_selectedCategoryId, sortBy: _sortBy),
      builder: (context, snapshot) {
        // Hiển thị loading khi đang chờ dữ liệu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        // Kiểm tra lỗi
        if (snapshot.hasError) {
          return Center(
            child: Text('Đã xảy ra lỗi: ${snapshot.error}'),
          );
        }
        
        // Kiểm tra danh sách trống
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_basket_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text('Không có sản phẩm nào trong danh mục ${_selectedCategory}'),
              ],
            ),
          );
        }
        
        // Lọc theo địa điểm nếu đã chọn
        final allProducts = snapshot.data!;
        List<Product> filteredProducts = allProducts;
        
        if (_selectedLocation != null) {
          filteredProducts = allProducts.where((product) {
            // Nếu sản phẩm có vị trí, kiểm tra có trùng với khu vực đã chọn không
            if (product.location != null && product.location!.containsKey('address')) {
              String address = product.location!['address'].toString().toLowerCase();
              // Kiểm tra xem địa chỉ sản phẩm có chứa tên cơ sở hoặc địa chỉ cơ sở không
              return address.contains(_selectedLocation!.name.toLowerCase()) || 
                     address.contains(_selectedLocation!.address.toLowerCase()) ||
                     address.contains(_selectedLocation!.district.toLowerCase());
            }
            return false;
          }).toList();
        }
        
        final products = filteredProducts;
        
        // Controls bar và danh sách sản phẩm
        return Column(
          children: [
            // Controls bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tìm thấy ${products.length} sản phẩm',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      // Nút lọc địa điểm
                      IconButton(
                        icon: Icon(
                          Icons.location_on,
                          color: _selectedLocation != null ? Colors.blue : null,
                        ),
                        tooltip: 'Lọc theo cơ sở',
                        onPressed: _showLocationFilterDialog,
                      ),
                      // Nút sắp xếp
                      IconButton(
                        icon: const Icon(Icons.sort),
                        tooltip: 'Sắp xếp',
                        onPressed: _showSortOptionsDialog,
                      ),
                      const SizedBox(width: 8),
                      // Nút chuyển đổi chế độ xem
                      IconButton(
                        icon: Icon(
                          _isGridView ? Icons.list : Icons.grid_view,
                        ),
                        onPressed: () {
                          if (!_disposed) {
                            setState(() {
                              _isGridView = !_isGridView;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Hiển thị thông tin địa điểm đã chọn
            if (_selectedLocation != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.blue.shade50,
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lọc theo cơ sở: ${_selectedLocation!.name} (${_selectedLocation!.district})',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedLocation = null;
                        });
                      },
                      child: const Icon(Icons.close, size: 16),
                    ),
                  ],
                ),
              ),
            
            // Product grid/list
            Expanded(
              child: _isGridView
                  ? GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.58,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        return ProductCardStandard(product: products[index]);
                      },
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        return ProductCardStandard(
                          product: products[index],
                          isListView: true,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
} 