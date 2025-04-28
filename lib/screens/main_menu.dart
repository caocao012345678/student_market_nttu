import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_market_nttu/services/user_service.dart';
import 'package:student_market_nttu/screens/profile_screen.dart';
import 'package:student_market_nttu/screens/cart_screen.dart';
import 'package:student_market_nttu/screens/settings_screen.dart';
import 'package:student_market_nttu/screens/admin/admin_home_screen.dart';
import 'package:student_market_nttu/screens/chat_list_screen.dart';

class MainMenu extends StatefulWidget {
  final int initialIndex;
  
  const MainMenu({
    Key? key,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  late int _selectedIndex;
  
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }
  
  // Danh sách các màn hình trong bottom navigation
  static final List<Widget> _screens = [
    const HomeContent(),
    const ExploreContent(),
    const NotificationsContent(),
    const ProfileScreen(),
  ];
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context);
    final currentUser = userService.currentUser;
    final isLoggedIn = currentUser != null;
    
    // Thêm kiểm tra người dùng có phải admin không
    return FutureBuilder<bool>(
      future: isLoggedIn ? userService.isCurrentUserAdmin() : Future.value(false),
      builder: (context, adminSnapshot) {
        final isAdmin = adminSnapshot.data == true;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('NTT Market'),
            backgroundColor: Colors.blue[900],
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: 'Tìm kiếm',
                onPressed: () {
                  // Mở trang tìm kiếm
                },
              ),
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                tooltip: 'Giỏ hàng',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CartScreen(),
                    ),
                  );
                },
              ),
              
              // Thêm nút truy cập trang quản trị cho admin
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.admin_panel_settings),
                  tooltip: 'Quản trị hệ thống',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminHomeScreen(),
                      ),
                    );
                  },
                ),
            ],
          ),
          
          body: _screens[_selectedIndex],
          
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(isLoggedIn ? (currentUser.displayName ?? 'Người dùng') : 'Chưa đăng nhập'),
                  accountEmail: Text(isLoggedIn ? (currentUser.email ?? '') : ''),
                  currentAccountPicture: CircleAvatar(
                    backgroundImage: isLoggedIn && currentUser.photoURL.isNotEmpty
                        ? NetworkImage(currentUser.photoURL)
                        : null,
                    child: isLoggedIn && currentUser.photoURL.isEmpty
                        ? Text(
                            (currentUser.displayName ?? 'User').substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontSize: 24),
                          )
                        : null,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue[900],
                  ),
                ),
                
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Trang chủ'),
                  onTap: () {
                    Navigator.pop(context);
                    _onItemTapped(0);
                  },
                ),
                
                ListTile(
                  leading: const Icon(Icons.explore),
                  title: const Text('Khám phá'),
                  onTap: () {
                    Navigator.pop(context);
                    _onItemTapped(1);
                  },
                ),
                
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Thông báo'),
                  onTap: () {
                    Navigator.pop(context);
                    _onItemTapped(2);
                  },
                ),
                
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Hồ sơ'),
                  onTap: () {
                    Navigator.pop(context);
                    _onItemTapped(3);
                  },
                ),
                
                const Divider(),
                
                ListTile(
                  leading: const Icon(Icons.shopping_cart),
                  title: const Text('Giỏ hàng'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CartScreen(),
                      ),
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
                      MaterialPageRoute(
                        builder: (context) => const ChatListScreen(),
                      ),
                    );
                  },
                ),
                
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Cài đặt'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                
                // Thêm menu Quản trị hệ thống cho admin
                if (isAdmin) ...[
                  const Divider(),
                  const ListTile(
                    title: Text(
                      'Quản trị',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: const Text('Quản trị hệ thống'),
                    onTap: () {
                      Navigator.pop(context); // Đóng drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminHomeScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Trang chủ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.explore),
                label: 'Khám phá',
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
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.blue[900],
            onTap: _onItemTapped,
          ),
        );
      }
    );
  }
}

// Placeholder widgets cho các màn hình
class HomeContent extends StatelessWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Màn hình Trang chủ'),
    );
  }
}

class ExploreContent extends StatelessWidget {
  const ExploreContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Màn hình Khám phá'),
    );
  }
}

class NotificationsContent extends StatelessWidget {
  const NotificationsContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Màn hình Thông báo'),
    );
  }
} 