import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:student_market_nttu/models/chat.dart';
import 'package:student_market_nttu/models/chat_message_detail.dart';
import 'package:student_market_nttu/models/user.dart';
import 'package:student_market_nttu/services/user_service.dart';
import 'package:student_market_nttu/services/firebase_messaging_service.dart';

class ChatService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Lưu cache các cuộc trò chuyện
  Map<String, Chat> _chats = {};
  Map<String, List<ChatMessageDetail>> _messages = {};

  // Getter
  Map<String, Chat> get chats => _chats;
  String get currentUserId => _auth.currentUser?.uid ?? '';

  // Khởi tạo dữ liệu chat
  Future<void> initializeChats() async {
    if (currentUserId.isEmpty) return;

    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .orderBy('lastMessageAt', descending: true)
          .limit(20)
          .get();

      for (var doc in querySnapshot.docs) {
        final chat = Chat.fromMap(doc.data(), doc.id);
        _chats[chat.id] = chat;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Lỗi khi khởi tạo dữ liệu chat: $e');
    }
  }

  // Tạo mới hoặc lấy cuộc trò chuyện hiện có
  Future<String> createOrGetChat(String otherUserId) async {
    if (currentUserId.isEmpty) {
      throw Exception('Người dùng chưa đăng nhập');
    }

    if (currentUserId == otherUserId) {
      throw Exception('Không thể chat với chính mình');
    }

    try {
      // Kiểm tra xem cuộc trò chuyện đã tồn tại chưa
      final querySnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      // Tìm chat có cả 2 người tham gia
      for (var doc in querySnapshot.docs) {
        final chat = Chat.fromMap(doc.data(), doc.id);
        if (chat.participants.contains(otherUserId)) {
          return chat.id;
        }
      }

      // Nếu không tìm thấy, tạo mới
      final chatId = const Uuid().v4();
      final now = DateTime.now();
      
      final newChat = Chat(
        id: chatId,
        participants: [currentUserId, otherUserId],
        createdAt: now,
        lastMessageAt: now,
        read: {
          currentUserId: true,
          otherUserId: true,
        },
        unreadCount: {
          currentUserId: 0,
          otherUserId: 0,
        },
      );

      await _firestore.collection('chats').doc(chatId).set(newChat.toMap());
      _chats[chatId] = newChat;
      notifyListeners();
      
      return chatId;
    } catch (e) {
      debugPrint('Lỗi khi tạo/lấy chat: $e');
      throw Exception('Không thể tạo hoặc lấy cuộc trò chuyện. Vui lòng thử lại sau.');
    }
  }

  // Lấy danh sách cuộc trò chuyện của người dùng hiện tại
  Stream<List<Chat>> getUserChats() {
    if (currentUserId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final chatList = snapshot.docs
              .map((doc) => Chat.fromMap(doc.data(), doc.id))
              .toList();
          
          // Cập nhật cache
          for (var chat in chatList) {
            _chats[chat.id] = chat;
          }
          
          notifyListeners();
          return chatList;
        });
  }

  // Lấy thông tin chi tiết của một cuộc trò chuyện
  Stream<Chat> getChatById(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            throw Exception('Cuộc trò chuyện không tồn tại');
          }
          
          final chat = Chat.fromMap(doc.data()!, doc.id);
          _chats[chatId] = chat;
          return chat;
        });
  }

  // Lấy danh sách tin nhắn từ một cuộc trò chuyện
  Stream<List<ChatMessageDetail>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          final messageList = snapshot.docs
              .map((doc) => ChatMessageDetail.fromMap(doc.data(), doc.id))
              .toList();
          
          // Cập nhật cache
          _messages[chatId] = messageList;
          
          return messageList;
        });
  }

  // Đánh dấu đã đọc tin nhắn
  Future<void> markAsRead(String chatId) async {
    if (currentUserId.isEmpty) return;

    try {
      // Cập nhật trạng thái đọc của cuộc trò chuyện
      await _firestore.collection('chats').doc(chatId).update({
        'read.$currentUserId': true,
        'unreadCount.$currentUserId': 0,
      });

      // Cập nhật tất cả tin nhắn chưa đọc
      final unreadMessages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('read.$currentUserId', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'read.$currentUserId': true,
        });
      }
      
      await batch.commit();
      notifyListeners();
    } catch (e) {
      debugPrint('Lỗi khi đánh dấu đã đọc: $e');
    }
  }

  // Gửi tin nhắn văn bản
  Future<void> sendTextMessage(String chatId, String content) async {
    if (currentUserId.isEmpty || content.trim().isEmpty) return;

    try {
      final chat = _chats[chatId];
      if (chat == null) {
        throw Exception('Không tìm thấy cuộc trò chuyện');
      }

      final messageId = const Uuid().v4();
      final now = DateTime.now();
      
      // Khởi tạo Map read với tất cả người tham gia đều chưa đọc (trừ người gửi)
      final Map<String, bool> readStatus = {};
      final Map<String, int> unreadCount = {};
      
      // ID của người nhận
      String? receiverId;
      
      for (var userId in chat.participants) {
        if (userId == currentUserId) {
          readStatus[userId] = true;
          unreadCount[userId] = 0;
        } else {
          receiverId = userId;
          readStatus[userId] = false;
          // Tăng số tin nhắn chưa đọc cho người nhận
          unreadCount[userId] = (chat.unreadCount[userId] ?? 0) + 1;
        }
      }

      // Tạo tin nhắn mới
      final message = ChatMessageDetail(
        id: messageId,
        chatId: chatId,
        senderId: currentUserId,
        content: content,
        timestamp: now,
        type: ChatMessageType.text,
        read: readStatus,
      );

      // Cập nhật thông tin cuộc trò chuyện
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessageAt': Timestamp.fromDate(now),
        'lastMessage': {
          'content': content,
          'senderId': currentUserId,
          'type': 'text',
          'timestamp': Timestamp.fromDate(now),
        },
        'read': readStatus,
        'unreadCount': unreadCount,
      });

      // Lưu tin nhắn
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());

      // Gửi thông báo cho người nhận
      if (receiverId != null) {
        // Lấy thông tin người gửi
        final senderDoc = await _firestore.collection('users').doc(currentUserId).get();
        final senderName = senderDoc.data()?['displayName'] ?? 'Người dùng';
        
        // Gửi thông báo
        await FirebaseMessagingService.sendNotificationToUser(
          targetUserId: receiverId,
          title: senderName,
          body: content,
          data: {
            'type': 'chat_message',
            'chatId': chatId,
            'senderId': currentUserId,
            'timestamp': now.millisecondsSinceEpoch.toString(),
          },
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Lỗi khi gửi tin nhắn: $e');
      throw Exception('Không thể gửi tin nhắn. Vui lòng thử lại sau.');
    }
  }

  // Gửi tin nhắn hình ảnh
  Future<void> sendImageMessage(String chatId, XFile imageFile) async {
    if (currentUserId.isEmpty) return;

    try {
      final chat = _chats[chatId];
      if (chat == null) {
        throw Exception('Không tìm thấy cuộc trò chuyện');
      }

      final messageId = const Uuid().v4();
      final now = DateTime.now();
      
      // Tạo tham chiếu đến nơi lưu trữ hình ảnh
      final fileName = '${path.basename(imageFile.path)}_${DateTime.now().millisecondsSinceEpoch}';
      final ref = _storage.ref().child('chat_images/$chatId/$fileName');
      
      // Upload hình ảnh
      final file = File(imageFile.path);
      final uploadTask = await ref.putFile(file);
      final imageUrl = await uploadTask.ref.getDownloadURL();
      
      // Khởi tạo Map read với tất cả người tham gia đều chưa đọc (trừ người gửi)
      final Map<String, bool> readStatus = {};
      final Map<String, int> unreadCount = {};
      
      // ID của người nhận
      String? receiverId;
      
      for (var userId in chat.participants) {
        if (userId == currentUserId) {
          readStatus[userId] = true;
          unreadCount[userId] = 0;
        } else {
          receiverId = userId;
          readStatus[userId] = false;
          unreadCount[userId] = (chat.unreadCount[userId] ?? 0) + 1;
        }
      }

      // Tạo tin nhắn mới
      final message = ChatMessageDetail(
        id: messageId,
        chatId: chatId,
        senderId: currentUserId,
        content: 'Đã gửi hình ảnh',
        timestamp: now,
        type: ChatMessageType.image,
        metadata: {'url': imageUrl},
        read: readStatus,
      );

      // Cập nhật thông tin cuộc trò chuyện
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessageAt': Timestamp.fromDate(now),
        'lastMessage': {
          'content': 'Đã gửi hình ảnh',
          'senderId': currentUserId,
          'type': 'image',
          'timestamp': Timestamp.fromDate(now),
        },
        'read': readStatus,
        'unreadCount': unreadCount,
      });

      // Lưu tin nhắn
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());

      // Gửi thông báo cho người nhận
      if (receiverId != null) {
        // Lấy thông tin người gửi
        final senderDoc = await _firestore.collection('users').doc(currentUserId).get();
        final senderName = senderDoc.data()?['displayName'] ?? 'Người dùng';
        
        // Gửi thông báo
        await FirebaseMessagingService.sendNotificationToUser(
          targetUserId: receiverId,
          title: senderName,
          body: 'Đã gửi hình ảnh',
          data: {
            'type': 'chat_message',
            'chatId': chatId,
            'senderId': currentUserId,
            'timestamp': now.millisecondsSinceEpoch.toString(),
          },
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Lỗi khi gửi hình ảnh: $e');
      throw Exception('Không thể gửi hình ảnh. Vui lòng thử lại sau.');
    }
  }

  // Tính tổng số tin nhắn chưa đọc
  Future<int> getTotalUnreadCount() async {
    if (currentUserId.isEmpty) return 0;

    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      int total = 0;
      for (var doc in querySnapshot.docs) {
        final chat = Chat.fromMap(doc.data(), doc.id);
        total += chat.unreadCount[currentUserId] ?? 0;
      }
      
      return total;
    } catch (e) {
      debugPrint('Lỗi khi tính tổng tin nhắn chưa đọc: $e');
      return 0;
    }
  }

  // Gửi tin nhắn về sản phẩm
  Future<void> sendProductMessage(String chatId, String productId, String productName, String imageUrl, String price) async {
    if (currentUserId.isEmpty) return;

    try {
      final chat = _chats[chatId];
      if (chat == null) {
        throw Exception('Không tìm thấy cuộc trò chuyện');
      }

      final messageId = const Uuid().v4();
      final now = DateTime.now();
      
      // Khởi tạo Map read với tất cả người tham gia đều chưa đọc (trừ người gửi)
      final Map<String, bool> readStatus = {};
      final Map<String, int> unreadCount = {};
      
      for (var userId in chat.participants) {
        if (userId == currentUserId) {
          readStatus[userId] = true;
          unreadCount[userId] = 0;
        } else {
          readStatus[userId] = false;
          unreadCount[userId] = (chat.unreadCount[userId] ?? 0) + 1;
        }
      }

      // Tạo tin nhắn mới
      final message = ChatMessageDetail(
        id: messageId,
        chatId: chatId,
        senderId: currentUserId,
        content: 'Đã gửi thông tin sản phẩm: $productName',
        timestamp: now,
        type: ChatMessageType.product,
        metadata: {
          'productId': productId,
          'productName': productName,
          'imageUrl': imageUrl,
          'price': price,
        },
        read: readStatus,
      );

      // Cập nhật thông tin cuộc trò chuyện
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessageAt': Timestamp.fromDate(now),
        'lastMessage': {
          'content': 'Đã gửi thông tin sản phẩm: $productName',
          'senderId': currentUserId,
          'type': 'product',
          'timestamp': Timestamp.fromDate(now),
        },
        'read': readStatus,
        'unreadCount': unreadCount,
      });

      // Lưu tin nhắn
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());

      notifyListeners();
    } catch (e) {
      debugPrint('Lỗi khi gửi thông tin sản phẩm: $e');
      throw Exception('Không thể gửi thông tin sản phẩm. Vui lòng thử lại sau.');
    }
  }

  // Lấy thông tin người dùng khác trong cuộc trò chuyện
  Future<UserModel?> getOtherUserInChat(String chatId, BuildContext context) async {
    try {
      var chat = _chats[chatId];
      if (chat == null) {
        // Lấy chat từ Firestore nếu chưa có trong cache
        final doc = await _firestore.collection('chats').doc(chatId).get();
        if (!doc.exists) {
          return null;
        }
        
        chat = Chat.fromMap(doc.data()!, chatId);
        _chats[chatId] = chat;
      }
      
      // Lấy ID của người dùng khác trong cuộc trò chuyện
      final otherUserId = chat.participants.firstWhere(
        (id) => id != currentUserId,
        orElse: () => '',
      );
      
      if (otherUserId.isEmpty) {
        return null;
      }
      
      // Lấy thông tin người dùng
      final userService = Provider.of<UserService>(context, listen: false);
      return await userService.getUserById(otherUserId);
    } catch (e) {
      debugPrint('Lỗi khi lấy thông tin người dùng khác: $e');
      return null;
    }
  }

  // Xóa tin nhắn (chỉ của người dùng hiện tại)
  Future<void> deleteMessage(String chatId, String messageId) async {
    if (currentUserId.isEmpty) return;

    try {
      // Lấy message từ Firestore
      final doc = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .get();
      
      if (!doc.exists) {
        throw Exception('Tin nhắn không tồn tại');
      }
      
      final message = ChatMessageDetail.fromMap(doc.data()!, messageId);
      
      // Chỉ người gửi mới có thể xóa tin nhắn
      if (message.senderId != currentUserId) {
        throw Exception('Bạn không có quyền xóa tin nhắn này');
      }
      
      // Xóa tin nhắn
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
      
      // Cập nhật cache
      _messages[chatId]?.removeWhere((msg) => msg.id == messageId);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Lỗi khi xóa tin nhắn: $e');
      throw Exception('Không thể xóa tin nhắn. Vui lòng thử lại sau.');
    }
  }
} 