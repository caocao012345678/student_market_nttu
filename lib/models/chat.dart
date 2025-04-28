import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final List<String> participants; // danh sách user ids
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final Map<String, dynamic>? lastMessage; // lưu tin nhắn cuối cùng để hiển thị trong danh sách chat
  final Map<String, bool> read; // Theo dõi xem từng người dùng đã đọc tin nhắn mới nhất hay chưa
  final Map<String, int> unreadCount; // Số tin nhắn chưa đọc cho mỗi người dùng

  Chat({
    required this.id,
    required this.participants,
    required this.createdAt,
    required this.lastMessageAt,
    this.lastMessage,
    required this.read,
    required this.unreadCount,
  });

  factory Chat.fromMap(Map<String, dynamic> map, String id) {
    return Chat(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastMessageAt: (map['lastMessageAt'] as Timestamp).toDate(),
      lastMessage: map['lastMessage'] as Map<String, dynamic>?,
      read: Map<String, bool>.from(map['read'] ?? {}),
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'lastMessage': lastMessage,
      'read': read,
      'unreadCount': unreadCount,
    };
  }

  Chat copyWith({
    String? id,
    List<String>? participants,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    Map<String, dynamic>? lastMessage,
    Map<String, bool>? read,
    Map<String, int>? unreadCount,
  }) {
    return Chat(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessage: lastMessage ?? this.lastMessage,
      read: read ?? this.read,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
} 