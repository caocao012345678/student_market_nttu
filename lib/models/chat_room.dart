import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final Map<String, dynamic> participants;
  final List<String> participantsArray;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String? lastMessageSenderId;
  final DateTime createdAt;

  ChatRoom({
    required this.id,
    required this.participants,
    required this.participantsArray,
    this.lastMessage = '',
    required this.lastMessageTime,
    this.lastMessageSenderId,
    required this.createdAt,
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map, String id) {
    Map<String, dynamic> participantsMap = {};
    try {
      participantsMap = Map<String, dynamic>.from(map['participants'] ?? {});
    } catch (e) {
      // Xử lý trường hợp participants không phải là Map
      participantsMap = {};
    }

    List<String> participantsArray = [];
    try {
      participantsArray = List<String>.from(map['participantsArray'] ?? []);
    } catch (e) {
      // Xử lý trường hợp participantsArray không phải là List
      participantsArray = [];
    }

    return ChatRoom(
      id: id,
      participants: participantsMap,
      participantsArray: participantsArray,
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageSenderId: map['lastMessageSenderId'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'participantsArray': participantsArray,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessageSenderId': lastMessageSenderId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  String getOtherUserId(String currentUserId) {
    try {
      return participantsArray.firstWhere((id) => id != currentUserId, 
        orElse: () => '');
    } catch (e) {
      return '';
    }
  }

  bool hasUser(String userId) {
    return participantsArray.contains(userId);
  }

  ChatRoom copyWith({
    String? id,
    Map<String, dynamic>? participants,
    List<String>? participantsArray,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    DateTime? createdAt,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      participantsArray: participantsArray ?? this.participantsArray,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 