import 'package:flutter/material.dart' hide CarouselController;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geolocator/geolocator.dart';
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
import '../utils/location_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/chat_service.dart';
import '../services/notification_service.dart';
import '../services/location_service.dart';

class ProductDetailScreen extends StatefulWidget {
  static const routeName = '/product-detail';
  
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
  late Future<List<Review>> _productReviews;
  late Future<dynamic> _sellerInfoFuture;
  
  // Biến vị trí người dùng và khoảng cách đến sản phẩm
  Map<String, double>? _userLocation;
  double? _distanceToProduct;
  late Future<Map<String, double>?> _userLocationFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);
    
    // Đảm bảo _isLoading luôn là false khi khởi tạo
    setState(() => _isLoading = false);
    
    // Khởi tạo Future để tải dữ liệu đánh giá sản phẩm
    _productReviews = _getProductReviews();
    
    // Khởi tạo Future để tải thông tin người bán
    _sellerInfoFuture = Provider.of<UserService>(context, listen: false)
        .getUserById(widget.product.sellerId);
    
    // Khởi tạo Future để lấy vị trí người dùng
    _userLocationFuture = _getCurrentLocation();
    
    // Đảm bảo gọi sau khi widget đã được build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateProductViewData();
    });
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

  // Phương thức lấy vị trí hiện tại của người dùng
  Future<Map<String, double>?> _getCurrentLocation() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Kiểm tra nếu người dùng đã đăng nhập
      if (authService.currentUser != null) {
        final productService = Provider.of<ProductService>(context, listen: false);
        final savedLocation = await productService.getUserLocation(authService.currentUser!.uid);
        
        // Nếu đã có vị trí lưu trữ, kiểm tra xem vị trí có quá cũ không (>30 phút)
        if (savedLocation != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(authService.currentUser!.uid)
              .get();
              
          if (userDoc.exists && userDoc.data()!.containsKey('currentLocation')) {
            final locationData = userDoc.data()!['currentLocation'];
            if (locationData.containsKey('updatedAt') && locationData['updatedAt'] != null) {
              final updateTime = (locationData['updatedAt'] as Timestamp).toDate();
              final timeDiff = DateTime.now().difference(updateTime).inMinutes;
              
              // Nếu vị trí còn mới (< 30 phút), sử dụng vị trí đã lưu
              if (timeDiff <= 30) {
                print('🕒 Sử dụng vị trí đã lưu (${timeDiff} phút trước): ${savedLocation['lat']}, ${savedLocation['lng']}');
                // Tính khoảng cách đến sản phẩm - đã chuyển thành phương thức bất đồng bộ
                if (widget.product.location != null) {
                  await _calculateDistanceToProduct(savedLocation);
                }
                return savedLocation;
              }
            }
          }
        }
      }
      
      // Nếu không có vị trí lưu trữ hoặc vị trí quá cũ, lấy vị trí hiện tại
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Người dùng từ chối quyền truy cập vị trí');
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        print('❌ Người dùng đã từ chối vĩnh viễn quyền truy cập vị trí');
        return null;
      }
      
      print('📱 Đang lấy vị trí hiện tại...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      print('📍 Đã lấy được vị trí: ${position.latitude}, ${position.longitude}');
      final currentLocation = {
        'lat': position.latitude,
        'lng': position.longitude,
      };
      
      // Lưu vị trí hiện tại vào Firestore nếu người dùng đã đăng nhập
      if (authService.currentUser != null) {
        final productService = Provider.of<ProductService>(context, listen: false);
        
        print('💾 Đang lưu vị trí vào Firestore...');
        bool updateSuccess = await productService.updateUserLocation(
          authService.currentUser!.uid, 
          currentLocation
        );
        
        if (updateSuccess) {
          print('✅ Đã lưu vị trí thành công');
          
          // Xác minh vị trí đã lưu
          final verifiedLocation = await productService.getUserLocation(authService.currentUser!.uid);
          if (verifiedLocation != null) {
            print('🔍 Kiểm tra vị trí từ Firestore: ${verifiedLocation['lat']}, ${verifiedLocation['lng']}');
          } else {
            print('⚠️ Không thể xác minh vị trí đã lưu');
          }
        } else {
          print('❌ Không thể lưu vị trí vào Firestore');
        }
      }
      
      // Tính khoảng cách đến sản phẩm - đã chuyển thành phương thức bất đồng bộ
      if (widget.product.location != null) {
        await _calculateDistanceToProduct(currentLocation);
      }
      
      return currentLocation;
    } catch (e) {
      print('❌ Lỗi khi lấy vị trí hiện tại: $e');
      return null;
    }
  }
  
  // Phương thức tính khoảng cách đến sản phẩm
  Future<void> _calculateDistanceToProduct(Map<String, double> userLocation) async {
    if (widget.product.location == null) return;
    
    try {
      // Lấy vị trí sản phẩm từ Firestore dựa trên địa chỉ
      final productLocation = await LocationUtils.getLocationFromAddressAsync(widget.product.location);
      
      if (productLocation == null) {
        print('❌ Không thể xác định vị trí cho sản phẩm: ${widget.product.title}');
        setState(() {
          _distanceToProduct = null; // Đặt lại khoảng cách thành null khi không thể xác định vị trí
        });
        return;
      }
      
      final productLat = productLocation['lat'];
      final productLng = productLocation['lng'];
      
      if (productLat == null || productLng == null) {
        print('❌ Vị trí sản phẩm không hợp lệ');
        setState(() {
          _distanceToProduct = null;
        });
        return;
      }
      
      print('📍 Vị trí sản phẩm: $productLat, $productLng');
      print('📍 Vị trí người dùng: ${userLocation['lat']}, ${userLocation['lng']}');
      
      final distance = LocationUtils.calculateDistance(
        userLocation['lat']!,
        userLocation['lng']!,
        productLat,
        productLng,
      );
      
      print('📏 Khoảng cách tính toán: ${distance.toStringAsFixed(2)} km');
      
      setState(() {
        _distanceToProduct = distance;
      });
    } catch (e) {
      print('❌ Lỗi khi tính khoảng cách đến sản phẩm: $e');
      setState(() {
        _distanceToProduct = null;
      });
    }
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
    FocusScope.of(context).unfocus();

    if (_reviewController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đánh giá')),
      );
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

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
        images: null,
        likes: [],
        comments: [],
      );
      
      await Provider.of<ReviewService>(context, listen: false).addReview(review);

      if (!mounted) return;

      // Tải lại dữ liệu đánh giá sau khi thêm thành công
      setState(() {
        _productReviews = _getProductReviews();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đánh giá thành công')),
      );

      _reviewController.clear();
      setState(() => _rating = 5.0);
    } catch (e) {
      print("Error submitting review: $e");
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
                      _buildSellerInfo(),
                      const SizedBox(height: 24),
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
                  
                  // Hiển thị khoảng cách
                  FutureBuilder<Map<String, double>?>(
                    future: _userLocationFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      } else if (snapshot.hasData && _distanceToProduct != null) {
                        return Card(
                          margin: const EdgeInsets.only(top: 16),
                          child: InkWell(
                            onTap: _openProductLocation,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Khoảng cách',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _distanceToProduct! < 1
                                                  ? 'Cách vị trí hiện tại của bạn ${(_distanceToProduct! * 1000).toStringAsFixed(0)} mét'
                                                  : 'Cách vị trí hiện tại của bạn ${_distanceToProduct!.toStringAsFixed(1)} km',
                                            ),
                                            if (widget.product.location != null && 
                                                widget.product.location!.containsKey('address')) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'Địa chỉ: ${widget.product.location!['address']}',
                                                style: const TextStyle(color: Colors.grey),
                                              ),
                                            ],
                                            const SizedBox(height: 2),
                                            const Text(
                                              'Nhấn để xem trên bản đồ',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.blue,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.directions, color: Colors.blue)
                                    ],
                                  ),
                                  
                                  // Chỉ hiển thị nút này cho admin hoặc người phát triển
                                  FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(FirebaseAuth.instance.currentUser?.uid)
                                        .get(),
                                    builder: (context, snapshot) {
                                      // Kiểm tra nếu là admin hoặc developer mới hiển thị nút này
                                      if (snapshot.hasData && 
                                          snapshot.data != null && 
                                          snapshot.data!.exists) {
                                        final userData = snapshot.data!.data() as Map<String, dynamic>?;
                                        final userRole = userData?['role'] as String? ?? 'user';
                                        
                                        if (userRole == 'admin' || userRole == 'developer') {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                TextButton.icon(
                                                  onPressed: _updateLocationDatabase,
                                                  icon: const Icon(Icons.add_location_alt, size: 16),
                                                  label: const Text('Thêm vào location database', style: TextStyle(fontSize: 12)),
                                                ),
                                                const SizedBox(width: 8),
                                                TextButton.icon(
                                                  onPressed: _debugRecommendations,
                                                  icon: const Icon(Icons.bug_report, size: 16),
                                                  label: const Text('Debug đề xuất', style: TextStyle(fontSize: 12)),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
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
              _buildReviewsTab(),
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
                              onPressed: () => _chatWithSeller(context),
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
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person, size: 18, color: Colors.white),
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
            if (review.likes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.thumb_up, size: 14, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      '${review.likes.length} người thích',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsTab() {
    return FutureBuilder<List<Review>>(
      future: _productReviews,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Đã xảy ra lỗi khi tải đánh giá: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _productReviews = _getProductReviews();
                    });
                  },
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        final reviews = snapshot.data ?? [];
        
        // Mặc định 0 sao nếu không có đánh giá
        double averageRating = 0.0;
        if (reviews.isNotEmpty) {
          averageRating = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
        }
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Card hiển thị thông tin đánh giá
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          reviews.isNotEmpty 
                            ? averageRating.toStringAsFixed(1)
                            : "0.0",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              (reviews.isNotEmpty && index < averageRating) ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reviews.isEmpty 
                            ? 'Chưa có đánh giá'
                            : '${reviews.length} đánh giá',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Danh sách đánh giá
            if (reviews.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'Chưa có đánh giá nào cho sản phẩm này.\nHãy là người đầu tiên đánh giá!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...reviews.map((review) => _buildReviewItem(review)).toList(),
            
            const SizedBox(height: 16),
            // Form thêm đánh giá
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
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(5, (index) {
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _rating = index + 1.0;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Icon(
                                      index < _rating ? Icons.star : Icons.star_border,
                                      color: Colors.amber,
                                      size: 24,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _reviewController,
                      maxLines: 3,
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
                        onPressed: _isLoading ? null : _submitReview,
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
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Future<List<Review>> _getProductReviews() async {
    try {
      final reviewService = Provider.of<ReviewService>(context, listen: false);
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('productId', isEqualTo: widget.product.id)
          .orderBy('createdAt', descending: true)
          .get();
      
      return reviewsSnapshot.docs
          .map((doc) => Review.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Lỗi khi tải đánh giá: $e');
      return [];
    }
  }

  Widget _buildSellerInfo() {
    return FutureBuilder<dynamic>(
      future: _sellerInfoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Không thể tải thông tin người bán'),
            ),
          );
        }

        final sellerData = snapshot.data;
        final sellerName = sellerData?.displayName ?? 'Người bán';
        
        // Lấy thông tin địa chỉ từ location của người bán
        String sellerAddress = 'Không có địa chỉ';
        final location = widget.product.location;
        
        if (location != null && location.containsKey('address')) {
          sellerAddress = location['address'].toString();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: sellerData?.photoURL != null && sellerData.photoURL.isNotEmpty
                      ? NetworkImage(sellerData.photoURL)
                      : null,
                  child: sellerData?.photoURL == null || sellerData.photoURL.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          sellerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              sellerAddress,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfilePage(
                          userId: widget.product.sellerId,
                          username: sellerName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.store, size: 16),
                  label: const Text('Xem shop', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateProductViewData() async {
    try {
      final productService = Provider.of<ProductService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Lưu view count vào Firestore
      await productService.incrementProductViewCount(widget.product.id);
      
      // Chỉ lưu vào lịch sử xem nếu user đã đăng nhập
      if (authService.currentUser != null) {
        // Lấy vị trí hiện tại từ _userLocationFuture
        Map<String, double>? currentLocation = await _userLocationFuture;
        
        // Nếu không có vị trí, không gửi thông tin vị trí
        if (currentLocation != null) {
          // Sử dụng phương thức trackProductView để lưu cả lịch sử xem và vị trí
          await productService.trackProductView(
            authService.currentUser!.uid,
            widget.product.id,
            currentLocation,
          );
        } else {
          // Chỉ lưu lịch sử xem mà không có vị trí
          await productService.trackProductView(
            authService.currentUser!.uid,
            widget.product.id,
            null,
          );
        }
      }
    } catch (e) {
      print('Error updating product view data: $e');
      // Không hiển thị lỗi cho người dùng vì đây là thao tác ngầm
    }
  }

  Future<void> _chatWithSeller(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (authService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để nhắn tin với người bán')),
      );
      return;
    }

    if (authService.currentUser!.uid == widget.product.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đây là sản phẩm của bạn')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);
      
      // Lấy thông tin người dùng hiện tại và người bán
      final userService = Provider.of<UserService>(context, listen: false);
      final currentUser = await userService.getUserById(authService.currentUser!.uid);
      final seller = await userService.getUserById(widget.product.sellerId);
      
      // Tạo đoạn chat mới hoặc lấy đoạn chat hiện có
      final chatService = Provider.of<ChatService>(context, listen: false);
      final chatId = await chatService.createOrGetChat(widget.product.sellerId);
      
      if (!mounted) return;
      
      // Điều hướng đến màn hình chat
      Navigator.pushNamed(
        context,
        '/chat-detail',
        arguments: {
          'chatId': chatId,
          'otherUser': seller,
        },
      );
      
      // Tạo tin nhắn về sản phẩm
      final message = 'Tôi quan tâm đến sản phẩm: ${widget.product.title} (${NumberFormat('#,###').format(widget.product.price)} đ)';
      await chatService.sendTextMessage(chatId, message, context: context);
      
      // Gửi thông báo đặc biệt cho người bán về việc có người hỏi sản phẩm
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      await notificationService.createChatProductNotification(
        userId: widget.product.sellerId,
        chatId: chatId,
        senderId: authService.currentUser!.uid,
        senderName: currentUser?.displayName ?? 'Người mua',
        productId: widget.product.id,
        productTitle: widget.product.title,
        message: message,
      );
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Phương thức mở vị trí sản phẩm trên bản đồ
  Future<void> _openProductLocation() async {
    try {
      final productLocation = await LocationUtils.getLocationFromAddressAsync(widget.product.location);
      
      if (productLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể xác định vị trí sản phẩm')),
        );
        return;
      }
      
      final lat = productLocation['lat'];
      final lng = productLocation['lng'];
      
      // Tạo URL Google Maps
      final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
      
      // Mở URL
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở bản đồ')),
        );
      }
    } catch (e) {
      print('❌ Lỗi khi mở vị trí sản phẩm: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Có lỗi xảy ra khi mở bản đồ')),
      );
    }
  }

  // Phương thức thêm địa chỉ sản phẩm vào database locations
  Future<void> _updateLocationDatabase() async {
    try {
      if (widget.product.location == null || 
          !widget.product.location!.containsKey('address') ||
          widget.product.location!['address'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sản phẩm không có thông tin địa chỉ')),
        );
        return;
      }
      
      // Lấy service
      final locationService = Provider.of<LocationService>(context, listen: false);
      
      // Thêm địa chỉ vào collection locations
      String address = widget.product.location!['address'].toString();
      
      // Kiểm tra xem địa chỉ đã tồn tại trong collection chưa
      final querySnapshot = await FirebaseFirestore.instance
          .collection('locations')
          .where('address', isEqualTo: address)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Địa chỉ đã tồn tại trong database')),
        );
        return;
      }
      
      // Kiểm tra và trích xuất quận từ địa chỉ
      String district = 'Không xác định';
      final districtPattern = RegExp(r'Q\.\s*(\d+|[^,]+)');
      final match = districtPattern.firstMatch(address);
      if (match != null) {
        district = 'Quận ${match.group(1)}';
      }
      
      // Nếu là địa chỉ 300A Nguyễn Tất Thành, sử dụng phương thức đặc biệt
      if (address.contains('300A') && address.contains('Nguyễn Tất Thành')) {
        final location = await locationService.addNguyenTatThanhLocation();
        if (location != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã thêm địa chỉ 300A Nguyễn Tất Thành vào database')),
          );
        }
      } else {
        // Tạo vị trí mới cho địa chỉ khác
        final location = await locationService.createLocation(
          district: district,
          name: address.split(',').first,
          address: address,
          isActive: true,
        );
        
        if (location != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã thêm địa chỉ "$address" vào database')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể thêm địa chỉ vào database')),
          );
        }
      }
    } catch (e) {
      print('❌ Lỗi khi cập nhật database địa chỉ: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  // Phương thức debug đề xuất sản phẩm
  Future<void> _debugRecommendations() async {
    try {
      // Hiển thị dialog đang tải
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang phân tích thuật toán đề xuất...'),
            ],
          ),
        ),
      );
      
      final authService = Provider.of<AuthService>(context, listen: false);
      final productService = Provider.of<ProductService>(context, listen: false);
      
      // Kiểm tra người dùng đã đăng nhập chưa
      if (authService.currentUser == null) {
        Navigator.of(context).pop(); // Đóng dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập để sử dụng tính năng này')),
        );
        return;
      }
      
      // Lấy vị trí người dùng
      Map<String, double>? userLocation = await _getCurrentLocation();
      
      if (userLocation == null) {
        userLocation = {'lat': 10.7326, 'lng': 106.6975}; // Vị trí mặc định
      }
      
      // Lấy danh sách đề xuất với verbose=true để log chi tiết
      await productService.getRecommendedProductsWithLocation(
        userId: authService.currentUser!.uid,
        userLocation: userLocation,
        limit: 10,
        verbose: true,
      );
      
      // Đóng dialog
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thông tin phân tích đã được hiển thị trong console'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      // Đóng dialog nếu có lỗi
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
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

class RelatedProductsSection extends StatelessWidget {
  final String category;
  final String excludeProductId;
  
  const RelatedProductsSection({
    super.key, 
    required this.category, 
    required this.excludeProductId
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sản phẩm tương tự',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProductListScreen(),
                    ),
                  );
                },
                child: const Text('Xem tất cả'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: StreamBuilder<List<Product>>(
            stream: Provider.of<ProductService>(context).getProductsByCategory(category),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Đã xảy ra lỗi: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                );
              }

              final products = snapshot.data ?? [];
              
              // Lọc bỏ sản phẩm hiện tại
              final filteredProducts = products
                  .where((product) => product.id != excludeProductId)
                  .toList();

              if (filteredProducts.isEmpty) {
                return const Center(
                  child: Text(
                    'Không tìm thấy sản phẩm tương tự',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              // Giới hạn hiển thị tối đa 5 sản phẩm
              final displayProducts = filteredProducts.take(5).toList();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: displayProducts.length,
                itemBuilder: (context, index) {
                  final product = displayProducts[index];
                  return Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 10),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(
                                product: product,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 120,
                              width: double.infinity,
                              child: product.images.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: product.images.first,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                    )
                                  : Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image_not_supported),
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    NumberFormat.currency(
                                      locale: 'vi_VN',
                                      symbol: 'đ',
                                    ).format(product.price),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
} 