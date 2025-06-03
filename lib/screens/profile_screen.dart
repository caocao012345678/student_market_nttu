import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_market_nttu/services/auth_service.dart';
import 'package:student_market_nttu/services/user_service.dart';
import 'package:student_market_nttu/screens/login_screen.dart';
import 'package:student_market_nttu/screens/settings_screen.dart';
import 'package:student_market_nttu/screens/my_products_screen.dart';
import 'package:student_market_nttu/screens/add_product_screen.dart';
import 'package:student_market_nttu/screens/edit_profile_screen.dart';
import 'package:student_market_nttu/screens/favorite_products_screen.dart';
import 'package:student_market_nttu/screens/order_history_screen.dart';
import 'package:student_market_nttu/screens/user_profile_page.dart';
import 'package:student_market_nttu/screens/register_shipper_screen.dart';
import 'package:student_market_nttu/screens/user_survey_screen.dart';
import 'package:student_market_nttu/screens/moderation_history_screen.dart';
import 'package:student_market_nttu/screens/change_password_screen.dart';
import 'package:student_market_nttu/screens/notification_screen.dart';
import 'package:student_market_nttu/services/theme_service.dart';
import 'package:student_market_nttu/widgets/app_drawer.dart';
import 'package:student_market_nttu/widgets/common_app_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  // Bỏ TabController, không cần nữa
  
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showShipperRegistrationDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterShipperScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final isLoggedIn = user != null;

    // Hiển thị màn hình đăng nhập nếu người dùng chưa đăng nhập
    if (!isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tài khoản'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_circle,
                size: 100,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              const Text(
                'Vui lòng đăng nhập để xem thông tin cá nhân',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Đăng nhập'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<UserModel?>(
      // Chỉ tải dữ liệu khi đã đăng nhập
      future: Provider.of<UserService>(context, listen: false).getUserById(user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data == null) {
          return const CircularProgressIndicator();
        }

        final userModel = snapshot.data;
        final themeService = Provider.of<ThemeService>(context);
        final isDarkMode = themeService.isDarkMode;

        return Scaffold(
          drawer: const AppDrawer(),
          body: _buildProfileContent(userModel!),
        );
      },
    );
  }

  Widget _buildProfileContent(UserModel userModel) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;
    
    return ListView(
      children: [
        const SizedBox(height: 20),
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: userModel.photoURL.isNotEmpty
                    ? NetworkImage(userModel.photoURL)
                    : null,
                backgroundColor: Colors.grey[300],
                child: userModel.photoURL.isEmpty != false
                    ? const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.grey,
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            userModel.displayName.isNotEmpty
                ? userModel.displayName
                : user?.email ?? 'Không có tên',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Center(
          child: Text(
            user?.email ?? 'Không có email',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        if (userModel.phoneNumber.isNotEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                userModel.phoneNumber,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
        // Student information display
        if (userModel.isStudent) ...[
          const SizedBox(height: 10),
          Center(
            child: Chip(
              label: const Text('Sinh viên NTTU'),
              backgroundColor: Colors.blue.shade100,
              labelStyle: TextStyle(color: Colors.blue.shade800),
              avatar: const Icon(Icons.school, size: 16, color: Colors.blue),
            ),
          ),
          const SizedBox(height: 4),
          if (userModel.studentId?.isNotEmpty == true)
            Center(
              child: Text(
                'MSSV: ${userModel.studentId}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          if (userModel.department?.isNotEmpty == true)
            Center(
              child: Text(
                'Khoa: ${userModel.department}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
        const SizedBox(height: 20),
        // Credit and points information
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .snapshots(),
                builder: (context, snapshot) {
                  int nttPoint = 0;
                  if (snapshot.hasData && snapshot.data != null) {
                    nttPoint = snapshot.data!.get('nttPoint') ?? 0;
                  } else {
                    nttPoint = userModel.nttPoint ?? 0;
                  }
                  return _buildStatCard(
                    context, 
                    'NTT Point', 
                    '$nttPoint',
                    Icons.monetization_on,
                    Colors.amber
                  );
                },
              ),
              _buildStatCard(
                context, 
                'NTT Credit', 
                '${userModel.nttCredit ?? 0}',
                Icons.credit_score,
                Colors.green
              ),
            ],
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.shopping_bag),
          title: const Text('Cửa hàng của tôi'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => UserProfilePage(
                  userId: user?.uid ?? '',
                  username: userModel.displayName.isNotEmpty
                      ? userModel.displayName
                      : 'Cửa hàng của tôi',
                ),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.inventory_2),
          title: const Text('Sản phẩm của tôi'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const MyProductsScreen(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.favorite),
          title: const Text('Sản phẩm yêu thích'),
          trailing: Text(
            userModel.favoriteProducts.length.toString(),
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const FavoriteProductsScreen(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.local_shipping),
          title: const Text('Đăng ký làm shipper'),
          trailing: userModel.isShipper == true
              ? const Chip(
                  label: Text('Đã đăng ký'),
                  backgroundColor: Colors.green,
                  labelStyle: TextStyle(color: Colors.white),
                )
              : null,
          onTap: () {
            if (userModel.isShipper != true) {
              _showShipperRegistrationDialog(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bạn đã đăng ký làm shipper'),
                ),
              );
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('Lịch sử giao dịch'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const OrderHistoryScreen(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.fact_check),
          title: const Text('Lịch sử kiểm duyệt sản phẩm'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ModerationHistoryScreen(),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.interests),
          title: const Text('Khảo sát sở thích'),
          subtitle: Text(
            userModel.completedSurvey == true 
                ? 'Đã hoàn thành' 
                : 'Chưa hoàn thành'
          ),
          trailing: userModel.completedSurvey == true
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => UserSurveyScreen(fromProfile: true),
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text(
            'Đăng xuất',
            style: TextStyle(color: Colors.red),
          ),
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Xác nhận đăng xuất'),
                content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Hủy'),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Đăng xuất'),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              try {
                final authService = Provider.of<AuthService>(context, listen: false);
                await authService.signOut();
                if (!context.mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 40, color: color),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (title == 'NTT Credit')
          Consumer<UserService>(
            builder: (context, userService, child) {
              final user = userService.currentUser;
              return Text(
                user?.getCreditRating() ?? '',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic
                ),
              );
            }
          ),
      ],
    );
  }
} 