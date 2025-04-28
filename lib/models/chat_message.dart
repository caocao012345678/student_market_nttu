import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  file,
  product,
  productList,
  help,
  location,
}

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final MessageType type;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.type = MessageType.text,
    this.metadata,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    MessageType messageType = MessageType.text;
    if (map['type'] == 'product') {
      messageType = MessageType.product;
    } else if (map['type'] == 'help') {
      messageType = MessageType.help;
    }

    return ChatMessage(
      id: id,
      content: map['content'] ?? '',
      isUser: map['isUser'] ?? true,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      type: messageType,
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    String typeString = 'text';
    if (type == MessageType.product) typeString = 'product';
    else if (type == MessageType.help) typeString = 'help';

    return {
      'content': content,
      'isUser': isUser,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': typeString,
      'metadata': metadata,
    };
  }
} 