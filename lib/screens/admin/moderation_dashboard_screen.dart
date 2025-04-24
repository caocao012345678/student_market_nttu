import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:student_market_nttu/models/moderation_result.dart';
import 'package:student_market_nttu/models/product.dart';
import 'package:student_market_nttu/services/user_service.dart';
import 'package:student_market_nttu/screens/product_detail_screen.dart';
import 'package:student_market_nttu/screens/moderation_result_screen.dart';
import 'package:student_market_nttu/services/auth_service.dart';
import 'package:student_market_nttu/services/product_service.dart';

class ModerationDashboardScreen extends StatefulWidget {
  const ModerationDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ModerationDashboardScreen> createState() => _ModerationDashboardScreenState();
}

class _ModerationDashboardScreenState extends State<ModerationDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  bool _isAdmin = false;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  double _currentScore = 0.0;
  List<String> _selectedIssues = [];
  List<Product> _products = [];
  ProductService _productService = ProductService();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkAdminStatus();
    _refreshProducts();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _commentController.dispose();
    _reasonController.dispose();
    super.dispose();
  }
  
  Future<void> _checkAdminStatus() async {
    final userService = Provider.of<UserService>(context, listen: false);
    final isAdmin = await userService.isCurrentUserAdmin();
    setState(() {
      _isAdmin = isAdmin;
    });
    
    if (!isAdmin && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn không có quyền truy cập trang này'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Đang tải...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý kiểm duyệt'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chờ xử lý'),
            Tab(text: 'Đang xem'),
            Tab(text: 'Đã duyệt'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              // TODO: Hiển thị thống kê kiểm duyệt
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tiêu đề, ID, người đăng...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductList(),
                _buildProductsList('in_review'),
                _buildProductsList('approved'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProductList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_products.isEmpty) {
      return const Center(child: Text('Không có sản phẩm nào đang chờ duyệt'));
    }

    return ListView.builder(
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            leading: product.images.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.images[0],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(Icons.error),
                        );
                      },
                    ),
                  )
                : Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
                  ),
            title: Text(product.title),
            subtitle: Text(
              'Giá: ${product.price.toStringAsFixed(0)} VNĐ',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: ButtonBar(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(product: product),
                      ),
                    );
                  },
                  child: const Text('Chi tiết'),
                ),
                TextButton(
                  onPressed: () {
                    _showModerationActionSheet(product);
                  },
                  child: const Text('Kiểm duyệt'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildProductsList(String status) {
    Query query = FirebaseFirestore.instance.collection('moderation_results')
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true);
    
    if (_searchQuery.isNotEmpty) {
      // Trong thực tế, bạn sẽ cần triển khai tìm kiếm nâng cao hơn
      // Có thể cần lưu thêm thông tin trong bảng moderation_results
      // hoặc thực hiện truy vấn kết hợp
    }
    
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Lỗi: ${snapshot.error}'),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('Không có sản phẩm nào'),
          );
        }
        
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final moderationData = doc.data() as Map<String, dynamic>;
            final productId = moderationData['productId'] as String;
            
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('products').doc(productId).get(),
              builder: (context, productSnapshot) {
                if (!productSnapshot.hasData) {
                  return const Card(
                    margin: EdgeInsets.all(8),
                    child: ListTile(
                      title: Text('Đang tải...'),
                    ),
                  );
                }
                
                if (!productSnapshot.data!.exists) {
                  return const SizedBox.shrink(); // Sản phẩm đã bị xóa
                }
                
                final productData = productSnapshot.data!.data() as Map<String, dynamic>;
                final title = productData['title'] as String? ?? 'Không có tiêu đề';
                final price = productData['price'] as num? ?? 0;
                final images = List<String>.from(productData['images'] ?? []);
                final createdAt = (moderationData['createdAt'] as Timestamp).toDate();
                final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
                
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: InkWell(
                    onTap: () {
                      _navigateToProductDetail(productId);
                    },
                    child: Column(
                      children: [
                        ListTile(
                          leading: images.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    images[0],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.image, size: 50),
                                  ),
                                )
                              : const Icon(Icons.image_not_supported, size: 50),
                          title: Text(title),
                          subtitle: Text(
                            'ID: $productId\nNgày: ${dateFormat.format(createdAt)}',
                          ),
                          trailing: Text(
                            '${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(price)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          isThreeLine: true,
                        ),
                        ButtonBar(
                          children: [
                            TextButton(
                              onPressed: () {
                                _navigateToProductDetail(productId);
                              },
                              child: const Text('Xem sản phẩm'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ModerationResultScreen(productId: productId),
                                  ),
                                );
                              },
                              child: const Text('Xem chi tiết'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
  
  Future<void> _navigateToProductDetail(String productId) async {
    try {
      final productDoc = await FirebaseFirestore.instance.collection('products').doc(productId).get();
      if (!productDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sản phẩm không tồn tại')),
          );
        }
        return;
      }
      
      final productData = productDoc.data() as Map<String, dynamic>;
      final product = Product.fromMap(productData, productId);
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }
  
  void _showModerationActionSheet(Product product) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('Xem chi tiết sản phẩm'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(product: product),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Duyệt sản phẩm'),
                onTap: () {
                  Navigator.pop(context);
                  _showApproveDialog(product);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Từ chối sản phẩm'),
                onTap: () {
                  Navigator.pop(context);
                  _showRejectDialog(product);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showApproveDialog(Product product) {
    _commentController.clear();
    _currentScore = 5.0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Phê duyệt sản phẩm'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Chất lượng sản phẩm (1-5)'),
              Slider(
                value: _currentScore,
                min: 1.0,
                max: 5.0,
                divisions: 8,
                label: _currentScore.toString(),
                onChanged: (value) {
                  setState(() {
                    _currentScore = value;
                  });
                },
              ),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Nhận xét (tùy chọn)',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _approveProduct(product);
            },
            child: const Text('Phê duyệt', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }
  
  void _showRejectDialog(Product product) {
    _reasonController.clear();
    _currentScore = 3.0;
    _selectedIssues = [];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Từ chối sản phẩm'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Chất lượng sản phẩm (1-5)'),
              Slider(
                value: _currentScore,
                min: 1.0,
                max: 5.0,
                divisions: 8,
                label: _currentScore.toString(),
                onChanged: (value) {
                  setState(() {
                    _currentScore = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  hintText: 'Lý do từ chối',
                  labelText: 'Lý do từ chối',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Text('Vấn đề với sản phẩm:'),
              const SizedBox(height: 8),
              _buildIssueCheckboxes(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectProduct(product);
            },
            child: const Text('Từ chối', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildIssueCheckboxes() {
    final issues = [
      'Hình ảnh không rõ ràng',
      'Thông tin không đầy đủ',
      'Giá không hợp lý',
      'Sản phẩm không phù hợp',
      'Sản phẩm cấm',
      'Khác',
    ];

    return Column(
      children: issues.map((issue) {
        return CheckboxListTile(
          title: Text(issue),
          value: _selectedIssues.contains(issue),
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                _selectedIssues.add(issue);
              } else {
                _selectedIssues.remove(issue);
              }
            });
          },
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
        );
      }).toList(),
    );
  }
  
  Future<void> _approveProduct(Product product) async {
    setState(() {
      _isLoading = true;
    });

    // Tạo kết quả kiểm duyệt
    final Map<String, dynamic> moderationResults = {
      'approvedAt': FieldValue.serverTimestamp(),
      'moderatorId': AuthService().currentUser!.uid,
      'comment': _commentController.text.trim(),
      'score': _currentScore,
    };

    // Gọi service để phê duyệt sản phẩm
    final success = await _productService.approveProduct(
      product.id,
      moderationResults,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      _showSnackBar('Sản phẩm đã được phê duyệt thành công');
      _refreshProducts();
    } else {
      _showSnackBar('Lỗi khi phê duyệt sản phẩm', isError: true);
    }
  }
  
  Future<void> _rejectProduct(Product product) async {
    setState(() {
      _isLoading = true;
    });

    // Validate reason
    if (_reasonController.text.trim().isEmpty) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Vui lòng nhập lý do từ chối', isError: true);
      return;
    }

    // Tạo kết quả kiểm duyệt
    final Map<String, dynamic> moderationResults = {
      'rejectedAt': FieldValue.serverTimestamp(),
      'moderatorId': AuthService().currentUser!.uid,
      'reason': _reasonController.text.trim(),
      'score': _currentScore,
      'issues': _selectedIssues,
    };

    // Gọi service để từ chối sản phẩm
    final success = await _productService.rejectProduct(
      product.id,
      moderationResults,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      _showSnackBar('Sản phẩm đã bị từ chối');
      _refreshProducts();
    } else {
      _showSnackBar('Lỗi khi từ chối sản phẩm', isError: true);
    }
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _productService.getPendingProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error refreshing products: $e');
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Lỗi khi tải danh sách sản phẩm', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
} 