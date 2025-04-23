import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:student_market_nttu/services/auth_service.dart';
import 'package:student_market_nttu/screens/product_list_screen.dart';
import 'package:student_market_nttu/screens/profile_screen.dart';
import 'package:student_market_nttu/screens/chat_list_screen.dart';
import 'package:student_market_nttu/screens/notification_screen.dart';
import 'package:student_market_nttu/screens/my_products_screen.dart';
import 'package:student_market_nttu/services/product_service.dart';
import 'package:student_market_nttu/models/product.dart';
import 'package:student_market_nttu/widgets/product_card_standard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:student_market_nttu/screens/search_screen.dart';
import 'package:student_market_nttu/screens/cart_screen.dart';
import 'package:student_market_nttu/widgets/cart_badge.dart';

import '../services/user_service.dart';
import '../services/cart_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
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
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Student Market NTTU'),
        backgroundColor: Colors.blue[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Navigate to search
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
              const SizedBox(height: 16),
            ],
          ),
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
                return CachedNetworkImage(
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
      ),
    );
  }

  Widget _buildRecommendedProducts() {
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
                  'Sản phẩm đề xuất',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to see all
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
            const SizedBox(height: 16),
            SizedBox(
              height: 350,
              child: FutureBuilder<List<Product>>(
                future: _getPersonalizedRecommendations(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Không có sản phẩm đề xuất'));
                  }
                  
                  final products = snapshot.data!;
                  
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 180,
                        margin: const EdgeInsets.only(right: 12),
                        child: ProductCardStandard(
                          product: products[index],
                          isCompact: false,
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
    );
  }

  // Phương thức lấy sản phẩm đề xuất cá nhân hóa cho người dùng
  Future<List<Product>> _getPersonalizedRecommendations() async {
    final productService = Provider.of<ProductService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Nếu người dùng đã đăng nhập, lấy đề xuất dựa trên hành vi của họ
    if (authService.currentUser != null) {
      return productService.getRecommendedProductsForUser(
        authService.currentUser!.uid,
        limit: 10,
      );
    } else {
      // Nếu chưa đăng nhập, lấy đề xuất chung
      return productService.getRecommendedProducts(limit: 10);
    }
  }

  Widget _buildFeaturedShops() {
    // This would be replaced with actual data from a service
    final List<Map<String, dynamic>> featuredShops = [
      {
        'name': 'Shop NTTU Books',
        'avatar': 'https://firebasestorage.googleapis.com/v0/b/student-market-nttu.appspot.com/o/avatars%2Fshop1.jpg?alt=media',
        'rating': 4.8,
        'productCount': 56,
      },
      {
        'name': 'Điện tử sinh viên',
        'avatar': 'https://firebasestorage.googleapis.com/v0/b/student-market-nttu.appspot.com/o/avatars%2Fshop2.jpg?alt=media',
        'rating': 4.5,
        'productCount': 42,
      },
      {
        'name': 'Second Hand NTTU',
        'avatar': 'https://firebasestorage.googleapis.com/v0/b/student-market-nttu.appspot.com/o/avatars%2Fshop3.jpg?alt=media',
        'rating': 4.6,
        'productCount': 78,
      },
      {
        'name': 'Thời trang sinh viên',
        'avatar': 'https://firebasestorage.googleapis.com/v0/b/student-market-nttu.appspot.com/o/avatars%2Fshop4.jpg?alt=media',
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
                          backgroundImage: CachedNetworkImageProvider(
                            shop['avatar'],
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
    // This would be replaced with actual data from a service
    final List<Map<String, dynamic>> topDonors = [
      {
        'name': 'Nguyễn Văn A',
        'avatar': 'https://firebasestorage.googleapis.com/v0/b/student-market-nttu.appspot.com/o/avatars%2Fdonor1.jpg?alt=media',
        'donationCount': 15,
      },
      {
        'name': 'Trần Thị B',
        'avatar': 'https://firebasestorage.googleapis.com/v0/b/student-market-nttu.appspot.com/o/avatars%2Fdonor2.jpg?alt=media',
        'donationCount': 12,
      },
      {
        'name': 'Lê Văn C',
        'avatar': 'https://firebasestorage.googleapis.com/v0/b/student-market-nttu.appspot.com/o/avatars%2Fdonor3.jpg?alt=media',
        'donationCount': 10,
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
              height: 120,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: Provider.of<UserService>(context, listen: false).getTopCreditGainersThisWeek(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Không có dữ liệu'));
                  }

                  final donors = snapshot.data!;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: donors.asMap().entries.map((entry) {
                      final index = entry.key;
                      final donor = entry.value;

                      // Different styles for top 3 donors
                      final List<Color> medalColors = [
                        Colors.amber[700]!, // Gold
                        Colors.grey[400]!, // Silver
                        Colors.brown[300]!, // Bronze
                      ];

                      final List<String> medals = ['🥇', '🥈', '🥉'];

                      return Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 35,
                                backgroundImage: CachedNetworkImageProvider(
                                  donor['avatar'] != ''
                                      ? donor['avatar']
                                      : 'https://via.placeholder.com/80',
                                ),
                                backgroundColor: Colors.grey[200],
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: medalColors[index],
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: Text(
                                    medals[index],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            donor['name'] != '' ? donor['name'] : 'Người dùng',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '+${donor['creditGain']} điểm uy tín',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
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
                      // Navigate to all products
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductListScreen(),
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
            const SizedBox(height: 16),
            StreamBuilder<List<Product>>(
              stream: Provider.of<ProductService>(context).searchProductsAdvanced(
                sortBy: 'Mới nhất',
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Không có sản phẩm nào'),
                  );
                }

                final products = snapshot.data!.take(4).toList();

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
                    return ProductCardStandard(
                      product: products[index],
                      showFavoriteButton: true,
                      isCompact: false,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 