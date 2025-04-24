import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_market_nttu/services/user_service.dart';
import 'package:student_market_nttu/screens/admin/moderation_dashboard_screen.dart';
import 'package:student_market_nttu/screens/admin/moderation_stats_screen.dart';
import 'package:student_market_nttu/screens/admin/user_management_screen.dart';
import 'package:student_market_nttu/screens/home_screen.dart';
import 'package:student_market_nttu/screens/login_screen.dart';
import 'package:student_market_nttu/services/auth_service.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final isAdmin = await userService.isCurrentUserAdmin();

      setState(() {
        _isAdmin = isAdmin;
        _isLoading = false;
      });

      if (!isAdmin && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bạn không có quyền truy cập vào trang quản trị'),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xảy ra lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Quản trị hệ thống'),
          backgroundColor: Colors.blue[900],
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Quản trị hệ thống'),
          backgroundColor: Colors.blue[900],
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Bạn không có quyền truy cập vào trang quản trị'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản trị hệ thống'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility),
            tooltip: 'Xem như người dùng thường',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () {
              _showLogoutConfirmDialog();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chào mừng đến với trang quản trị',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chọn một chức năng bên dưới để bắt đầu',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16.0,
              runSpacing: 16.0,
              children: [
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 48) / 2,
                  child: _buildMenuCard(
                    title: 'Kiểm duyệt sản phẩm',
                    icon: Icons.fact_check,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ModerationDashboardScreen(),
                        ),
                      );
                    },
                    subtitle: 'Xem và xử lý yêu cầu kiểm duyệt',
                  ),
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 48) / 2,
                  child: _buildMenuCard(
                    title: 'Thống kê kiểm duyệt',
                    icon: Icons.analytics,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ModerationStatsScreen(),
                        ),
                      );
                    },
                    subtitle: 'Xem báo cáo và số liệu thống kê',
                  ),
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 48) / 2,
                  child: _buildMenuCard(
                    title: 'Quản lý người dùng',
                    icon: Icons.people,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserManagementScreen(),
                        ),
                      );
                    },
                    subtitle: 'Phân quyền và quản lý tài khoản',
                  ),
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - 48) / 2,
                  child: _buildMenuCard(
                    title: 'Cài đặt hệ thống',
                    icon: Icons.settings,
                    color: Colors.purple,
                    onTap: () {
                      // TODO: Implement system settings screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tính năng đang phát triển'),
                        ),
                      );
                    },
                    subtitle: 'Cấu hình và tùy chỉnh hệ thống',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi đăng xuất: ${e.toString()}')),
        );
      }
    }
  }
} 