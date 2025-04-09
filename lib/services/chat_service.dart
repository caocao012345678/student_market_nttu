import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'dart:io';

class ChatService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Lấy danh sách chat của người dùng hiện tại
  Stream<QuerySnapshot> getChats() {
    if (currentUserId == null) {
      return const Stream.empty();
    }
    
    return _firestore
        .collection('chats')
        .where('participantsArray', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }
  
  // Lấy tin nhắn của một cuộc trò chuyện
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
  
  // Tạo hoặc lấy chat giữa người dùng hiện tại và người dùng khác
  Future<String> getChatId(String otherUserId) async {
    if (currentUserId == null) {
      throw Exception('Người dùng chưa đăng nhập');
    }
    
    // Sắp xếp ID để đảm bảo chat ID nhất quán
    final List<String> ids = [currentUserId!, otherUserId];
    ids.sort();
    
    // Kiểm tra xem cuộc trò chuyện đã tồn tại chưa
    final chatQuery = await _firestore
        .collection('chats')
        .where('participantsArray', arrayContains: currentUserId)
        .get();
    
    // Tìm cuộc trò chuyện có cả người dùng hiện tại và người dùng khác
    for (final doc in chatQuery.docs) {
      final data = doc.data();
      final List<String> participants = List<String>.from(data['participantsArray'] ?? []);
      if (participants.contains(otherUserId)) {
        return doc.id;
      }
    }
    
    // Tạo cuộc trò chuyện mới
    final chatDoc = _firestore.collection('chats').doc();
    await chatDoc.set({
      'participants': {
        currentUserId!: true,
        otherUserId: true,
      },
      'participantsArray': ids,
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    return chatDoc.id;
  }
  
  // Gửi tin nhắn văn bản
  Future<void> sendMessage(String chatId, String message) async {
    if (currentUserId == null) {
      throw Exception('Người dùng chưa đăng nhập');
    }
    
    if (message.trim().isEmpty) {
      return;
    }
    
    // Thêm tin nhắn vào subcollection messages
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'text': message,
      'type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
    
    // Cập nhật thông tin tin nhắn gần nhất
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': currentUserId,
    });
  }
  
  // Gửi tin nhắn hình ảnh
  Future<void> sendImageMessage(String chatId, XFile image) async {
    if (currentUserId == null) {
      throw Exception('Người dùng chưa đăng nhập');
    }
    
    // Tạo reference đến storage
    final String fileName = '${const Uuid().v4()}${path.extension(image.path)}';
    final Reference ref = _storage.ref().child('chat_images/$chatId/$fileName');
    
    // Upload hình ảnh
    final UploadTask uploadTask = ref.putData(await image.readAsBytes());
    final TaskSnapshot snapshot = await uploadTask;
    final String downloadUrl = await snapshot.ref.getDownloadURL();
    
    // Thêm tin nhắn hình ảnh vào subcollection messages
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'imageUrl': downloadUrl,
      'type': 'image',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
    
    // Cập nhật thông tin tin nhắn gần nhất
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': '📷 Hình ảnh',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': currentUserId,
    });
  }
  
  // Gửi tin nhắn tập tin
  Future<void> sendFileMessage(String chatId, File file, String fileName) async {
    if (currentUserId == null) {
      throw Exception('Người dùng chưa đăng nhập');
    }
    
    // Tạo reference đến storage
    final String uniqueFileName = '${const Uuid().v4()}__${fileName}';
    final Reference ref = _storage.ref().child('chat_files/$chatId/$uniqueFileName');
    
    // Upload tập tin
    final UploadTask uploadTask = ref.putFile(file);
    final TaskSnapshot snapshot = await uploadTask;
    final String downloadUrl = await snapshot.ref.getDownloadURL();
    
    // Lấy kích thước file để hiển thị
    final int fileSize = await file.length();
    
    // Thêm tin nhắn tập tin vào subcollection messages
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': currentUserId,
      'fileUrl': downloadUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'type': 'file',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
    
    // Cập nhật thông tin tin nhắn gần nhất
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': '📎 Tập tin: $fileName',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': currentUserId,
    });
  }
  
  // Đánh dấu tin nhắn đã đọc
  Future<void> markMessagesAsRead(String chatId, String senderId) async {
    if (currentUserId == null || currentUserId == senderId) {
      return;
    }
    
    final messages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isEqualTo: senderId)
        .where('isRead', isEqualTo: false)
        .get();
    
    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    
    await batch.commit();
  }
  
  // Xóa tin nhắn (chỉ xóa phía người gửi)
  Future<void> deleteMessage(String chatId, String messageId) async {
    if (currentUserId == null) {
      throw Exception('Người dùng chưa đăng nhập');
    }
    
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'deletedFor': FieldValue.arrayUnion([currentUserId]),
    });
  }
  
  // Lấy thông tin người dùng khác trong cuộc trò chuyện
  Future<DocumentSnapshot> getOtherUserInfo(String userId) {
    return _firestore.collection('users').doc(userId).get();
  }
} 