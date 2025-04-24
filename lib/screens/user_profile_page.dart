import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_market_nttu/models/user.dart';
import 'package:student_market_nttu/models/product.dart';
import 'package:student_market_nttu/services/user_service.dart';
import 'package:student_market_nttu/services/product_service.dart';
import 'package:student_market_nttu/screens/product_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:student_market_nttu/services/auth_service.dart';
import 'package:student_market_nttu/screens/add_product_screen.dart';
import 'package:student_market_nttu/screens/edit_product_screen.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  final String? username;

  const UserProfilePage({
    super.key,
    required this.userId,
    this.username,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Stream<List<Product>> _productsStream;
  UserModel? _userProfile;
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isProcessingFollow = false;
  int _followerCount = 0;
  int _followingCount = 0;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserProfile();
    _productsStream = Provider.of<ProductService>(context, listen: false)
        .getUserProducts(widget.userId);
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      
      if (userDoc.exists) {
        setState(() {
          _userProfile = UserModel.fromMap(userDoc.data()!, userDoc.id);
          _isLoading = false;
        });
        
        // Kiểm tra trạng thái follow và số liệu thống kê
        await _loadFollowStats();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải thông tin người dùng: $e')),
        );
      }
    }
  }
  
  Future<void> _loadFollowStats() async {
    final userService = Provider.of<UserService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Chỉ kiểm tra nếu không phải trang cá nhân của người dùng hiện tại
    if (authService.user?.uid != widget.userId) {
      final isFollowing = await userService.isFollowing(widget.userId);
      setState(() {
        _isFollowing = isFollowing;
      });
    }
    
    // Lấy số lượng follower và following
    final followerCount = await userService.getFollowerCount(widget.userId);
    final followingCount = await userService.getFollowingCount(widget.userId);
    
    setState(() {
      _followerCount = followerCount;
      _followingCount = followingCount;
    });
  }
  
  Future<void> _toggleFollow() async {
    if (_isProcessingFollow) return;
    
    setState(() {
      _isProcessingFollow = true;
    });
    
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      await userService.toggleFollow(widget.userId);
      
      // Cập nhật lại trạng thái và số liệu
      await _loadFollowStats();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể thực hiện: $e')),
      );
    } finally {
      setState(() {
        _isProcessingFollow = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isCurrentUser = authService.user?.uid == widget.userId;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.username ?? 'Trang người dùng'),
        actions: [
          if (!isCurrentUser && authService.user != null)
            _buildFollowButton(),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Thông tin'),
            Tab(text: 'Sản phẩm'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(),
                _buildProductsTab(),
              ],
            ),
    );
  }
  
  Widget _buildFollowButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: _isProcessingFollow
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white, 
                strokeWidth: 2,
              ),
            )
          : TextButton.icon(
              onPressed: _toggleFollow,
              icon: Icon(
                _isFollowing ? Icons.person_remove : Icons.person_add,
                color: Colors.white,
              ),
              label: Text(
                _isFollowing ? 'Đang theo dõi' : 'Theo dõi',
                style: const TextStyle(color: Colors.white),
              ),
              style: TextButton.styleFrom(
                backgroundColor: _isFollowing 
                    ? Colors.grey.withOpacity(0.5)
                    : Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
    );
  }

  Widget _buildProfileTab() {
    if (_userProfile == null) {
      return const Center(child: Text('Không tìm thấy thông tin người dùng'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: _userProfile?.photoURL.isNotEmpty == true
                    ? NetworkImage(_userProfile!.photoURL)
                    : null,
                backgroundColor: Colors.grey[300],
                child: _userProfile?.photoURL.isEmpty != false
                    ? const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.grey,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userProfile?.displayName.isNotEmpty == true
                          ? _userProfile!.displayName
                          : 'Người dùng',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Hiển thị đánh giá sao
                    Row(
                      children: [
                        _buildRatingStars(_userProfile?.rating ?? 0),
                        const SizedBox(width: 4),
                        Text(
                          '(${(_userProfile?.rating ?? 0).toStringAsFixed(1)})',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (_userProfile?.isShipper == true)
                      Chip(
                        label: const Text('Shipper'),
                        backgroundColor: Theme.of(context).primaryColor,
                        labelStyle: const TextStyle(color: Colors.white),
                      ),
                    if (_userProfile?.isStudent == true)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Chip(
                          label: const Text('Sinh viên NTTU'),
                          backgroundColor: Colors.blue.shade100,
                          labelStyle: TextStyle(color: Colors.blue.shade800),
                          avatar: const Icon(Icons.school, size: 16, color: Colors.blue),
                        ),
                      ),
                    // Hiển thị badge shop nổi bật nếu rating cao
                    if (_userProfile != null && _userProfile!.rating >= 4.5)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Chip(
                          label: const Text('Shop Nổi Bật'),
                          backgroundColor: Colors.amber.shade100,
                          labelStyle: TextStyle(color: Colors.amber.shade800),
                          avatar: const Icon(Icons.workspace_premium, size: 16, color: Colors.amber),
                        ),
                      ),
                    // Hiển thị badge người quyên góp nếu NTT Credit cao
                    if (_userProfile != null && _userProfile!.nttCredit >= 130)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Chip(
                          label: const Text('Người Quyên Góp'),
                          backgroundColor: Colors.green.shade100,
                          labelStyle: TextStyle(color: Colors.green.shade800),
                          avatar: const Icon(Icons.volunteer_activism, size: 16, color: Colors.green),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Tham gia từ ${_formatDate(_userProfile?.createdAt)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          // Credit và Point Card
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.blue.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thông tin tài khoản',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCreditInfo(
                      'NTT Point',
                      '${_userProfile?.nttPoint ?? 0}',
                      Icons.monetization_on,
                      Colors.amber,
                    ),
                    _buildCreditInfo(
                      'NTT Credit',
                      '${_userProfile?.nttCredit ?? 0}',
                      Icons.credit_score,
                      Colors.green,
                      subtitle: _userProfile?.getCreditRating() ?? '',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_userProfile?.bio?.isNotEmpty == true) ...[
            const Text(
              'Giới thiệu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(_userProfile!.bio!),
            const Divider(height: 32),
          ],
          // Student information details
          if (_userProfile?.isStudent == true &&
              (_userProfile?.studentId?.isNotEmpty == true || 
               _userProfile?.department?.isNotEmpty == true)) ...[
            const Text(
              'Thông tin sinh viên',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (_userProfile?.studentId?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.badge, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text('MSSV: ${_userProfile!.studentId}'),
                  ],
                ),
              ),
            if (_userProfile?.department?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.school, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text('Khoa: ${_userProfile!.department}'),
                  ],
                ),
              ),
            const Divider(height: 32),
          ],
          const Text(
            'Thống kê',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Lấy thống kê sản phẩm để hiển thị
          StreamBuilder<List<Product>>(
            stream: Provider.of<ProductService>(context).getUserProducts(widget.userId),
            builder: (context, snapshot) {
              // Tính toán thống kê từ sản phẩm
              int productCount = 0;
              double avgRating = 0;
              int ratedProductCount = 0;
              int soldProductCount = 0;
              
              if (snapshot.hasData) {
                final allProducts = snapshot.data!;
                // Lấy danh sách sản phẩm hiển thị (không bao gồm đang duyệt)
                final products = allProducts
                    .where((p) => p.status != ProductStatus.pending_review)
                    .toList();
                
                productCount = products.length;
                
                // Tính đánh giá trung bình chỉ từ sản phẩm có rating > 0
                var ratedProducts = products.where((p) => p.rating > 0).toList();
                ratedProductCount = ratedProducts.length;
                
                if (ratedProductCount > 0) {
                  double totalRating = ratedProducts.fold(0, (sum, p) => sum + p.rating);
                  avgRating = totalRating / ratedProductCount;
                }
                
                // Đếm số sản phẩm đã bán
                soldProductCount = products.where((p) => p.isSold).length;
              }
              
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(Icons.shopping_bag, 'Sản phẩm', '$productCount'),
                  _buildStatItem(
                    Icons.star, 
                    'Đánh giá', 
                    ratedProductCount > 0 ? avgRating.toStringAsFixed(1) : '0'
                  ),
                  _buildStatItem(Icons.people, 'Người theo dõi', '$_followerCount'),
                  _buildStatItem(Icons.sell, 'Đã bán', '$soldProductCount'),
                ],
              );
            }
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star, size: 16, color: Colors.amber[700]);
        } else if (index == rating.floor() && rating % 1 > 0) {
          return Icon(Icons.star_half, size: 16, color: Colors.amber[700]);
        } else {
          return Icon(Icons.star_border, size: 16, color: Colors.amber[700]);
        }
      }),
    );
  }

  Widget _buildCreditInfo(String title, String value, IconData icon, Color color, {String subtitle = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildProductsTab() {
    // Lấy user hiện tại để so sánh với userId của shop
    final currentUser = Provider.of<AuthService>(context).user;
    final isOwner = currentUser != null && currentUser.uid == widget.userId;

    return Column(
      children: [
        if (isOwner)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quản lý sản phẩm',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddProductScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm sản phẩm'),
                ),
              ],
            ),
          ),
        Expanded(
          child: StreamBuilder<List<Product>>(
            stream: _productsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Lỗi: ${snapshot.error}'),
                );
              }

              var allProducts = snapshot.data ?? [];
              
              // Lọc sản phẩm: 
              // - Nếu là chủ cửa hàng, hiển thị tất cả các sản phẩm
              // - Nếu là người xem, chỉ hiển thị các sản phẩm đã được duyệt (available)
              final products = isOwner 
                  ? allProducts 
                  : allProducts.where((p) => p.status == ProductStatus.available).toList();

              if (products.isEmpty) {
                return Center(
                  child: isOwner
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Bạn chưa có sản phẩm nào'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AddProductScreen(),
                                  ),
                                );
                              },
                              child: const Text('Thêm sản phẩm'),
                            ),
                          ],
                        )
                      : const Text('Người dùng chưa đăng bán sản phẩm nào'),
                );
              }

              // Tách sản phẩm nổi bật (rating ≥ 4.0)
              final featuredProducts = products.where((p) => p.rating >= 4.0 && p.status == ProductStatus.available).toList();
              final regularProducts = products.where((p) => p.rating < 4.0 && 
                (isOwner || p.status == ProductStatus.available)).toList();

              return featuredProducts.isNotEmpty
                  ? SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Phần sản phẩm nổi bật
                          if (featuredProducts.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Icon(Icons.workspace_premium, color: Colors.amber[700], size: 20),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Sản phẩm nổi bật',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 300,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: featuredProducts.length,
                                itemBuilder: (context, index) {
                                  return SizedBox(
                                    width: 180,
                                    child: Card(
                                      clipBehavior: Clip.antiAlias,
                                      elevation: 2,
                                      child: _buildFeaturedProductItem(featuredProducts[index], isOwner),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const Divider(),
                          ],
                          
                          // Phần tất cả sản phẩm
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              featuredProducts.isNotEmpty ? 'Tất cả sản phẩm' : 'Sản phẩm',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(8),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.58,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: regularProducts.length,
                            itemBuilder: (context, index) {
                              return _buildProductItem(regularProducts[index], isOwner);
                            },
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.58,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        return _buildProductItem(products[index], isOwner);
                      },
                    );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedProductItem(Product product, bool isOwner) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: product.images.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.images.first,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 50, color: Colors.grey),
                      ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.white),
                      const SizedBox(width: 2),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormat.format(product.price),
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (product.isSold) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Đã bán',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(Product product, bool isOwner) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hình ảnh sản phẩm
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(product: product),
                    ),
                  );
                },
                child: AspectRatio(
                  aspectRatio: 1,
                  child: product.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.images.first,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 50, color: Colors.grey),
                        ),
                ),
              ),
              
              // Thông tin sản phẩm
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          currencyFormat.format(product.price),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.star, size: 14, color: Colors.amber[700]),
                            const SizedBox(width: 2),
                            Text(
                              product.rating.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (product.isSold) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Đã bán',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: Colors.grey),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            product.location ?? 'Không xác định',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Nút quản lý sản phẩm cho chủ shop
          if (isOwner)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EditProductScreen(product: product),
                        ),
                      );
                    } else if (value == 'status') {
                      try {
                        await Provider.of<ProductService>(context, listen: false)
                            .updateProductStatus(product.id, !product.isSold);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cập nhật trạng thái thành công'),
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
                    } else if (value == 'delete') {
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
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Chỉnh sửa'),
                    ),
                    PopupMenuItem(
                      value: 'status',
                      child: Text(
                        product.isSold ? 'Đánh dấu đang bán' : 'Đánh dấu đã bán',
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Xóa'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Không xác định';
    return DateFormat('dd/MM/yyyy').format(date);
  }
}