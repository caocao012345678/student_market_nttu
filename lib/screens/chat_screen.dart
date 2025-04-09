import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import '../services/chat_service.dart';
import '../models/chat_message.dart';
import '../services/user_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserPhotoUrl;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserPhotoUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isAttachmentMenuVisible = false;
  bool _isEmojiPickerVisible = false;
  bool _isSending = false;
  bool _isTyping = false;
  bool _hasNewMessage = false;
  String _typingStatus = '';

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('vi', timeago.ViMessages());
    _markMessagesAsRead();
    
    // Lắng nghe sự kiện cuộn để hiển thị nút cuộn xuống
    _scrollController.addListener(() {
      if (_scrollController.position.pixels > 300 && !_hasNewMessage) {
        setState(() {
          _hasNewMessage = true;
        });
      }
    });
    
    // Lắng nghe sự kiện focus để ẩn emoji picker khi keyboard hiện lên
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _isEmojiPickerVisible) {
        setState(() {
          _isEmojiPickerVisible = false;
        });
      }
    });
  }

  void _markMessagesAsRead() {
    final chatService = Provider.of<ChatService>(context, listen: false);
    chatService.markMessagesAsRead(widget.chatId, widget.otherUserId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final chatService = Provider.of<ChatService>(context, listen: false);
    final message = _messageController.text.trim();
    _messageController.clear();
    setState(() {
      _isTyping = false;
    });

    setState(() {
      _isSending = true;
    });

    try {
      await chatService.sendMessage(widget.chatId, message);
      
      // Cuộn xuống dưới cùng
      _scrollToBottom();
      setState(() {
        _hasNewMessage = false;
      });
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    setState(() {
      _isAttachmentMenuVisible = false;
    });

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null && mounted) {
      setState(() {
        _isSending = true;
      });

      try {
        final chatService = Provider.of<ChatService>(context, listen: false);
        await chatService.sendImageMessage(widget.chatId, image);
        
        // Cuộn xuống dưới cùng
        _scrollToBottom();
        setState(() {
          _hasNewMessage = false;
        });
      } catch (e) {
        if (!mounted) return;
        _showErrorSnackBar(e.toString());
      } finally {
        if (mounted) {
          setState(() {
            _isSending = false;
          });
        }
      }
    }
  }

  Future<void> _takePhoto() async {
    setState(() {
      _isAttachmentMenuVisible = false;
    });

    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (photo != null && mounted) {
      setState(() {
        _isSending = true;
      });

      try {
        final chatService = Provider.of<ChatService>(context, listen: false);
        await chatService.sendImageMessage(widget.chatId, photo);
        
        // Cuộn xuống dưới cùng
        _scrollToBottom();
        setState(() {
          _hasNewMessage = false; 
        });
      } catch (e) {
        if (!mounted) return;
        _showErrorSnackBar(e.toString());
      } finally {
        if (mounted) {
          setState(() {
            _isSending = false;
          });
        }
      }
    }
  }

  Future<void> _pickFile() async {
    setState(() {
      _isAttachmentMenuVisible = false;
    });

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
    );

    if (result != null && mounted) {
      setState(() {
        _isSending = true;
      });

      try {
        final chatService = Provider.of<ChatService>(context, listen: false);
        final file = File(result.files.single.path!);
        await chatService.sendFileMessage(widget.chatId, file, result.files.single.name);
        
        // Cuộn xuống dưới cùng
        _scrollToBottom();
        setState(() {
          _hasNewMessage = false;
        });
      } catch (e) {
        if (!mounted) return;
        _showErrorSnackBar(e.toString());
      } finally {
        if (mounted) {
          setState(() {
            _isSending = false;
          });
        }
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lỗi: $message')),
    );
  }

  void _toggleAttachmentMenu() {
    setState(() {
      _isAttachmentMenuVisible = !_isAttachmentMenuVisible;
    });
  }

  void _toggleEmojiPicker() {
    setState(() {
      _isEmojiPickerVisible = !_isEmojiPickerVisible;
      if (_isEmojiPickerVisible) {
        _focusNode.unfocus();
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  void _showMessageOptions(ChatMessage message) {
    final chatService = Provider.of<ChatService>(context, listen: false);
    if (message.senderId != chatService.currentUserId) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Sao chép'),
              onTap: () {
                Navigator.pop(context);
                if (message.text != null) {
                  Clipboard.setData(ClipboardData(text: message.text!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã sao chép tin nhắn')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Xóa', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await chatService.deleteMessage(widget.chatId, message.id);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa tin nhắn')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  _showErrorSnackBar(e.toString());
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _handleTyping(String text) {
    bool isCurrentlyTyping = text.isNotEmpty;
    
    if (isCurrentlyTyping != _isTyping) {
      setState(() {
        _isTyping = isCurrentlyTyping;
      });
      
      // Có thể thêm cập nhật trạng thái typing lên Firestore
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);
    final userService = Provider.of<UserService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[200],
              backgroundImage: widget.otherUserPhotoUrl.isNotEmpty
                  ? CachedNetworkImageProvider(widget.otherUserPhotoUrl)
                  : null,
              child: widget.otherUserPhotoUrl.isEmpty
                  ? const Icon(Icons.person, size: 16, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(fontSize: 16),
                ),
                if (_typingStatus.isNotEmpty)
                  Text(
                    _typingStatus,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Hiển thị thông tin người dùng
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: chatService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}'));
                }

                final messages = snapshot.data?.docs ?? [];
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Chưa có tin nhắn nào, hãy bắt đầu trò chuyện!'),
                  );
                }

                // Đánh dấu tin nhắn đã đọc
                _markMessagesAsRead();

                String? currentDate;
                
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.blue.withOpacity(0.05),
                            Colors.grey.shade50,
                          ],
                        ),
                      ),
                      child: ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final messageData = messages[index].data() as Map<String, dynamic>;
                          final message = ChatMessage.fromMap(messageData, messages[index].id);
                          
                          // Kiểm tra xem tin nhắn có bị xóa không
                          if (message.deletedFor.contains(chatService.currentUserId)) {
                            return const SizedBox.shrink();
                          }
                          
                          // Nhóm tin nhắn theo ngày
                          final messageDate = DateFormat('dd/MM/yyyy').format(message.timestamp);
                          final showDateDivider = currentDate != messageDate;
                          if (showDateDivider) {
                            currentDate = messageDate;
                          }
                          
                          final isMe = message.senderId == chatService.currentUserId;
                          
                          // Hiển thị avatar chỉ cho tin nhắn đầu tiên của một chuỗi
                          final isFirstInSequence = _isFirstInSequence(messages, index);
                          
                          return Column(
                            children: [
                              if (showDateDivider)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getDateHeader(message.timestamp),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              MessageBubble(
                                message: message,
                                isMe: isMe,
                                showAvatar: !isMe && isFirstInSequence,
                                avatarUrl: !isMe ? widget.otherUserPhotoUrl : null,
                                onLongPress: () => _showMessageOptions(message),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    if (_hasNewMessage)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: FloatingActionButton(
                          mini: true,
                          heroTag: 'scrollBottom',
                          backgroundColor: Theme.of(context).primaryColor,
                          onPressed: () {
                            _scrollToBottom();
                            setState(() {
                              _hasNewMessage = false;
                            });
                          },
                          child: const Icon(Icons.arrow_downward, color: Colors.white),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          // Attachment menu
          if (_isAttachmentMenuVisible)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 100,
              color: Colors.grey[100],
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.photo_library,
                    label: 'Thư viện',
                    onTap: _pickImage,
                  ),
                  _buildAttachmentOption(
                    icon: Icons.camera_alt,
                    label: 'Máy ảnh',
                    onTap: _takePhoto,
                  ),
                  _buildAttachmentOption(
                    icon: Icons.insert_drive_file,
                    label: 'Tài liệu',
                    onTap: _pickFile,
                  ),
                ],
              ),
            ),
          // Message input box
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 3,
                  spreadRadius: 1,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: Colors.blue[700],
                  onPressed: _toggleAttachmentMenu,
                ),
                IconButton(
                  icon: Icon(_isEmojiPickerVisible 
                      ? Icons.keyboard 
                      : Icons.emoji_emotions_outlined),
                  color: Colors.blue[700],
                  onPressed: _toggleEmojiPicker,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    onChanged: _handleTyping,
                    minLines: 1,
                    maxLines: 5,
                  ),
                ),
                const SizedBox(width: 8),
                _isSending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send),
                          color: Colors.white,
                          onPressed: _sendMessage,
                        ),
                      ),
              ],
            ),
          ),
          // Emoji picker
          if (_isEmojiPickerVisible)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _messageController.text = _messageController.text + emoji.emoji;
                  _handleTyping(_messageController.text);
                },
                textEditingController: _messageController,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.blue[900]),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[900],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Hôm nay';
    } else if (difference.inDays == 1) {
      return 'Hôm qua';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  bool _isFirstInSequence(List<QueryDocumentSnapshot> messages, int index) {
    if (index == messages.length - 1) return true;
    
    final currentMessage = ChatMessage.fromMap(
      messages[index].data() as Map<String, dynamic>, 
      messages[index].id
    );
    
    final nextMessage = ChatMessage.fromMap(
      messages[index + 1].data() as Map<String, dynamic>, 
      messages[index + 1].id
    );
    
    return currentMessage.senderId != nextMessage.senderId;
  }

  Future<void> launchUrl(Uri url) async {
    try {
      if (await url_launcher.canLaunchUrl(url)) {
        await url_launcher.launchUrl(
          url,
          mode: url_launcher.LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Không thể mở URL');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể mở liên kết: $e')),
        );
      }
    }
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showAvatar;
  final String? avatarUrl;
  final VoidCallback onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.showAvatar,
    this.avatarUrl,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe ? Colors.blue[900] : Colors.grey[200];
    final textColor = isMe ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (showAvatar && !isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[200],
              backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(avatarUrl!)
                  : null,
              child: avatarUrl == null || avatarUrl!.isEmpty
                  ? const Icon(Icons.person, size: 16, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _buildMessageContent(context, textColor),
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 4),
            Icon(
              message.isRead ? Icons.done_all : Icons.done,
              size: 14,
              color: message.isRead ? Colors.blue : Colors.grey,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, Color textColor) {
    if (message.isImage()) {
      return _buildImageMessage(context);
    } else if (message.isFile()) {
      return _buildFileMessage(context);
    } else {
      return _buildTextMessage(textColor);
    }
  }

  Widget _buildTextMessage(Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            message.text!,
            style: TextStyle(color: textColor),
          ),
          const SizedBox(height: 2),
          Text(
            DateFormat('HH:mm').format(message.timestamp),
            style: TextStyle(
              fontSize: 10,
              color: isMe ? Colors.white70 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageMessage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: GestureDetector(
            onTap: () {
              _showFullScreenImage(context, message.imageUrl!);
            },
            child: CachedNetworkImage(
              imageUrl: message.imageUrl!,
              fit: BoxFit.cover,
              width: MediaQuery.of(context).size.width * 0.6,
              placeholder: (context, url) => const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => const SizedBox(
                height: 150,
                width: 200,
                child: Center(child: Icon(Icons.error)),
              ),
            ),
          ),
        ),
        Container(
          width: MediaQuery.of(context).size.width * 0.6,
          padding: const EdgeInsets.only(right: 8, bottom: 6, top: 4),
          child: Text(
            DateFormat('HH:mm').format(message.timestamp),
            style: TextStyle(
              fontSize: 10,
              color: isMe ? Colors.white70 : Colors.grey,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildFileMessage(BuildContext context) {
    final textColor = isMe ? Colors.white : Colors.black87;
    final subtitleColor = isMe ? Colors.white70 : Colors.black54;
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue[800] : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.insert_drive_file, size: 36, color: Colors.white),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.fileName ?? 'Tập tin',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message.getReadableFileSize(),
                        style: TextStyle(
                          fontSize: 12,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.download, 
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    // Xử lý tải xuống tập tin
                    _openFileUrl(context, message.fileUrl!);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 4, left: 8),
            child: Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openFileUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await url_launcher.canLaunchUrl(uri)) {
        await url_launcher.launchUrl(
          uri,
          mode: url_launcher.LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Không thể mở URL');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể mở tập tin: $e')),
        );
      }
    }
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 