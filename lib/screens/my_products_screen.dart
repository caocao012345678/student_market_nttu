import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/moderation_result.dart';
import '../services/auth_service.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/category_service.dart';
import 'product_detail_screen.dart';
import 'add_product_screen.dart';
import 'moderation_history_screen.dart';
import 'edit_product_screen.dart';

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
    _tabController = TabController(length: 4, vsync: this);
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
            icon: const Icon(Icons.history),
            tooltip: 'Lịch sử kiểm duyệt',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ModerationHistoryScreen(),
                ),
              );
            },
          ),
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
            Tab(text: 'Đang duyệt'),
            Tab(text: 'Bị từ chối'),
          ],
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          isScrollable: true,
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
                // Tab Đang bán - Available products
                _buildProductsByStatus(user.uid, ProductStatus.available),
                // Tab Đã bán - Sold products
                _buildProductsByStatus(user.uid, ProductStatus.sold),
                // Tab Đang duyệt - Products pending review
                _buildProductsByStatus(user.uid, ProductStatus.pending_review),
                // Tab Bị từ chối - Rejected products
                _buildProductsByStatus(user.uid, ProductStatus.rejected),
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

  Widget _buildProductsByStatus(String userId, ProductStatus status) {
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
        
        // Filter by status
        var products = allProducts.where((product) => product.status == status).toList();
        
        // Filter by category if not 'All'
        if (_selectedCategory != 'Tất cả') {
          products = products.where((product) => product.category == _selectedCategory).toList();
        }

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_getEmptyMessage(status)),
                if (status == ProductStatus.available) ...[
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
              childAspectRatio: 0.62,
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

  String _getEmptyMessage(ProductStatus status) {
    switch (status) {
      case ProductStatus.available:
        return 'Bạn chưa có sản phẩm nào đang bán';
      case ProductStatus.sold:
        return 'Bạn chưa có sản phẩm nào đã bán';
      case ProductStatus.pending_review:
        return 'Bạn không có sản phẩm nào đang chờ duyệt';
      case ProductStatus.rejected:
        return 'Bạn không có sản phẩm nào bị từ chối';
      default:
        return 'Không có sản phẩm nào';
    }
  }

  Widget _buildProductGridItem(BuildContext context, Product product) {
    final categoryService = Provider.of<CategoryService>(context, listen: false);

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
                    children: [
                      Expanded(
                        child: FutureBuilder<String>(
                          future: _getCategoryName(categoryService, product.category),
                          builder: (context, snapshot) {
                            return Chip(
                              label: Text(
                                snapshot.data ?? product.category,
                                style: const TextStyle(fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              backgroundColor: Colors.blue[50],
                            );
                          }
                        ),
                      ),
                      PopupMenuButton(
                        icon: const Icon(Icons.more_vert, size: 20),
                        itemBuilder: _buildPopupMenuItems,
                        onSelected: (value) => _handlePopupAction(value, product),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _buildStatusBadge(product.status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductListItem(BuildContext context, Product product) {
    final categoryService = Provider.of<CategoryService>(context, listen: false);
    
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
        title: Text(
          product.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
                Expanded(
                  child: FutureBuilder<String>(
                    future: _getCategoryName(categoryService, product.category),
                    builder: (context, snapshot) {
                      return Chip(
                        label: Text(
                          snapshot.data ?? product.category,
                          style: const TextStyle(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.blue[50],
                      );
                    }
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(product.status),
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
        value: 'view_moderation',
        child: Row(
          children: [
            Icon(Icons.fact_check, size: 18),
            SizedBox(width: 8),
            Text('Xem chi tiết kiểm duyệt'),
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
        // Chuyển đến màn hình chỉnh sửa sản phẩm
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EditProductScreen(product: product),
          ),
        );
        
        // Nếu có sự thay đổi, refresh lại danh sách sản phẩm
        if (result == true) {
          setState(() {});
        }
        break;
      case 'view_moderation':
        _showModerationDetails(product);
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

  void _showModerationDetails(Product product) async {
    // Get moderation details from Firestore
    final moderationResult = await Provider.of<ProductService>(context, listen: false)
        .getProductModerationInfo(product.id);
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết kiểm duyệt: ${product.title}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (moderationResult == null) ...[
                const Text('Không có thông tin kiểm duyệt cho sản phẩm này.'),
              ] else ...[
                ListTile(
                  title: const Text('Trạng thái:'),
                  subtitle: Text(
                    moderationResult.status == ModerationStatus.approved ? 'Đã duyệt' :
                    moderationResult.status == ModerationStatus.rejected ? 'Bị từ chối' :
                    moderationResult.status == ModerationStatus.in_review ? 'Đang xem xét' : 'Đang chờ duyệt',
                    style: TextStyle(
                      color: moderationResult.status == ModerationStatus.approved ? Colors.green :
                      moderationResult.status == ModerationStatus.rejected ? Colors.red : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Thời gian:'),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy - HH:mm').format(moderationResult.createdAt),
                  ),
                ),
                if (moderationResult.rejectionReason != null && moderationResult.rejectionReason!.isNotEmpty) 
                  ListTile(
                    title: const Text('Lý do từ chối:'),
                    subtitle: Text(moderationResult.rejectionReason!),
                  ),
                const Divider(),
                const Text('Điểm đánh giá:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildScoreItem('Nội dung', moderationResult.contentScore / 10),
                _buildScoreItem('Hình ảnh', moderationResult.imageScore / 10),
                _buildScoreItem('Tuân thủ', moderationResult.complianceScore / 10),
                _buildScoreItem('Tổng', moderationResult.totalScore / 10),
                if (moderationResult.issues != null && moderationResult.issues!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text('Vấn đề được phát hiện:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  ...moderationResult.issues!.map((issue) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          issue.severity == 'high' ? Icons.error : 
                          issue.severity == 'medium' ? Icons.warning : Icons.info_outline,
                          color: issue.severity == 'high' ? Colors.red : 
                                issue.severity == 'medium' ? Colors.orange : Colors.blue,
                          size: 16
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(issue.description)),
                      ],
                    ),
                  )).toList(),
                ],
                if (moderationResult.suggestedTags != null && moderationResult.suggestedTags!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text('Thẻ gợi ý:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: moderationResult.suggestedTags!.map((tag) => Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.blue[50],
                      visualDensity: VisualDensity.compact,
                    )).toList(),
                  ),
                ],
              ],
            ],
          ),
        ),
        actions: [
          if (product.status == ProductStatus.rejected)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Chuyển đến màn hình chỉnh sửa sản phẩm để sửa lỗi
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditProductScreen(product: product),
                  ),
                );
              },
              child: const Text('Chỉnh sửa sản phẩm'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildScoreItem(String label, double score) {
    Color color;
    if (score >= 8) {
      color = Colors.green;
    } else if (score >= 6) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Text('$label: '),
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Text('/10'),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ProductStatus status) {
    String label;
    Color color;
    
    switch (status) {
      case ProductStatus.available:
        label = 'Đang bán';
        color = Colors.green;
        break;
      case ProductStatus.sold:
        label = 'Đã bán';
        color = Colors.red;
        break;
      case ProductStatus.pending_review:
        label = 'Đang duyệt';
        color = Colors.orange;
        break;
      case ProductStatus.rejected:
        label = 'Bị từ chối';
        color = Colors.purple;
        break;
      case ProductStatus.hidden:
        label = 'Đã ẩn';
        color = Colors.grey;
        break;
      case ProductStatus.reserved:
        label = 'Đã đặt trước';
        color = Colors.blue;
        break;
      default:
        label = 'Không xác định';
        color = Colors.grey;
    }
    
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      backgroundColor: color,
    );
  }

  Future<String> _getCategoryName(CategoryService categoryService, String categoryId) async {
    final category = await categoryService.getCategoryById(categoryId);
    return category?.name ?? categoryId;
  }
}