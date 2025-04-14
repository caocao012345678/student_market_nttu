import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_market_nttu/models/product.dart';
import 'package:student_market_nttu/widgets/product_card_standard.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:student_market_nttu/services/product_service.dart';
import 'package:student_market_nttu/screens/search_screen.dart';
import 'package:student_market_nttu/screens/cart_screen.dart';
import 'package:student_market_nttu/widgets/cart_badge.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedCategory = 'Tất cả';
  String _sortBy = 'Mới nhất';
  RangeValues _priceRange = const RangeValues(0, 10000000);
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = true;
  final PageController _pageController = PageController();
  int _currentBannerIndex = 0;
  bool _isSearching = false;
  List<Product> _searchResults = [];
  bool _isLoadingSearch = false;

  final List<String> _bannerImages = [
    'https://firebasestorage.googleapis.com/v0/b/student-market-nttu.appspot.com/o/banners%2Fbanner1.jpg?alt=media',
    'https://firebasestorage.googleapis.com/v0/b/student-market-nttu.appspot.com/o/banners%2Fbanner2.jpg?alt=media',
    'https://firebasestorage.googleapis.com/v0/b/student-market-nttu.appspot.com/o/banners%2Fbanner3.jpg?alt=media',
  ];

  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.book, 'name': 'Sách', 'color': Colors.blue[700]},
    {'icon': Icons.computer, 'name': 'Đồ điện tử', 'color': Colors.orange[700]},
    {'icon': Icons.checkroom, 'name': 'Quần áo', 'color': Colors.pink[700]},
    {'icon': Icons.sports_basketball, 'name': 'Thể thao', 'color': Colors.green[700]},
    {'icon': Icons.kitchen, 'name': 'Đồ dùng', 'color': Colors.purple[700]},
    {'icon': Icons.phone_android, 'name': 'Điện thoại', 'color': Colors.red[700]},
    {'icon': Icons.camera_alt, 'name': 'Máy ảnh', 'color': Colors.teal[700]},
    {'icon': Icons.recycling, 'name': 'Đồ đã qua sử dụng', 'color': Colors.amber[700]},
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }
    
    _performSearch(query);
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    
    setState(() {
      _isSearching = true;
      _isLoadingSearch = true;
    });

    try {
      final snapshot = await _firestore
          .collection('products')
          .where('isSold', isEqualTo: false)
          .get();
      
      final allProducts = snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
      
      // Filter products based on query (title, description, tags)
      final filteredProducts = allProducts.where((product) {
        final titleMatch = product.title.toLowerCase().contains(query.toLowerCase());
        final descriptionMatch = product.description.toLowerCase().contains(query.toLowerCase());
        final tagMatch = product.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()));
        final categoryMatch = product.category.toLowerCase().contains(query.toLowerCase());
        
        return titleMatch || descriptionMatch || tagMatch || categoryMatch;
      }).toList();
      
      setState(() {
        _searchResults = filteredProducts;
        _isLoadingSearch = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSearch = false;
      });
      print('Error searching products: $e');
    }
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchScreen(),
                  ),
                );
              },
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.search, color: Colors.grey),
                    ),
                    Text(
                      'Tìm kiếm sản phẩm',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, size: 22),
            color: Colors.white,
            onPressed: () {
              // Navigate to cart
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_outlined, size: 22),
            color: Colors.white,
            onPressed: () {
              // Navigate to messages
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBannerSlider() {
    return Container(
      height: 150,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
            itemCount: _bannerImages.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: _bannerImages[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.error),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _bannerImages.asMap().entries.map((entry) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentBannerIndex == entry.key
                        ? Colors.blue[900]
                        : Colors.grey.withOpacity(0.5),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Danh mục',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category['name'];
                
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category['name'];
                      _searchController.clear();
                      _isSearching = false;
                    });
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? category['color']!.withOpacity(0.2)
                              : category['color']!.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          category['icon'],
                          color: category['color'],
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category['name'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lọc sản phẩm',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sortBy,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem<String>(
                        value: 'Mới nhất',
                        child: Text('Mới nhất'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'Giá thấp đến cao',
                        child: Text('Giá thấp đến cao'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'Giá cao đến thấp',
                        child: Text('Giá cao đến thấp'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'Bán chạy',
                        child: Text('Bán chạy'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'Đánh giá cao',
                        child: Text('Đánh giá cao'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _sortBy = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Khoảng giá',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            RangeSlider(
              values: _priceRange,
              min: 0,
              max: 10000000,
              divisions: 100,
              labels: RangeLabels(
                '${_priceRange.start.round()}đ',
                '${_priceRange.end.round()}đ',
              ),
              onChanged: (RangeValues values) {
                setState(() {
                  _priceRange = values;
                });
              },
              activeColor: Colors.blue[900],
              inactiveColor: Colors.blue[900]?.withOpacity(0.2),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_priceRange.start.round()}đ',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  '${_priceRange.end.round()}đ',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductsView({bool isSearchResults = false}) {
    if (isSearchResults) {
      if (_isLoadingSearch) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_searchResults.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text('Không tìm thấy sản phẩm phù hợp'),
          ),
        );
      }

      return _renderProductList(_searchResults);
    }

    return StreamBuilder<List<Product>>(
      stream: Provider.of<ProductService>(context).searchProductsAdvanced(
        category: _selectedCategory,
        minPrice: _priceRange.start,
        maxPrice: _priceRange.end,
        sortBy: _sortBy,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Đã xảy ra lỗi'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('Không có sản phẩm nào'),
            ),
          );
        }

        return _renderProductList(products);
      },
    );
  }

  Widget _renderProductList(List<Product> products) {
    if (_isGridView) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.58,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return ProductCardStandard(product: products[index]);
        },
      );
    } else {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(8),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return ProductCardStandard(
            product: products[index],
            isListView: true,
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        title: const Text('Tất cả sản phẩm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
          ),
          const CartBadge(),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.blue[900],
        onRefresh: () async {
          setState(() {
            _searchController.clear();
            _isSearching = false;
          });
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Danh mục
                  _buildCategories(),
                  const SizedBox(height: 8),
                  
                  // Lọc giá
                  _buildFilters(),
                  const SizedBox(height: 8),
                  
                  // Tất cả sản phẩm
                  _buildSectionHeader('Tất cả sản phẩm'),
                  _buildProductsView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedProducts() {
    return FutureBuilder<List<Product>>(
      future: Provider.of<ProductService>(context, listen: false).getRecommendedProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Không có sản phẩm đề xuất'));
        }
        
        final products = snapshot.data!;
        
        return SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            itemBuilder: (context, index) {
              return SizedBox(
                width: 160,
                child: ProductCardStandard(
                  product: products[index],
                  isCompact: true,
                ),
              );
            },
          ),
        );
      },
    );
  }
} 