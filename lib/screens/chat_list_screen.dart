import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:student_market_nttu/models/chat.dart';
import 'package:student_market_nttu/models/user.dart';
import 'package:student_market_nttu/screens/chat_detail_screen.dart';
import 'package:student_market_nttu/screens/home_screen.dart';
import 'package:student_market_nttu/services/chat_service.dart';
import 'package:student_market_nttu/services/user_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:student_market_nttu/widgets/common_app_bar.dart';

import 'login_screen.dart';

class ChatListScreen extends StatefulWidget {
  static const routeName = '/chat-list';

  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  // Lưu cache thông tin người dùng
  final Map<String, UserModel?> _userCache = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Khởi tạo dữ liệu khi vừa vào màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
      
      // Đặt time-out để tránh hiển thị loading quá lâu
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _isLoading) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    });
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      await chatService.initializeChats();
    } catch (error) {
      // Xử lý lỗi im lặng
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Lấy thông tin người dùng khác trong cuộc trò chuyện
  Future<UserModel?> _getOtherUserInChat(Chat chat) async {
    final chatService = Provider.of<ChatService>(context, listen: false);
    final currentUserId = chatService.currentUserId;

    // Lấy ID của người dùng khác
    final otherUserId = chat.participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );

    if (otherUserId.isEmpty) {
      return null;
    }

    // Kiểm tra cache
    if (_userCache.containsKey(otherUserId)) {
      return _userCache[otherUserId];
    }

    // Lấy thông tin người dùng
    final userService = Provider.of<UserService>(context, listen: false);
    final user = await userService.getUserById(otherUserId);
    
    // Cập nhật cache
    _userCache[otherUserId] = user;
    
    return user;
  }

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);
    final isLoggedIn = chatService.currentUserId.isNotEmpty;
    
    return Scaffold(
      appBar: const CommonAppBar(
        title: 'Tin nhắn',
        showNotificationBadge: true,
        showCartBadge: true,
      ),
      body: !isLoggedIn 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_circle,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Vui lòng đăng nhập để xem tin nhắn',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
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
            )
          : _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<List<Chat>>(
                  stream: chatService.getUserChats(),
                  builder: (context, snapshot) {
                    // Nếu đang chờ dữ liệu từ stream và chưa có dữ liệu nào, hiển thị loading
                    if (snapshot.connectionState == ConnectionState.waiting && 
                        !snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Đã xảy ra lỗi: ${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadInitialData,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      );
                    }

                    final chats = snapshot.data ?? [];

                    if (chats.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Bạn chưa có cuộc trò chuyện nào',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                // Quay về màn hình HomeScreen và chuyển sang tab Sản phẩm (index 1)
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/', 
                                  (route) => false,
                                  arguments: {'initialIndex': 1}
                                );
                              },
                              child: const Text('Khám phá sản phẩm'),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _loadInitialData,
                      child: ListView.builder(
                        itemCount: chats.length,
                        itemBuilder: (context, index) {
                          final chat = chats[index];
                          return FutureBuilder<UserModel?>(
                            future: _getOtherUserInChat(chat),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.connectionState ==
                                      ConnectionState.waiting &&
                                  !_userCache.containsKey(chat.participants.firstWhere(
                                    (id) => id != (chatService.currentUserId.isEmpty ? '' : chatService.currentUserId),
                                    orElse: () => '',
                                  ))) {
                                return const ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.grey,
                                    child: Icon(Icons.person, color: Colors.white),
                                  ),
                                  title: Text('Đang tải...'),
                                  subtitle: Text(''),
                                );
                              }

                              final otherUser = userSnapshot.data;
                              final lastMessage = chat.lastMessage;
                              final unreadCount =
                                  chat.unreadCount[chatService.currentUserId] ?? 0;
                              
                              // Kiểm tra xem tin nhắn cuối cùng có phải của người dùng hiện tại không
                              final isLastMessageFromCurrentUser = 
                                  lastMessage != null && 
                                  lastMessage['senderId'] == chatService.currentUserId;

                              // Xử lý hiển thị nội dung tin nhắn cuối cùng
                              String lastMessageContent = '';
                              if (lastMessage != null) {
                                final messageType = lastMessage['type'] ?? 'text';
                                if (messageType == 'text') {
                                  lastMessageContent = lastMessage['content'] ?? '';
                                } else if (messageType == 'image') {
                                  lastMessageContent = 'Đã gửi hình ảnh';
                                } else if (messageType == 'product') {
                                  lastMessageContent = lastMessage['content'] ?? 'Đã gửi thông tin sản phẩm';
                                } else {
                                  lastMessageContent = 'Tin nhắn mới';
                                }
                              }

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.grey[300],
                                  backgroundImage: otherUser?.photoURL.isNotEmpty == true
                                      ? CachedNetworkImageProvider(otherUser!.photoURL)
                                      : null,
                                  child: otherUser?.photoURL.isEmpty == true
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                title: Text(
                                  otherUser?.displayName ?? 'Người dùng',
                                  style: TextStyle(
                                    fontWeight: unreadCount > 0
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Row(
                                  children: [
                                    isLastMessageFromCurrentUser 
                                        ? const Text('Bạn: ', 
                                            style: TextStyle(
                                              fontSize: 12, 
                                              color: Colors.grey
                                            )
                                          )
                                        : const SizedBox(),
                                    Expanded(
                                      child: Text(
                                        lastMessageContent,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: unreadCount > 0
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      lastMessage != null
                                          ? timeago.format(
                                              (lastMessage['timestamp'] as dynamic)
                                                  .toDate(),
                                              locale: 'vi',
                                            )
                                          : '',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (unreadCount > 0)
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[900],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          unreadCount.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ChatDetailScreen(
                                        chatId: chat.id,
                                        otherUser: otherUser,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
} 