import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:student_market_nttu/services/firebase_messaging_service.dart';

class NotificationType {
  static const String order = 'order';
  static const String chat = 'chat';
  static const String product = 'product';
  static const String system = 'system';
  static const String promo = 'promo';
}

class Notification {
  final String id;
  final String userId; // Người nhận thông báo
  final String title;
  final String body;
  final String type; // Loại thông báo: order, chat, product, system, promo...
  final Map<String, dynamic>? data; // Dữ liệu bổ sung: chatId, orderId, productId...
  final DateTime createdAt;
  final bool isRead;

  Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    required this.createdAt,
    this.isRead = false,
  });

  factory Notification.fromMap(Map<String, dynamic> map, String id) {
    return Notification(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? '',
      data: map['data'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  Notification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

class NotificationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Lưu cache thông báo
  List<Notification> _notifications = [];
  int _unreadCount = 0;
  
  // Getter
  List<Notification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  String get currentUserId => _auth.currentUser?.uid ?? '';

  // Theo dõi các yêu cầu đang xử lý để tránh trùng lặp
  final Map<String, Completer<void>> _pendingRequests = {};

  // Khởi tạo dữ liệu thông báo
  Future<void> initializeNotifications() async {
    if (currentUserId.isEmpty) return;

    // Nếu đang xử lý, không thực hiện lại
    if (_pendingRequests['init'] != null) {
      await _pendingRequests['init']!.future;
      return;
    }

    final completer = Completer<void>();
    _pendingRequests['init'] = completer;

    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get()
          .timeout(const Duration(seconds: 10), onTimeout: () {
            throw TimeoutException('Tải dữ liệu thông báo quá thời gian, vui lòng thử lại sau');
          });

      _notifications = querySnapshot.docs
          .map((doc) => Notification.fromMap(doc.data(), doc.id))
          .toList();
      
      _updateUnreadCount();
      notifyListeners();
      completer.complete();
    } catch (e) {
      debugPrint('Lỗi khi khởi tạo dữ liệu thông báo: $e');
      completer.completeError(e);
      throw e;
    } finally {
      _pendingRequests.remove('init');
    }
  }

  // Lấy danh sách thông báo của người dùng hiện tại
  Stream<List<Notification>> getUserNotifications() {
    if (currentUserId.isEmpty) {
      return Stream.value([]);
    }

    // Sử dụng biến static để kiểm soát thời gian refresh
    final Map<String, DateTime> _lastRefreshTimes = {};
    final now = DateTime.now();
    
    // Nếu đã tải thông báo trong 3 giây gần đây, trả về cache
    if (_lastRefreshTimes.containsKey(currentUserId) && 
        now.difference(_lastRefreshTimes[currentUserId]!).inSeconds < 3 &&
        _notifications.isNotEmpty) {
      return Stream.value(_notifications);
    }
    
    _lastRefreshTimes[currentUserId] = now;

    // Sử dụng BehaviorSubject để caching kết quả snapshot gần nhất
    final controller = StreamController<List<Notification>>();
    
    // Thêm cache hiện tại vào stream ngay lập tức nếu có
    if (_notifications.isNotEmpty) {
      controller.add(_notifications);
    }

    // Đăng ký theo dõi thay đổi từ Firestore
    final subscription = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen(
          (snapshot) {
            final newNotifications = snapshot.docs
                .map((doc) => Notification.fromMap(doc.data(), doc.id))
                .toList();
            
            // Kiểm tra xem dữ liệu có thay đổi không
            if (_hasNotificationsChanged(_notifications, newNotifications)) {
              _notifications = newNotifications;
              _updateUnreadCount();
              notifyListeners();
              controller.add(_notifications);
            }
          },
          onError: (error) {
            debugPrint('Lỗi khi lấy danh sách thông báo: $error');
            // Không throw lỗi nếu đã có cache
            if (_notifications.isEmpty) {
              controller.addError(error);
            }
          },
        );

    // Đóng controller và hủy subscription khi stream bị đóng
    controller.onCancel = () {
      subscription.cancel();
      controller.close();
    };

    return controller.stream;
  }
  
  // Kiểm tra xem danh sách thông báo có thay đổi không
  bool _hasNotificationsChanged(List<Notification> oldList, List<Notification> newList) {
    // Nếu số lượng khác nhau, chắc chắn đã thay đổi
    if (oldList.length != newList.length) return true;
    
    // Nếu danh sách rỗng, không có thay đổi
    if (oldList.isEmpty && newList.isEmpty) return false;
    
    // So sánh thông báo mới nhất
    if (oldList.isNotEmpty && newList.isNotEmpty) {
      return oldList[0].id != newList[0].id || 
             oldList[0].isRead != newList[0].isRead;
    }
    
    return true;
  }

  // Đánh dấu đã đọc thông báo
  Future<void> markAsRead(String notificationId) async {
    if (currentUserId.isEmpty) return;
    
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });

      // Cập nhật cache
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _updateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Lỗi khi đánh dấu đã đọc thông báo: $e');
      throw Exception('Không thể đánh dấu đã đọc thông báo. Vui lòng thử lại sau.');
    }
  }

  // Đánh dấu đã đọc tất cả thông báo
  Future<void> markAllAsRead() async {
    if (currentUserId.isEmpty) return;
    
    try {
      final batch = _firestore.batch();
      final unreadNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();

      // Cập nhật cache
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Lỗi khi đánh dấu đã đọc tất cả thông báo: $e');
      throw Exception('Không thể đánh dấu đã đọc tất cả thông báo. Vui lòng thử lại sau.');
    }
  }

  // Tạo thông báo mới
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
    bool sendPush = true,
  }) async {
    try {
      final notificationId = const Uuid().v4();
      final now = DateTime.now();
      
      final notification = Notification(
        id: notificationId,
        userId: userId,
        title: title,
        body: body,
        type: type,
        data: data,
        createdAt: now,
        isRead: false,
      );

      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .set(notification.toMap());

      // Gửi thông báo đẩy nếu yêu cầu
      if (sendPush) {
        await FirebaseMessagingService.sendNotificationToUser(
          targetUserId: userId,
          title: title,
          body: body,
          data: {
            'type': type,
            'notificationId': notificationId,
            ...data ?? {},
          },
        );
      }

      // Cập nhật cache nếu thông báo là của người dùng hiện tại
      if (userId == currentUserId) {
        _notifications.insert(0, notification);
        _updateUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Lỗi khi tạo thông báo: $e');
      throw Exception('Không thể tạo thông báo. Vui lòng thử lại sau.');
    }
  }

  // Xóa thông báo
  Future<void> deleteNotification(String notificationId) async {
    if (currentUserId.isEmpty) return;
    
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();

      // Cập nhật cache
      _notifications.removeWhere((n) => n.id == notificationId);
      _updateUnreadCount();
      notifyListeners();
    } catch (e) {
      debugPrint('Lỗi khi xóa thông báo: $e');
      throw Exception('Không thể xóa thông báo. Vui lòng thử lại sau.');
    }
  }

  // Xóa tất cả thông báo
  Future<void> deleteAllNotifications() async {
    if (currentUserId.isEmpty) return;
    
    try {
      final batch = _firestore.batch();
      final userNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUserId)
          .get();

      for (var doc in userNotifications.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();

      // Cập nhật cache
      _notifications = [];
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Lỗi khi xóa tất cả thông báo: $e');
      throw Exception('Không thể xóa tất cả thông báo. Vui lòng thử lại sau.');
    }
  }

  // Tạo thông báo chat
  Future<void> createChatNotification({
    required String receiverId,
    required String senderId,
    required String chatId,
    required String senderName,
    required String message,
  }) async {
    await createNotification(
      userId: receiverId,
      title: senderName,
      body: message,
      type: NotificationType.chat,
      data: {
        'chatId': chatId,
        'senderId': senderId,
      },
    );
  }

  // Tạo thông báo đơn hàng
  Future<void> createOrderNotification({
    required String userId,
    required String orderId,
    required String title,
    required String body,
  }) async {
    await createNotification(
      userId: userId,
      title: title,
      body: body,
      type: NotificationType.order,
      data: {'orderId': orderId},
    );
  }

  // Tạo thông báo sản phẩm
  Future<void> createProductNotification({
    required String userId,
    required String productId,
    required String title,
    required String body,
  }) async {
    await createNotification(
      userId: userId,
      title: title,
      body: body,
      type: NotificationType.product,
      data: {'productId': productId},
    );
  }

  // Tạo thông báo khi có người nhắn tin hỏi về sản phẩm
  Future<void> createChatProductNotification({
    required String userId,
    required String chatId,
    required String senderId,
    required String senderName,
    required String productId,
    required String productTitle,
    required String message,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Có người hỏi về sản phẩm của bạn',
      body: '$senderName: $message',
      type: NotificationType.chat,
      data: {
        'chatId': chatId,
        'senderId': senderId,
        'productId': productId,
        'productTitle': productTitle,
      },
    );
  }

  // Cập nhật số lượng thông báo chưa đọc
  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }
} 