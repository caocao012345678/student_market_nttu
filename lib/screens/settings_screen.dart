import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_market_nttu/services/theme_service.dart';
import 'package:student_market_nttu/screens/change_password_screen.dart';
import 'package:student_market_nttu/screens/my_products_screen.dart';
import 'package:student_market_nttu/screens/add_product_screen.dart';
import 'package:student_market_nttu/screens/admin/admin_home_screen.dart';
import 'package:student_market_nttu/services/auth_service.dart';
import 'package:student_market_nttu/widgets/common_app_bar.dart';
import 'package:student_market_nttu/widgets/app_drawer.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final authService = Provider.of<AuthService>(context);
    final isDarkMode = themeService.isDarkMode;
    
    return Scaffold(
      appBar: const CommonAppBar(
        title: 'Cài đặt',
      ),
      drawer: const AppDrawer(),
      body: ListView(
        children: [          
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Chủ đề'),
            trailing: Consumer<ThemeService>(
              builder: (context, themeService, child) {
                return Switch(
                  value: themeService.isDarkMode,
                  onChanged: (value) {
                    themeService.toggleTheme();
                  },
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Đổi mật khẩu'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ChangePasswordScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Thông báo'),
            trailing: Switch(
              value: Provider.of<ThemeService>(context).isNotificationEnabled,
              onChanged: (value) {
                Provider.of<ThemeService>(context, listen: false).toggleNotification(value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(value ? 'Đã bật thông báo' : 'Đã tắt thông báo')),
                );
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Ngôn ngữ'),
            trailing: const Text('Tiếng Việt'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Chọn ngôn ngữ'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Tiếng Việt'),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã chọn Tiếng Việt')),
                          );
                        },
                      ),
                      ListTile(
                        title: const Text('English'),
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('English selected')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Trợ giúp'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Trợ giúp')),
                    body: const Center(child: Text('Đây là trang trợ giúp.')), // Placeholder
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Giới thiệu'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Giới thiệu')), 
                    body: const Center(child: Text('Ứng dụng Student Market NTTU.')), // Placeholder
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
} 