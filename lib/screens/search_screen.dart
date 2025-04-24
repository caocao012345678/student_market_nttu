import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:student_market_nttu/models/product.dart';
import 'package:student_market_nttu/services/product_service.dart';
import 'package:student_market_nttu/widgets/product_card_standard.dart';
import 'package:student_market_nttu/screens/product_detail_screen.dart';
import 'package:student_market_nttu/services/auth_service.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  final String? initialCategory;
  
  const SearchScreen({
    Key? key,
    this.initialQuery,
    this.initialCategory,
  }) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late TextEditingController _searchController;
  bool _isSearching = false;
  bool _isFiltersVisible = false;
  String _selectedCategory = 'Tất cả';
  String _sortBy = 'Mới nhất';
  RangeValues _priceRange = const RangeValues(0, 10000000);
  bool _isGridView = true;
  List<String> _recentSearches = [];
  bool _isLoading = false;
  String _searchQuery = '';
  List<String> _popularSearchTerms = [
    'Sách giáo khoa', 'Laptop cũ', 'Điện thoại', 'Quần áo nam',
    'Quần áo nữ', 'Đồ dùng học tập', 'Tặng free', 'Đồ dùng ký túc xá'
  ];

  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.all_inbox, 'name': 'Tất cả'},
    {'icon': Icons.book, 'name': 'Sách'},
    {'icon': Icons.computer, 'name': 'Đồ điện tử'},
    {'icon': Icons.checkroom, 'name': 'Quần áo'},
    {'icon': Icons.sports_basketball, 'name': 'Thể thao'},
    {'icon': Icons.kitchen, 'name': 'Đồ dùng'},
    {'icon': Icons.phone_android, 'name': 'Điện thoại'},
    {'icon': Icons.camera_alt, 'name': 'Máy ảnh'},
    {'icon': Icons.recycling, 'name': 'Đồ đã qua sử dụng'},
    {'icon': Icons.more_horiz, 'name': 'Khác'},
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
    
    if (_searchController.text.isNotEmpty) {
      _isSearching = true;
    }
    
    // Load recent searches
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList('recent_searches') ?? [];
      setState(() {
        _recentSearches = searches;
      });
    } catch (e) {
      print('Error loading recent searches: $e');
    }
  }

  Future<void> _saveSearchQuery(String query) async {
    if (query.isEmpty) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList('recent_searches') ?? [];
      
      // Remove if already exists (to move it to the top)
      searches.remove(query);
      
      // Add to the beginning
      searches.insert(0, query);
      
      // Limit to 10 recent searches
      final limitedSearches = searches.take(10).toList();
      
      // Save back to SharedPreferences
      await prefs.setStringList('recent_searches', limitedSearches);
      
      // Update state
      setState(() {
        _recentSearches = limitedSearches;
      });
    } catch (e) {
      print('Error saving search query: $e');
    }
  }

  Future<void> _clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('recent_searches');
      setState(() {
        _recentSearches = [];
      });
    } catch (e) {
      print('Error clearing recent searches: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _searchQuery = query;
      _isLoading = true;
    });
    
    // Save search history for logged in users
    _saveSearchToFirebase(query);
    
    // Lưu vào SharedPreferences
    _saveSearchQuery(query);
    
    // ... existing code (search logic) ...
  }

  void _saveSearchToFirebase(String query) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final productService = Provider.of<ProductService>(context, listen: false);
    
    // Only save search history if user is logged in
    if (authService.currentUser != null) {
      productService.addToSearchHistory(
        authService.currentUser!.uid,
        query
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm sản phẩm...',
            hintStyle: const TextStyle(color: Colors.white70),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _isSearching = false;
                      });
                    },
                  )
                : const Icon(Icons.search, color: Colors.white),
          ),
          onSubmitted: (value) => _performSearch(value),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFiltersVisible ? Icons.filter_list_off : Icons.filter_list,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isFiltersVisible = !_isFiltersVisible;
              });
            },
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view, color: Colors.white),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
        bottom: _isFiltersVisible
            ? PreferredSize(
                preferredSize: const Size.fromHeight(180),
                child: _buildFilters(),
              )
            : null,
      ),
      body: _isSearching
          ? _buildSearchResults()
          : _buildSearchSuggestions(),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Danh mục',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_categories[index]['name']),
                    selected: _selectedCategory == _categories[index]['name'],
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = _categories[index]['name'];
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Khoảng giá',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${_priceRange.start.round()}đ - ${_priceRange.end.round()}đ',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 10000000,
            divisions: 50,
            labels: RangeLabels(
              '${_priceRange.start.round()}đ',
              '${_priceRange.end.round()}đ',
            ),
            onChanged: (RangeValues values) {
              setState(() {
                _priceRange = values;
              });
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sắp xếp theo',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: _sortBy,
                items: const [
                  DropdownMenuItem(
                    value: 'Mới nhất',
                    child: Text('Mới nhất'),
                  ),
                  DropdownMenuItem(
                    value: 'Giá thấp đến cao',
                    child: Text('Giá thấp đến cao'),
                  ),
                  DropdownMenuItem(
                    value: 'Giá cao đến thấp',
                    child: Text('Giá cao đến thấp'),
                  ),
                  DropdownMenuItem(
                    value: 'Bán chạy',
                    child: Text('Bán chạy'),
                  ),
                  DropdownMenuItem(
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
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900],
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                // Apply filters and perform search
                _performSearch(_searchController.text.trim());
              },
              child: const Text('Áp dụng'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return StreamBuilder<List<Product>>(
      stream: Provider.of<ProductService>(context).searchProductsAdvanced(
        query: _searchController.text.trim(),
        category: _selectedCategory != 'Tất cả' ? _selectedCategory : null,
        minPrice: _priceRange.start,
        maxPrice: _priceRange.end,
        sortBy: _sortBy,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Đã xảy ra lỗi: ${snapshot.error}'),
          );
        }

        final products = snapshot.data ?? [];

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 72,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Không tìm thấy sản phẩm phù hợp',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hãy thử tìm kiếm với từ khóa khác',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        if (_isGridView) {
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.58,
              crossAxisSpacing: 8,
              mainAxisSpacing: 12,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return ProductCardStandard(product: products[index]);
            },
          );
        } else {
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return ProductCardStandard(
                product: products[index],
                isListView: true,
              );
            },
          );
        }
      },
    );
  }

  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent searches section
          if (_recentSearches.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tìm kiếm gần đây',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: _clearRecentSearches,
                        child: const Text('Xóa'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _recentSearches.map((term) {
                      return ActionChip(
                        avatar: const Icon(Icons.history, size: 16),
                        label: Text(term),
                        onPressed: () {
                          setState(() {
                            _searchController.text = term;
                            _performSearch(term);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Popular searches
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tìm kiếm phổ biến',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _popularSearchTerms.map((term) {
                    return ActionChip(
                      label: Text(term),
                      onPressed: () {
                        setState(() {
                          _searchController.text = term;
                          _performSearch(term);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Categories section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Danh mục',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _categories.length > 8 ? 8 : _categories.length, // Limit to 8 categories
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategory = _categories[index]['name'];
                          _performSearch(_categories[index]['name']);
                        });
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _categories[index]['icon'],
                              color: Colors.blue[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _categories[index]['name'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
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

          // Trending products
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sản phẩm thịnh hành',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 290,
                  child: FutureBuilder<List<Product>>(
                    future: Provider.of<ProductService>(context, listen: false)
                        .getRecommendedProducts(limit: 5),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('Không có sản phẩm thịnh hành'),
                        );
                      }

                      final products = snapshot.data!;

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 180,
                            margin: const EdgeInsets.only(right: 8),
                            child: ProductCardStandard(
                              product: products[index],
                              isCompact: true,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 