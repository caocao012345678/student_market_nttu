import 'package:flutter/material.dart' hide CarouselController;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/product.dart';
import '../models/review.dart';
import '../services/auth_service.dart';
import '../services/review_service.dart';
import '../services/order_service.dart';
import '../services/cart_service.dart';
import '../models/purchase_order.dart';
import '../screens/user_profile_page.dart';
import '../screens/product_list_screen.dart';
import '../screens/cart_screen.dart';
import '../widgets/cart_badge.dart';
import '../widgets/related_products_section.dart';
import '../services/user_service.dart';
import '../services/product_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> with SingleTickerProviderStateMixin {
  final _reviewController = TextEditingController();
  double _rating = 5.0;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  bool _isFavorite = false;
  late TabController _tabController;
  int _quantity = 1;
  final _scrollController = ScrollController();
  bool _showAppBarTitle = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
    
    _updateProductViewData();
  }

  void _onScroll() {
    if (_scrollController.offset > 200 && !_showAppBarTitle) {
      setState(() => _showAppBarTitle = true);
    } else if (_scrollController.offset <= 200 && _showAppBarTitle) {
      setState(() => _showAppBarTitle = false);
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _pageController.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
      // TODO: Implement saving favorite state to database
    });
  }

  Future<void> _addToCart(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final cartService = Provider.of<CartService>(context, listen: false);
    
    if (authService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để thêm vào giỏ hàng')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);
      
      await cartService.addToCart(widget.product, authService.currentUser!.uid);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm ${widget.product.title} vào giỏ hàng'),
          action: SnackBarAction(
            label: 'XEM GIỎ HÀNG',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _shareProduct() async {
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      'Xem sản phẩm ${widget.product.title} tại Student Market NTTU',
      subject: widget.product.title,
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đánh giá')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Provider.of<AuthService>(context, listen: false).user;
      if (user == null) throw Exception('Vui lòng đăng nhập để đánh giá');

      final review = Review(
        id: '',
        productId: widget.product.id,
        userId: user.uid,
        userEmail: user.email!,
        rating: _rating,
        comment: _reviewController.text.trim(),
        createdAt: DateTime.now(),
        likes: [],
        comments: [],
      );

      await Provider.of<ReviewService>(context, listen: false).addReview(review);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đánh giá thành công')),
      );

      _reviewController.clear();
      setState(() => _rating = 5.0);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showPurchaseDialog(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để mua hàng'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Xác nhận mua hàng',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: widget.product.images.isNotEmpty
                              ? widget.product.images.first
                              : 'https://via.placeholder.com/100',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.title,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              NumberFormat.currency(
                                locale: 'vi_VN',
                                symbol: 'đ',
                              ).format(widget.product.price),
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Số lượng:'),
                      const SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: _quantity > 1
                                  ? () => setState(() => _quantity--)
                                  : null,
                            ),
                            Text(_quantity.toString()),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _quantity < widget.product.quantity
                                  ? () => setState(() => _quantity++)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Còn ${widget.product.quantity} sản phẩm',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ nhận hàng',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập địa chỉ nhận hàng';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập số điện thoại';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Tổng tiền:'),
                      const Spacer(),
                      Text(
                        NumberFormat.currency(
                          locale: 'vi_VN',
                          symbol: 'đ',
                        ).format(widget.product.price * _quantity),
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _placeOrder,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Xác nhận'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.user;
      if (user == null) throw Exception('Vui lòng đăng nhập để mua hàng');

      final order = PurchaseOrder(
        id: '',
        productId: widget.product.id,
        productTitle: widget.product.title,
        productImage: widget.product.images.isNotEmpty
            ? widget.product.images.first
            : '',
        sellerId: widget.product.sellerId,
        buyerId: user.uid,
        buyerName: user.displayName ?? user.email ?? 'Không có tên',
        price: widget.product.price,
        quantity: _quantity,
        address: _addressController.text,
        phone: _phoneController.text,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final orderId = await Provider.of<OrderService>(context, listen: false)
          .createOrder(order);

      if (!mounted) return;
      final paymentMethod = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Chọn phương thức thanh toán'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.money),
                title: const Text('Thanh toán khi nhận hàng'),
                onTap: () => Navigator.pop(context, 'COD'),
              ),
              ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text('Thẻ tín dụng/ghi nợ'),
                onTap: () => Navigator.pop(context, 'CARD'),
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text('Ví điện tử'),
                onTap: () => Navigator.pop(context, 'E_WALLET'),
              ),
            ],
          ),
        ),
      );

      if (paymentMethod != null) {
        await Provider.of<OrderService>(context, listen: false)
            .completeOrder(orderId, paymentMethod);

        if (!mounted) return;
        Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đặt hàng thành công'),
        ),
      );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
        ),
      );
    } finally {
        setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    );
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                floating: false,
                title: _showAppBarTitle ? Text(widget.product.title) : null,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildImageGallery(),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : Colors.white,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: _shareProduct,
                  ),
                  const CartBadge(),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.title,
                        style: const TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormat.format(widget.product.price),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Seller info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: widget.product.sellerAvatar.isNotEmpty
                                ? NetworkImage(widget.product.sellerAvatar)
                                : null,
                            child: widget.product.sellerAvatar.isEmpty
                                ? const Icon(Icons.person, size: 18)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.product.sellerName.isNotEmpty
                                      ? widget.product.sellerName
                                      : 'Người bán',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (widget.product.location.isNotEmpty)
                                  Text(
                                    widget.product.location,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserProfilePage(
                                    userId: widget.product.sellerId,
                                    username: widget.product.sellerName,
                                  ),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            child: const Text('Xem shop', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      // Related Products Section
                      RelatedProductsSection(
                        category: widget.product.category,
                        excludeProductId: widget.product.id,
                      ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: 'Thông tin'),
                      Tab(text: 'Đánh giá'),
                    ],
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            children: [
              // Product info tab
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Quick info cards
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoColumn(
                            Icons.inventory_2_outlined,
                            'Tình trạng',
                            widget.product.condition,
                          ),
                          _buildInfoColumn(
                            Icons.layers_outlined,
                            'Số lượng',
                            widget.product.quantity.toString(),
                          ),
                          _buildInfoColumn(
                            Icons.visibility_outlined,
                            'Lượt xem',
                            widget.product.viewCount.toString(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Description
                  const Text(
                    'Mô tả sản phẩm',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.product.description),
                  const SizedBox(height: 16),
                  // Tags
                  if (widget.product.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.product.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Related products - with minimal fixed height design
                  RelatedProductsSection(
                    category: widget.product.category,
                    excludeProductId: widget.product.id,
                  ),
                  // Add significant bottom padding to ensure no overflow
                  const SizedBox(height: 120),
                ],
              ),
              
              // Reviews tab
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  StreamBuilder<List<Review>>(
                    stream: Provider.of<ReviewService>(context).getReviewsByProductId(widget.product.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Lỗi: ${snapshot.error}'),
                        );
                      }

                      final reviews = snapshot.data ?? [];

                      if (reviews.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('Chưa có đánh giá nào'),
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Review summary
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        reviews.isNotEmpty
                                            ? (reviews.map((r) => r.rating).reduce((a, b) => a + b) /
                                                reviews.length)
                                                .toStringAsFixed(1)
                                            : '0.0',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: List.generate(5, (index) {
                                          final rating = reviews.isNotEmpty
                                              ? reviews.map((r) => r.rating).reduce((a, b) => a + b) /
                                                  reviews.length
                                              : 0.0;
                                          return Icon(
                                            index < rating ? Icons.star : Icons.star_border,
                                            color: Colors.amber,
                                            size: 16,
                                          );
                                        }),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${reviews.length} đánh giá',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Review list
                          ...reviews.map((review) => _buildReviewItem(review)).toList(),
                          const SizedBox(height: 16),
                          // Add review form
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Viết đánh giá',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Text('Đánh giá:'),
                                      const SizedBox(width: 8),
                                      ...List.generate(5, (index) {
                                        return IconButton(
                                          icon: Icon(
                                            index < _rating ? Icons.star : Icons.star_border,
                                            color: Colors.amber,
                                            size: 20,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            setState(() {
                                              _rating = index + 1.0;
                                            });
                                          },
                                        );
                                      }),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _reviewController,
                                    maxLines: 2,
                                    decoration: const InputDecoration(
                                      hintText: 'Nhập đánh giá của bạn...',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.all(12),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : () {},
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Text('Gửi đánh giá'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Add padding at the bottom
                          const SizedBox(height: 80),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 32), // Offset for the floating action button
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom > 0 
                        ? MediaQuery.of(context).padding.bottom 
                        : 8,
                  ),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () {
                                // TODO: Chat with seller
                              },
                              icon: const Icon(Icons.chat_bubble_outline, size: 16),
                              label: const Text('Nhắn tin', style: TextStyle(fontSize: 11)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                minimumSize: Size.zero,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _addToCart(context),
                              icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                              label: const Text('Thêm giỏ', style: TextStyle(fontSize: 11)),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                minimumSize: Size.zero,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showPurchaseDialog(context),
                              icon: const Icon(Icons.payment, size: 16),
                              label: const Text('Mua ngay', style: TextStyle(fontSize: 11)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                minimumSize: Size.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  Widget _buildImageGallery() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.product.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: widget.product.images[index],
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.product.images.asMap().entries.map((entry) {
              return Container(
                width: 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(
                    _currentImageIndex == entry.key ? 0.9 : 0.4,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoColumn(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
  
  Widget _buildReviewItem(Review review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  child: Icon(Icons.person, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userEmail,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy').format(review.createdAt),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 14,
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProductViewData() async {
    final productService = Provider.of<ProductService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Always increment view count
    await productService.incrementProductViewCount(widget.product.id);
    
    // Only add to recently viewed if user is logged in
    if (authService.currentUser != null) {
      await productService.addToRecentlyViewed(
        authService.currentUser!.uid,
        widget.product.id
      );
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
} 