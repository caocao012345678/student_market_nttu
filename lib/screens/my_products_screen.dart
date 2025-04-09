import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'product_detail_screen.dart';
import 'add_product_screen.dart';

class MyProductsScreen extends StatefulWidget {
  const MyProductsScreen({Key? key}) : super(key: key);

  @override
  State<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends State<MyProductsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'Tất cả';
  bool _isGridView = true;

  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.all_inclusive, 'name': 'Tất cả'},
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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Vui lòng đăng nhập để xem sản phẩm của bạn'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sản phẩm của tôi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AddProductScreen(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Đang bán'),
            Tab(text: 'Đã bán'),
          ],
          labelColor: Colors.white,
          indicatorColor: Colors.white,
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ChoiceChip(
                    label: Row(
                      children: [
                        Icon(
                          _categories[index]['icon'],
                          size: 16,
                          color: _selectedCategory == _categories[index]['name']
                              ? Colors.white
                              : Colors.blue[900],
                        ),
                        const SizedBox(width: 4),
                        Text(_categories[index]['name']),
                      ],
                    ),
                    selected: _selectedCategory == _categories[index]['name'],
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = _categories[index]['name'];
                      });
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Colors.blue[900],
                    labelStyle: TextStyle(
                      color: _selectedCategory == _categories[index]['name']
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hiển thị ${_selectedCategory == 'Tất cả' ? 'tất cả sản phẩm' : 'sản phẩm $_selectedCategory'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab Đang bán
                _buildProductList(user.uid, false),
                // Tab Đã bán
                _buildProductList(user.uid, true),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddProductScreen(),
            ),
          );
        },
        backgroundColor: Colors.blue[900],
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProductList(String userId, bool isSold) {
    return StreamBuilder<List<Product>>(
      stream: Provider.of<ProductService>(context).getUserProducts(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Đã xảy ra lỗi: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final allProducts = snapshot.data!;
        
        // Filter by status (sold or not)
        var products = allProducts.where((product) => product.isSold == isSold).toList();
        
        // Filter by category if not 'All'
        if (_selectedCategory != 'Tất cả') {
          products = products.where((product) => product.category == _selectedCategory).toList();
        }

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isSold ? 'Bạn chưa có sản phẩm nào đã bán' : 'Bạn chưa có sản phẩm nào đang bán'
                ),
                if (!isSold) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AddProductScreen(),
                        ),
                      );
                    },
                    child: const Text('Thêm sản phẩm'),
                  ),
                ],
              ],
            ),
          );
        }

        if (_isGridView) {
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductGridItem(context, product);
            },
          );
        } else {
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return _buildProductListItem(context, product);
            },
          );
        }
      },
    );
  }

  Widget _buildProductGridItem(BuildContext context, Product product) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: product.images.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.images.first,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    )
                  : Container(
                      width: double.infinity,
                      height: 120,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 40),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
                        .format(product.price),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        label: Text(
                          product.category,
                          style: const TextStyle(fontSize: 10),
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.blue[50],
                      ),
                      PopupMenuButton(
                        icon: const Icon(Icons.more_vert, size: 20),
                        itemBuilder: _buildPopupMenuItems,
                        onSelected: (value) => _handlePopupAction(value, product),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductListItem(BuildContext context, Product product) {
    return Card(
      child: ListTile(
        leading: product.images.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: product.images.first,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error),
                ),
              )
            : Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.image_not_supported),
              ),
        title: Text(product.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
                  .format(product.price),
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Chip(
                  label: Text(
                    product.category,
                    style: const TextStyle(fontSize: 10),
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.blue[50],
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    product.isSold ? 'Đã bán' : 'Đang bán',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: product.isSold ? Colors.red : Colors.green,
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: _buildPopupMenuItems,
          onSelected: (value) => _handlePopupAction(value, product),
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          );
        },
      ),
    );
  }
  
  List<PopupMenuEntry<String>> _buildPopupMenuItems(BuildContext context) {
    return [
      const PopupMenuItem(
        value: 'edit',
        child: Row(
          children: [
            Icon(Icons.edit, size: 18),
            SizedBox(width: 8),
            Text('Chỉnh sửa'),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'status',
        child: Row(
          children: [
            Icon(Icons.swap_horiz, size: 18),
            SizedBox(width: 8),
            Text('Đổi trạng thái'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'delete',
        child: Row(
          children: [
            Icon(Icons.delete, size: 18, color: Colors.red),
            SizedBox(width: 8),
            Text('Xóa', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    ];
  }
  
  Future<void> _handlePopupAction(String value, Product product) async {
    switch (value) {
      case 'edit':
        // TODO: Navigate to edit product screen
        break;
      case 'status':
        try {
          await Provider.of<ProductService>(context, listen: false)
              .updateProductStatus(product.id, !product.isSold);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(product.isSold 
                  ? 'Sản phẩm đã chuyển sang trạng thái đang bán' 
                  : 'Sản phẩm đã chuyển sang trạng thái đã bán'),
            ),
          );
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${e.toString()}'),
            ),
          );
        }
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xác nhận xóa'),
            content: const Text(
              'Bạn có chắc chắn muốn xóa sản phẩm này không?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xóa'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          try {
            await Provider.of<ProductService>(context, listen: false)
                .deleteProduct(product.id);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Xóa sản phẩm thành công'),
              ),
            );
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi: ${e.toString()}'),
              ),
            );
          }
        }
        break;
    }
  }
} 