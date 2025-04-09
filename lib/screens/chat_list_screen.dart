import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';

import '../services/chat_service.dart';
import '../models/chat_room.dart';
import '../services/user_service.dart';
import '../screens/chat_screen.dart';
import '../screens/new_chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  
  @override
  void initState() {
    super.initState();
    // Khởi tạo locale cho timeago
    timeago.setLocaleMessages('vi', timeago.ViMessages());
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
  
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);
    final userService = Provider.of<UserService>(context);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Tìm cuộc trò chuyện...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: _performSearch,
                autofocus: true,
              )
            : const Text('Tin nhắn'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: const Icon(Icons.add_comment),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NewChatScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: chatService.getChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Đã xảy ra lỗi: ${snapshot.error}'),
            );
          }

          final chatDocs = snapshot.data?.docs ?? [];
          if (chatDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Bạn chưa có cuộc trò chuyện nào'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NewChatScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo cuộc trò chuyện mới'),
                  ),
                ],
              ),
            );
          }

          // Lọc danh sách chat theo từ khóa tìm kiếm nếu có
          List<QueryDocumentSnapshot> filteredChats = chatDocs;
          if (_searchQuery.isNotEmpty) {
            filteredChats = [];
            for (final chatDoc in chatDocs) {
              final chatData = chatDoc.data() as Map<String, dynamic>;
              final lastMessage = (chatData['lastMessage'] ?? '').toString().toLowerCase();
              if (lastMessage.contains(_searchQuery.toLowerCase())) {
                filteredChats.add(chatDoc);
                continue;
              }
              
              // Tiếp tục tìm kiếm theo tên người dùng
              final chatRoom = ChatRoom.fromMap(chatData, chatDoc.id);
              final otherUserId = chatRoom.getOtherUserId(chatService.currentUserId!);
              if (otherUserId.isNotEmpty) {
                // Sử dụng FutureBuilder để hiển thị sau khi tìm người dùng
                userService.getUserById(otherUserId).then((userSnapshot) {
                  if (userSnapshot.exists) {
                    final userData = userSnapshot.data() as Map<String, dynamic>;
                    final displayName = (userData['displayName'] ?? '').toString().toLowerCase();
                    if (displayName.contains(_searchQuery.toLowerCase())) {
                      setState(() {
                        filteredChats.add(chatDoc);
                      });
                    }
                  }
                });
              }
            }
          }

          if (filteredChats.isEmpty && _searchQuery.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Không tìm thấy cuộc trò chuyện nào khớp với "$_searchQuery"'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.separated(
              itemCount: filteredChats.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final chatData = filteredChats[index].data() as Map<String, dynamic>;
                final chatRoom = ChatRoom.fromMap(chatData, filteredChats[index].id);
                
                // Lấy ID của người dùng khác trong cuộc trò chuyện
                final otherUserId = chatRoom.getOtherUserId(chatService.currentUserId!);
                
                return FutureBuilder<DocumentSnapshot>(
                  future: userService.getUserById(otherUserId),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text('Đang tải...'),
                      );
                    }
                    
                    Map<String, dynamic>? userData;
                    String displayName = 'Người dùng';
                    String photoURL = '';
                    
                    if (userSnapshot.hasData && userSnapshot.data != null) {
                      userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                      displayName = userData?['displayName'] ?? 'Người dùng';
                      photoURL = userData?['photoURL'] ?? '';
                    }
                    
                    final isUnread = chatRoom.lastMessageSenderId != null && 
                                    chatRoom.lastMessageSenderId != chatService.currentUserId;
                    
                    return Dismissible(
                      key: Key('chat_${chatRoom.id}'),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Xác nhận'),
                            content: const Text('Bạn có muốn xóa cuộc trò chuyện này không?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Hủy'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Xóa'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        // Thêm code xóa cuộc trò chuyện ở đây
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã xóa cuộc trò chuyện')),
                        );
                      },
                      child: ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: photoURL.isNotEmpty 
                                ? CachedNetworkImageProvider(photoURL)
                                : null,
                              child: photoURL.isEmpty 
                                ? const Icon(Icons.person, color: Colors.grey)
                                : null,
                            ),
                            if (isUnread)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          displayName,
                          style: TextStyle(
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          chatRoom.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                            color: isUnread ? Colors.black : Colors.grey[600],
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatTimeAgo(chatRoom.lastMessageTime),
                              style: TextStyle(
                                fontSize: 12,
                                color: isUnread ? Colors.blue[900] : Colors.grey,
                              ),
                            ),
                            if (isUnread)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue[900],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Mới',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                chatId: chatRoom.id,
                                otherUserId: otherUserId,
                                otherUserName: displayName,
                                otherUserPhotoUrl: photoURL,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NewChatScreen(),
            ),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  String _formatTimeAgo(DateTime messageTime) {
    return timeago.format(messageTime, locale: 'vi');
  }
} 