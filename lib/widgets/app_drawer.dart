import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_market_nttu/services/auth_service.dart';
import 'package:student_market_nttu/services/theme_service.dart';
import 'package:student_market_nttu/services/ntt_point_service.dart';
import 'package:student_market_nttu/screens/home_screen.dart';
import 'package:student_market_nttu/screens/profile_screen.dart';
import 'package:student_market_nttu/screens/settings_screen.dart';
import 'package:student_market_nttu/screens/my_products_screen.dart';
import 'package:student_market_nttu/screens/order_history_screen.dart';
import 'package:student_market_nttu/screens/favorite_products_screen.dart';
import 'package:student_market_nttu/screens/notification_screen.dart';
import 'package:student_market_nttu/screens/chat_list_screen.dart';
import 'package:student_market_nttu/screens/ntt_point_history_screen.dart';

import '../screens/admin/admin_home_screen.dart';
import '../screens/login_screen.dart';
import '../services/user_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    final pointService = Provider.of<NTTPointService>(context);
    final isLoggedIn = currentUser != null;

    return Drawer(
      child: FutureBuilder<bool>(
        // Check if the current user is an admin
        future: Provider.of<UserService>(context, listen: false).isCurrentUserAdmin(),
        builder: (context, snapshot) {
          // Determine if the admin tile should be shown
          final bool showAdminTile = snapshot.connectionState == ConnectionState.done &&
                                     snapshot.hasData &&
                                     snapshot.data == true;

          return ListView(
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
                  color: Theme.of(context).colorScheme.primary, // Use theme color
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

              ListTile(
                leading: const Icon(Icons.chat_outlined),
                title: const Text('Tin nhắn'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatListScreen()),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.monetization_on_outlined),
                title: Row(
                  children: [
                    const Text('NTTPoint'),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${pointService.availablePoints}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NTTPointHistoryScreen()),
                  );
                },
              ),

              const Divider(),

              // Admin Dashboard Tile (conditionally displayed)
              if (showAdminTile)
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: const Text('Trang quản trị'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
                    );
                  },
                ),

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
                  // Navigator.pop(context); // No need to pop, theme change doesn't require closing drawer
                },
              ),
              // Use a conditional expression to show either Login or Logout tile
              isLoggedIn
                  ? ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Đăng xuất'),
                      onTap: () {
                        Navigator.pop(context); // Close the drawer
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
                                    Navigator.of(context).pop(); // Close dialog
                                    // Chuyển về trang chủ sau khi đăng xuất
                                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    )
                  : ListTile(
                      leading: const Icon(Icons.login),
                      title: const Text('Đăng nhập'),
                      onTap: () {
                        Navigator.pop(context); // Close the drawer
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                    ),

              // Spacer is not typically used directly in a ListView's children list
              // Use Expanded or Flexible within a Column if needed, but ListView handles scrolling
              // If you need space at the bottom, add padding or a SizedBox

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
          );
        }
      ),
    );
  }
} 