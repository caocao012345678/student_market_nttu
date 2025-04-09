import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String? text;
  final String? imageUrl;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String type;
  final DateTime timestamp;
  final bool isRead;
  final List<String> deletedFor;

  ChatMessage({
    required this.id,
    required this.senderId,
    this.text,
    this.imageUrl,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.deletedFor = const [],
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      text: map['text'],
      imageUrl: map['imageUrl'],
      fileUrl: map['fileUrl'],
      fileName: map['fileName'],
      fileSize: map['fileSize'],
      type: map['type'] ?? 'text',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      deletedFor: List<String>.from(map['deletedFor'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'deletedFor': deletedFor,
    };
  }

  bool get isVisible {
    return !deletedFor.contains(senderId);
  }

  bool isImage() {
    return type == 'image';
  }

  bool isFile() {
    return type == 'file';
  }

  String getReadableFileSize() {
    if (fileSize == null) return '0 B';
    
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = fileSize!.toDouble();
    int unitIndex = 0;
    
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    
    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? text,
    String? imageUrl,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? type,
    DateTime? timestamp,
    bool? isRead,
    List<String>? deletedFor,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      deletedFor: deletedFor ?? this.deletedFor,
    );
  }
} 