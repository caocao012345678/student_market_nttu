import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_market_nttu/services/auth_service.dart';
import 'package:student_market_nttu/services/theme_service.dart';
import 'package:student_market_nttu/screens/home_screen.dart';
import 'package:student_market_nttu/screens/profile_screen.dart';
import 'package:student_market_nttu/screens/settings_screen.dart';
import 'package:student_market_nttu/screens/my_products_screen.dart';
import 'package:student_market_nttu/screens/order_history_screen.dart';
import 'package:student_market_nttu/screens/favorite_products_screen.dart';
import 'package:student_market_nttu/screens/notification_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // User Header
          UserAccountsDrawerHeader(
            accountName: Text(
              currentUser?.displayName ?? 'Người dùng',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(currentUser?.email ?? 'Chưa đăng nhập'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: currentUser?.photoURL != null
                  ? NetworkImage(currentUser!.photoURL!)
                  : null,
              child: currentUser?.photoURL == null
                  ? const Icon(Icons.person, size: 40, color: Colors.blue)
                  : null,
            ),
            decoration: BoxDecoration(
              color: Colors.blue[900],
            ),
          ),
          
          // Navigation Items
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Trang chủ'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Trang cá nhân'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.shopping_bag_outlined),
            title: const Text('Sản phẩm của tôi'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyProductsScreen()),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.favorite_outline),
            title: const Text('Sản phẩm yêu thích'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavoriteProductsScreen()),
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.receipt_outlined),
            title: const Text('Lịch sử đơn hàng'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
              );
            },
          ),
          
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Thông báo'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationScreen()),
              );
            },
          ),
          
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Cài đặt'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          
          ListTile(
            leading: Icon(isDarkMode ? Icons.brightness_7 : Icons.brightness_3),
            title: Text(isDarkMode ? 'Chế độ sáng' : 'Chế độ tối'),
            onTap: () {
              themeService.toggleTheme();
              Navigator.pop(context);
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Đăng xuất'),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Đăng xuất'),
                    content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Hủy'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('Đăng xuất'),
                        onPressed: () {
                          authService.signOut();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          
          const Spacer(),
          
          // App version
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Student Market NTTU v1.0.0',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 