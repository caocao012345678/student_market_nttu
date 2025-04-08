import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_market_nttu/services/theme_service.dart';
import 'package:student_market_nttu/screens/change_password_screen.dart';
import 'package:student_market_nttu/screens/my_products_screen.dart';
import 'package:student_market_nttu/screens/add_product_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
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
              value: true, // TODO: Implement notification settings
              onChanged: (value) {
                // TODO: Update notification settings
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Ngôn ngữ'),
            trailing: const Text('Tiếng Việt'),
            onTap: () {
              // TODO: Implement language selection
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Trợ giúp'),
            onTap: () {
              // TODO: Navigate to help screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Giới thiệu'),
            onTap: () {
              // TODO: Navigate to about screen
            },
          ),
        ],
      ),
    );
  }
} 