import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_market_nttu/services/auth_service.dart';
import 'package:student_market_nttu/screens/product_list_screen.dart';
import 'package:student_market_nttu/screens/profile_screen.dart';
import 'package:student_market_nttu/screens/notification_screen.dart';
import 'package:student_market_nttu/screens/my_products_screen.dart';
import 'package:student_market_nttu/services/product_service.dart';
import 'package:student_market_nttu/models/product.dart';
import 'package:student_market_nttu/widgets/product_card_standard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_market_nttu/screens/search_screen.dart';
import 'package:student_market_nttu/screens/cart_screen.dart';
import 'package:student_market_nttu/widgets/cart_badge.dart';
import 'package:student_market_nttu/widgets/chatbot_button.dart';
import 'package:student_market_nttu/screens/chat_list_screen.dart';
import 'package:student_market_nttu/widgets/common_app_bar.dart';

import '../services/user_service.dart';
import '../services/cart_service.dart';
import '../widgets/app_drawer.dart';
import '../utils/location_utils.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  
  const HomeScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;

  final List<Widget> _screens = [
    const HomeContent(),
    const ProductListScreen(),
    const ChatListScreen(),
    const NotificationScreen(),
    const ProfileScreen(),
  ];

  final List<String> _bannerImages = [
    'assets/images/banner/banner1.jpg',
    'assets/images/banner/banner2.jpg',
    'assets/images/banner/banner3.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: const CommonAppBar(
        title: 'Student Market NTTU',
      ),
      drawer: const AppDrawer(),
      floatingActionButton: const ChatbotButton(),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue[900],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shop),
            label: 'Sản phẩm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Tin nhắn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Thông báo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  
  final List<String> _bannerImages = [
    'assets/images/banner/banner1.jpg',
    'assets/images/banner/banner2.jpg',
    'assets/images/banner/banner3.jpg',
  ];

  @override
  void initState() {
    super.initState();
    // Khởi tạo giỏ hàng khi màn hình được mở
    _initCartIfNeeded();
  }
  
  // Phương thức khởi tạo giỏ hàng
  void _initCartIfNeeded() {
    Future.microtask(() {
      final authService = Provider.of<AuthService>(context, listen: false);
      final cartService = Provider.of<CartService>(context, listen: false);
      
      // Nếu người dùng đã đăng nhập, tải giỏ hàng
      if (authService.currentUser != null) {
        cartService.fetchCartItems(authService.currentUser!.uid);
      }
    });
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh data
        setState(() {});
      },
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBannerSlider(),
            _buildRecommendedProducts(),
            _buildFeaturedShops(),
            _buildDonorRecognition(),
            _buildLatestProducts(),
            _buildNewArrivals(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerSlider() {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            PageView.builder(
              controller: _bannerController,
              onPageChanged: (index) {
                setState(() {
                  _currentBannerIndex = index;
                });
              },
              itemCount: _bannerImages.length,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue[800]!,
                        Colors.blue[400]!,
                      ],
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Nếu cần hiển thị ảnh banner thật sau này, có thể thêm code tại đây
                      Center(
                        child: Icon(
                          index == 0 
                            ? Icons.shopping_cart 
                            : index == 1 
                              ? Icons.book 
                              : Icons.school,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      Positioned(
                        bottom: 30,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16, 
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            index == 0 
                              ? 'Chợ sinh viên NTTU' 
                              : index == 1 
                                ? 'Sách và đồ dùng học tập'
                                : 'Trao đổi đồ miễn phí',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
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
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedProducts() {
    return FutureBuilder<List<Product>>(
      future: _getPersonalizedRecommendations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Text('Có lỗi xảy ra: ${snapshot.error}'),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Text('Không có sản phẩm đề xuất'),
            ),
          );
        } else {
          // Lấy dịch vụ product và auth
          final productService = Provider.of<ProductService>(context, listen: false);
          final authService = Provider.of<AuthService>(context, listen: false);

          // Tạo Future để lấy vị trí người dùng (nếu đăng nhập)
          late final Future<Map<String, double>?> userLocationFuture;
          if (authService.currentUser != null) {
            userLocationFuture = productService.getUserLocation(authService.currentUser!.uid);
          } else {
            userLocationFuture = Future.value(null);
          }

          return FutureBuilder<Map<String, double>?>(
            future: userLocationFuture,
            builder: (context, locationSnapshot) {
              // Lấy thông tin vị trí người dùng
              final userLocation = locationSnapshot.data;
              
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Đề xuất cho bạn',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigate to see all recommended products
                            },
                            child: Text(
                              'Xem tất cả',
                              style: TextStyle(
                                color: Colors.blue[900],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 280,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final product = snapshot.data![index];
                          return SizedBox(
                            width: 160,
                            child: ProductCardStandard(
                              product: product,
                              isCompact: true,
                              showDistance: userLocation != null,
                              userLocation: userLocation,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }
          );
        }
      },
    );
  }

  // Phương thức lấy sản phẩm đề xuất cá nhân hóa cho người dùng
  Future<List<Product>> _getPersonalizedRecommendations() async {
    final productService = Provider.of<ProductService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Nếu người dùng đã đăng nhập, lấy đề xuất dựa trên vị trí và hành vi
    if (authService.currentUser != null) {
      try {
        // Sử dụng phương thức mới để lấy đề xuất dựa trên vị trí hiện tại
        return productService.getRecommendedProductsWithCurrentLocation(
          authService.currentUser!.uid,
          limit: 10
        );
      } catch (e) {
        print('Lỗi khi lấy khuyến nghị nâng cao: $e');
        // Fallback về phương thức khuyến nghị thông thường
        return productService.getRecommendedProductsForUser(
          authService.currentUser!.uid,
          limit: 10,
        );
      }
    } else {
      // Nếu chưa đăng nhập, lấy đề xuất chung
      return productService.getRecommendedProducts(limit: 10);
    }
  }

  Widget _buildFeaturedShops() {
   
    // Dữ liệu mẫu cho Shop nổi bật
    final List<Map<String, dynamic>> featuredShops = [
      {
        'id': '1',
        'name': 'Shop Công Nghệ NTTU',
        'icon': Icons.computer,
        'iconColor': Colors.blue,
        'rating': 4.8,
        'productCount': 126,
      },
      {
        'id': '2',
        'name': 'Sách Cũ Sinh Viên',
        'icon': Icons.book,
        'iconColor': Colors.amber,
        'rating': 4.6,
        'productCount': 89,
      },
      {
        'id': '3',
        'name': 'Thời Trang NTTU',
        'icon': Icons.shopping_bag,
        'iconColor': Colors.pink,
        'rating': 4.5,
        'productCount': 154,
      },
      {
        'id': '4',
        'name': 'Đồ Cũ Ký Túc',
        'icon': Icons.home,
        'iconColor': Colors.green,
        'rating': 4.3,
        'productCount': 72,
      },
      {
        'id': '5',
        'name': 'Trang Sức Handmade',
        'icon': Icons.diamond,
        'iconColor': Colors.purple,
        'rating': 4.7,
        'productCount': 63,
      },
    ];
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Shop nổi bật',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to see all featured shops
                  },
                  child: Text(
                    'Xem tất cả',
                    style: TextStyle(
                      color: Colors.blue[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: featuredShops.length,
                itemBuilder: (context, index) {
                  final shop = featuredShops[index];
                  return Container(
                    width: 110,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: shop['iconColor'],
                          child: Icon(
                            shop['icon'],
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          shop['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              '${shop['rating']}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${shop['productCount']} sản phẩm',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonorRecognition() {   
    // Dữ liệu mẫu người tặng đồ
    final List<Map<String, dynamic>> topDonors = [
      {
        'id': '1',
        'name': 'Nguyễn Văn An',
        'icon': Icons.person,
        'iconColor': Colors.blue,
        'donationCount': 24,
        'faculty': 'Công nghệ thông tin',
      },
      {
        'id': '2',
        'name': 'Trần Thị Bình',
        'icon': Icons.person,
        'iconColor': Colors.pink,
        'donationCount': 19,
        'faculty': 'Quản trị kinh doanh',
      },
      {
        'id': '3',
        'name': 'Lê Hoàng Dũng',
        'icon': Icons.person,
        'iconColor': Colors.green,
        'donationCount': 17,
        'faculty': 'Kỹ thuật điện tử',
      },
      {
        'id': '4',
        'name': 'Phạm Minh Châu',
        'icon': Icons.person,
        'iconColor': Colors.orange,
        'donationCount': 15,
        'faculty': 'Marketing',
      },
      {
        'id': '5',
        'name': 'Võ Hoài Nam',
        'icon': Icons.person,
        'iconColor': Colors.purple,
        'donationCount': 12,
        'faculty': 'Kiến trúc',
      },
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Vinh danh người tặng đồ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to see all donors
                  },
                  child: Text(
                    'Xem tất cả',
                    style: TextStyle(
                      color: Colors.blue[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: topDonors.length,
                itemBuilder: (context, index) {
                  final donor = topDonors[index];
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: donor['iconColor'],
                              child: Icon(
                                donor['icon'],
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            if (index < 3)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: index == 0 
                                      ? Colors.amber 
                                      : index == 1 
                                        ? Colors.grey[400] 
                                        : Colors.brown[300],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          donor['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          donor['faculty'],
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Tặng ${donor['donationCount']} món',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestProducts() {
    return FutureBuilder<List<Product>>(
      future: Provider.of<ProductService>(context, listen: false).getLatestProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Text('Có lỗi xảy ra: ${snapshot.error}'),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Text('Không có sản phẩm mới nhất'),
            ),
          );
        } else {
          // Lấy dịch vụ auth và product
          final authService = Provider.of<AuthService>(context, listen: false);
          final productService = Provider.of<ProductService>(context, listen: false);
          
          // Tạo Future để lấy vị trí người dùng (nếu đăng nhập)
          late final Future<Map<String, double>?> userLocationFuture;
          if (authService.currentUser != null) {
            userLocationFuture = productService.getUserLocation(authService.currentUser!.uid);
          } else {
            userLocationFuture = Future.value(null);
          }
          
          return FutureBuilder<Map<String, double>?>(
            future: userLocationFuture,
            builder: (context, locationSnapshot) {
              // Lấy thông tin vị trí người dùng
              final userLocation = locationSnapshot.data;
              
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Sản phẩm mới nhất',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigate to see all latest products
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProductListScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Xem tất cả',
                              style: TextStyle(
                                color: Colors.blue[900],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 280,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final product = snapshot.data![index];
                          return SizedBox(
                            width: 160,
                            child: ProductCardStandard(
                              product: product,
                              isCompact: true,
                              showDistance: userLocation != null,
                              userLocation: userLocation,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }
          );
        }
      },
    );
  }

  Widget _buildNewArrivals() {
    return FutureBuilder<List<Product>>(
      future: Provider.of<ProductService>(context, listen: false).getNewArrivals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Text('Có lỗi xảy ra: ${snapshot.error}'),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Text('Không có sản phẩm mới'),
            ),
          );
        } else {
          // Lấy dịch vụ auth và product
          final authService = Provider.of<AuthService>(context, listen: false);
          final productService = Provider.of<ProductService>(context, listen: false);
          
          // Tạo Future để lấy vị trí người dùng (nếu đăng nhập)
          late final Future<Map<String, double>?> userLocationFuture;
          if (authService.currentUser != null) {
            userLocationFuture = productService.getUserLocation(authService.currentUser!.uid);
          } else {
            userLocationFuture = Future.value(null);
          }
          
          return FutureBuilder<Map<String, double>?>(
            future: userLocationFuture,
            builder: (context, locationSnapshot) {
              // Lấy thông tin vị trí người dùng
              final userLocation = locationSnapshot.data;
              
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Sản phẩm mới',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigate to see all new products
                            },
                            child: Text(
                              'Xem tất cả',
                              style: TextStyle(
                                color: Colors.blue[900],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 280,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final product = snapshot.data![index];
                          return SizedBox(
                            width: 160,
                            child: ProductCardStandard(
                              product: product,
                              isCompact: true,
                              showDistance: userLocation != null,
                              userLocation: userLocation,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }
          );
        }
      },
    );
  }
} 