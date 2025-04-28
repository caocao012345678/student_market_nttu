import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatMessageType {
  text,
  image,
  file,
  product,
  location,
  audio,
  video,
}

class ChatMessageDetail {
  final String id;
  final String chatId; // ID của cuộc trò chuyện
  final String senderId; // ID của người gửi
  final String content; // Nội dung tin nhắn
  final DateTime timestamp; // Thời gian gửi
  final ChatMessageType type; // Loại tin nhắn
  final Map<String, dynamic>? metadata; // Dữ liệu bổ sung (URL hình ảnh, thông tin sản phẩm...)
  final Map<String, bool> read; // Theo dõi từng người dùng đã đọc tin nhắn hay chưa

  ChatMessageDetail({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.type = ChatMessageType.text,
    this.metadata,
    required this.read,
  });

  factory ChatMessageDetail.fromMap(Map<String, dynamic> map, String id) {
    ChatMessageType messageType = ChatMessageType.text;
    
    switch (map['type']) {
      case 'image':
        messageType = ChatMessageType.image;
        break;
      case 'file':
        messageType = ChatMessageType.file;
        break;
      case 'product':
        messageType = ChatMessageType.product;
        break;
      case 'location':
        messageType = ChatMessageType.location;
        break;
      case 'audio':
        messageType = ChatMessageType.audio;
        break;
      case 'video':
        messageType = ChatMessageType.video;
        break;
      default:
        messageType = ChatMessageType.text;
    }

    return ChatMessageDetail(
      id: id,
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      content: map['content'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      type: messageType,
      metadata: map['metadata'],
      read: Map<String, bool>.from(map['read'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    String typeString;
    
    switch (type) {
      case ChatMessageType.image:
        typeString = 'image';
        break;
      case ChatMessageType.file:
        typeString = 'file';
        break;
      case ChatMessageType.product:
        typeString = 'product';
        break;
      case ChatMessageType.location:
        typeString = 'location';
        break;
      case ChatMessageType.audio:
        typeString = 'audio';
        break;
      case ChatMessageType.video:
        typeString = 'video';
        break;
      default:
        typeString = 'text';
    }

    return {
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': typeString,
      'metadata': metadata,
      'read': read,
    };
  }

  ChatMessageDetail copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? content,
    DateTime? timestamp,
    ChatMessageType? type,
    Map<String, dynamic>? metadata,
    Map<String, bool>? read,
  }) {
    return ChatMessageDetail(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
      read: read ?? this.read,
    );
  }
} 