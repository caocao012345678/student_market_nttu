import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../screens/chat_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  List<QueryDocumentSnapshot> _recentUsers = [];
  
  @override
  void initState() {
    super.initState();
    _loadRecentChats();
  }

  Future<void> _loadRecentChats() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      final snapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('participantsArray', arrayContains: chatService.currentUserId)
          .orderBy('lastMessageTime', descending: true)
          .limit(5)
          .get();
      
      // Lấy danh sách người dùng từ các cuộc trò chuyện gần đây
      final Set<String> recentUserIds = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final List<String> participants = List<String>.from(data['participantsArray'] ?? []);
        for (final userId in participants) {
          if (userId != chatService.currentUserId) {
            recentUserIds.add(userId);
          }
        }
      }
      
      // Lấy thông tin người dùng
      if (recentUserIds.isNotEmpty) {
        final userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: recentUserIds.toList())
            .get();
        
        setState(() {
          _recentUsers = userSnapshot.docs;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tải cuộc trò chuyện gần đây: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.trim();
    });
  }

  Future<void> _startChat(String userId, String displayName, String photoURL) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      final chatId = await chatService.getChatId(userId);
      
      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            otherUserId: userId,
            otherUserName: displayName,
            otherUserPhotoUrl: photoURL,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context);
    final chatService = Provider.of<ChatService>(context);
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trò chuyện mới'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm người dùng...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: _performSearch,
            ),
          ),
          if (_recentUsers.isNotEmpty && _searchQuery.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.history, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Trò chuyện gần đây',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          if (_recentUsers.isNotEmpty && _searchQuery.isEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentUsers.length,
              itemBuilder: (context, index) {
                final userData = _recentUsers[index].data() as Map<String, dynamic>;
                final userId = _recentUsers[index].id;
                final displayName = userData['displayName'] ?? 'Người dùng';
                final photoURL = userData['photoURL'] ?? '';
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: photoURL.isNotEmpty
                        ? CachedNetworkImageProvider(photoURL)
                        : null,
                    child: photoURL.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(displayName),
                  subtitle: Text(userData['email'] ?? ''),
                  onTap: () => _startChat(userId, displayName, photoURL),
                );
              },
            ),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : FutureBuilder<QuerySnapshot>(
                    future: _searchQuery.isEmpty
                        ? FirebaseFirestore.instance.collection('users').limit(20).get()
                        : FirebaseFirestore.instance
                            .collection('users')
                            .where('displayName', isGreaterThanOrEqualTo: _searchQuery)
                            .where('displayName', isLessThan: _searchQuery + 'z')
                            .limit(20)
                            .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Đã xảy ra lỗi: ${snapshot.error}'),
                        );
                      }

                      final users = snapshot.data?.docs ?? [];
                      
                      if (users.isEmpty) {
                        return const Center(
                          child: Text('Không tìm thấy người dùng nào'),
                        );
                      }

                      return ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final userData = users[index].data() as Map<String, dynamic>;
                          final userId = users[index].id;
                          
                          // Bỏ qua người dùng hiện tại
                          if (userId == chatService.currentUserId) {
                            return const SizedBox.shrink();
                          }
                          
                          final displayName = userData['displayName'] ?? 'Người dùng';
                          final photoURL = userData['photoURL'] ?? '';
                          
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: photoURL.isNotEmpty
                                  ? CachedNetworkImageProvider(photoURL)
                                  : null,
                              child: photoURL.isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(displayName),
                            subtitle: Text(userData['email'] ?? ''),
                            onTap: () => _startChat(userId, displayName, photoURL),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
} 