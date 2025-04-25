import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:student_market_nttu/models/user.dart';
import 'package:student_market_nttu/services/user_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Bộ lọc
  String _selectedRole = 'Tất cả';
  final List<String> _roles = ['Tất cả', 'Admin', 'Shipper', 'Sinh viên', 'Thường'];
  
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final snapshot = await _firestore.collection('users').get();
      _users = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
      
      _applyFilters();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }
  
  void _applyFilters() {
    setState(() {
      _filteredUsers = _users.where((user) {
        // Lọc theo vai trò
        if (_selectedRole == 'Admin' && !user.isAdmin) {
          return false;
        }
        if (_selectedRole == 'Shipper' && !user.isShipper) {
          return false;
        }
        if (_selectedRole == 'Sinh viên' && !user.isStudent) {
          return false;
        }
        if (_selectedRole == 'Thường' && (user.isAdmin || user.isShipper || user.isStudent)) {
          return false;
        }
        
        // Lọc theo tìm kiếm
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          return user.displayName.toLowerCase().contains(query) ||
              user.email.toLowerCase().contains(query) ||
              (user.phoneNumber.isNotEmpty && user.phoneNumber.contains(query)) ||
              (user.studentId != null && user.studentId!.toLowerCase().contains(query));
        }
        
        return true;
      }).toList();
    });
  }
  
  Future<void> _toggleAdminRole(UserModel user) async {
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      
      // Kiểm tra xem người dùng hiện tại có phải admin không
      final isCurrentUserAdmin = await userService.isCurrentUserAdmin();
      if (!isCurrentUserAdmin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn không có quyền thực hiện thao tác này')),
        );
        return;
      }
      
      // Người dùng không thể tự bỏ quyền admin của mình
      final currentUser = userService.currentUser;
      if (currentUser?.id == user.id) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn không thể thay đổi quyền của chính mình')),
        );
        return;
      }
      
      // Xác nhận thay đổi quyền
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(user.isAdmin ? 'Hủy quyền Admin' : 'Gán quyền Admin'),
          content: Text(
            user.isAdmin 
              ? 'Bạn có chắc muốn hủy quyền Admin của ${user.displayName}?' 
              : 'Bạn có chắc muốn gán quyền Admin cho ${user.displayName}?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      );
      
      if (confirm == true) {
        // Cập nhật quyền admin
        await _firestore.collection('users').doc(user.id).update({
          'isAdmin': !user.isAdmin,
        });
        
        // Cập nhật danh sách
        _loadUsers();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                user.isAdmin 
                  ? 'Đã hủy quyền admin của ${user.displayName}' 
                  : 'Đã gán quyền admin cho ${user.displayName}'
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm người dùng...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                                _applyFilters();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedRole,
                  items: _roles.map((role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedRole = value;
                      });
                      _applyFilters();
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? const Center(child: Text('Không tìm thấy người dùng nào'))
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: user.photoURL.isNotEmpty
                                    ? CachedNetworkImageProvider(user.photoURL)
                                    : null,
                                child: user.photoURL.isEmpty
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(
                                user.displayName.isNotEmpty ? user.displayName : user.email,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.email),
                                  if (user.phoneNumber.isNotEmpty)
                                    Text('SĐT: ${user.phoneNumber}'),
                                  if (user.isStudent && user.studentId != null)
                                    Text('MSSV: ${user.studentId}'),
                                  Row(
                                    children: [
                                      if (user.isAdmin)
                                        _buildRoleBadge('Admin', Colors.red),
                                      if (user.isShipper)
                                        _buildRoleBadge('Shipper', Colors.orange),
                                      if (user.isStudent)
                                        _buildRoleBadge('Sinh viên', Colors.blue),
                                      if (!user.isAdmin && !user.isShipper && !user.isStudent)
                                        _buildRoleBadge('Thường', Colors.grey),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'toggleAdmin') {
                                    _toggleAdminRole(user);
                                  } else if (value == 'viewProfile') {
                                    // Mở trang thông tin chi tiết người dùng
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'toggleAdmin',
                                    child: Row(
                                      children: [
                                        Icon(
                                          user.isAdmin ? Icons.remove_moderator : Icons.admin_panel_settings,
                                          size: 18,
                                          color: user.isAdmin ? Colors.red : Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(user.isAdmin ? 'Hủy quyền Admin' : 'Gán quyền Admin'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'viewProfile',
                                    child: Row(
                                      children: [
                                        Icon(Icons.person, size: 18),
                                        SizedBox(width: 8),
                                        Text('Xem hồ sơ'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                // Mở trang thông tin chi tiết người dùng
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRoleBadge(String role, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 