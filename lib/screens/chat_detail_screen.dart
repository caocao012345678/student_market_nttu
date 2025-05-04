import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:student_market_nttu/models/chat_message_detail.dart';
import 'package:student_market_nttu/models/user.dart';
import 'package:student_market_nttu/services/chat_service.dart';
import 'package:student_market_nttu/services/user_service.dart';
import 'package:student_market_nttu/services/notification_service.dart';
import 'package:student_market_nttu/utils/ui_utils.dart';

class ChatDetailScreen extends StatefulWidget {
  static const routeName = '/chat-detail';
  
  final String chatId;
  final UserModel? otherUser;

  const ChatDetailScreen({
    Key? key,
    required this.chatId,
    this.otherUser,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  UserModel? _otherUser;
  bool _isLoading = true;
  bool _isSending = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      await Future.wait([
        _loadChatData(),
      ]).timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('Tải dữ liệu tin nhắn quá thời gian, vui lòng thử lại');
      });
    } catch (error) {
      debugPrint('Lỗi khi khởi tạo: $error');
      setState(() {
        _hasError = true;
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadChatData() async {
    final chatService = Provider.of<ChatService>(context, listen: false);
    
    await chatService.markAsRead(widget.chatId);
    
    if (widget.otherUser == null) {
      _otherUser = await chatService.getOtherUserInChat(widget.chatId, context);
    } else {
      _otherUser = widget.otherUser;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      await chatService.sendTextMessage(widget.chatId, message, context: context);
      _messageController.clear();
      
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (error) {
      debugPrint('Lỗi khi gửi tin nhắn: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi gửi tin nhắn: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _pickAndSendImage() async {
    if (_isSending) return;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile == null) return;

      setState(() {
        _isSending = true;
      });

      final chatService = Provider.of<ChatService>(context, listen: false);
      await chatService.sendImageMessage(widget.chatId, pickedFile, context: context);
    } catch (error) {
      debugPrint('Lỗi khi gửi hình ảnh: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi gửi hình ảnh: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      await chatService.deleteMessage(widget.chatId, messageId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa tin nhắn')),
      );
    } catch (error) {
      debugPrint('Lỗi khi xóa tin nhắn: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa tin nhắn: $error')),
      );
    }
  }

  Widget _buildMessageItem(ChatMessageDetail message) {
    final chatService = Provider.of<ChatService>(context, listen: false);
    final isCurrentUser = message.senderId == chatService.currentUserId;
    final timeString = timeago.format(message.timestamp, locale: 'vi');

    return GestureDetector(
      onLongPress: isCurrentUser 
          ? () => _showMessageOptions(message.id) 
          : null,
      child: Align(
        alignment: isCurrentUser 
            ? Alignment.centerRight 
            : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(
            vertical: 4,
            horizontal: 12,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: isCurrentUser 
                ? Colors.blue[700] 
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          child: Column(
            crossAxisAlignment: isCurrentUser 
                ? CrossAxisAlignment.end 
                : CrossAxisAlignment.start,
            children: [
              if (message.type == ChatMessageType.text)
                Text(
                  message.content,
                  style: TextStyle(
                    color: isCurrentUser ? Colors.white : Colors.black,
                  ),
                )
              else if (message.type == ChatMessageType.image)
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: message.metadata?['url'] ?? '',
                        placeholder: (context, url) => const SizedBox(
                          height: 150,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (message.content.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          message.content,
                          style: TextStyle(
                            color: isCurrentUser ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                  ],
                )
              else if (message.type == ChatMessageType.product)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: message.metadata?['imageUrl'] ?? '',
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => 
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => 
                              const Icon(Icons.error),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.metadata?['productName'] ?? 'Sản phẩm',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message.metadata?['price'] ?? '',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            OutlinedButton(
                              onPressed: () {
                                // Chuyển đến trang chi tiết sản phẩm
                                // Tính năng sẽ triển khai sau
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 36),
                              ),
                              child: const Text('Xem chi tiết'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  'Loại tin nhắn không được hỗ trợ',
                  style: TextStyle(
                    color: isCurrentUser ? Colors.white : Colors.black,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              
              const SizedBox(height: 4),
              Text(
                timeString,
                style: TextStyle(
                  fontSize: 10,
                  color: isCurrentUser 
                      ? Colors.white.withOpacity(0.7) 
                      : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMessageOptions(String messageId) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Xóa tin nhắn'),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(messageId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Sao chép nội dung'),
              onTap: () {
                Navigator.pop(context);
                // Tính năng sao chép nội dung sẽ triển khai sau
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);
    final user = _otherUser ?? widget.otherUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              backgroundImage: user?.photoURL.isNotEmpty == true
                  ? CachedNetworkImageProvider(user!.photoURL)
                  : null,
              child: user?.photoURL.isEmpty == true
                  ? const Icon(Icons.person, size: 16)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? 'Người dùng',
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (user != null)
                    Text(
                      user.isStudent ? 'Sinh viên' : 'Người dùng',
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Hiển thị thông tin cuộc trò chuyện
              // Tính năng sẽ triển khai sau
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError 
              ? _buildErrorView()
              : Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<List<ChatMessageDetail>>(
                        stream: chatService.getChatMessages(widget.chatId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                            return const Center(
                              child: SizedBox(
                                width: 30, 
                                height: 30, 
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Đã xảy ra lỗi: ${snapshot.error}',
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _init,
                                    child: const Text('Thử lại'),
                                  ),
                                ],
                              ),
                            );
                          }

                          final messages = snapshot.data ?? [];

                          if (messages.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.chat_bubble_outline,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Bắt đầu cuộc trò chuyện với ${user?.displayName ?? 'người dùng này'}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              return _buildMessageItem(message);
                            },
                          );
                        },
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            blurRadius: 3,
                            offset: const Offset(0, -1),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add_photo_alternate),
                              onPressed: _isSending ? null : _pickAndSendImage,
                            ),
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: const InputDecoration(
                                  hintText: 'Nhập tin nhắn...',
                                  border: InputBorder.none,
                                ),
                                textCapitalization: TextCapitalization.sentences,
                                keyboardType: TextInputType.multiline,
                                maxLines: null,
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            IconButton(
                              icon: _isSending
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.send, color: Colors.blue),
                              onPressed: _isSending ? null : _sendMessage,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Không thể tải dữ liệu tin nhắn: $_errorMessage',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _init,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
} 