import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_functions/cloud_functions.dart';

class FirebaseMessagingService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;
  
  // Khởi tạo dịch vụ thông báo
  static Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;
    
    // Yêu cầu quyền thông báo trên cả hai nền tảng
    await _requestNotificationPermissions();

    // Khởi tạo kênh thông báo cục bộ cho Android
    await _initializeLocalNotifications(context);

    // Xử lý khi nhận thông báo trong foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Nhận thông báo trong foreground: ${message.notification?.title}');
      _showNotification(message);
    });

    // Xử lý khi nhấn vào thông báo để mở ứng dụng từ terminated state
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('Nhấn thông báo từ terminated state');
        _handleNotificationTap(json.encode(message.data), context);
      }
    });

    // Xử lý khi nhấn vào thông báo để mở ứng dụng từ background state
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Nhấn thông báo từ background state');
      _handleNotificationTap(json.encode(message.data), context);
    });

    // Đăng ký token mới mỗi khi token thay đổi
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      debugPrint('FCM Token mới: $token');
      _saveTokenToFirestore(token);
    });

    // Set foreground notification presentation options
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Lấy và lưu token hiện tại
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      debugPrint('FCM Token hiện tại: $token');
      await _saveTokenToFirestore(token);
    } else {
      debugPrint('Không thể lấy FCM Token');
    }
    
    _isInitialized = true;
  }
  
  // Yêu cầu quyền thông báo
  static Future<void> _requestNotificationPermissions() async {
    try {
      // Yêu cầu quyền firebase messaging
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: false,
      );
      
      debugPrint('Trạng thái quyền thông báo: ${settings.authorizationStatus}');
      
      // Yêu cầu quyền thông báo trên Android 13+
      if (Platform.isAndroid) {
        final status = await Permission.notification.status;
        debugPrint('Trạng thái quyền thông báo Android: $status');
        
        if (status != PermissionStatus.granted) {
          final result = await Permission.notification.request();
          debugPrint('Kết quả yêu cầu quyền thông báo: $result');
        }
      }
    } catch (e) {
      debugPrint('Lỗi khi yêu cầu quyền thông báo: $e');
    }
  }

  // Khởi tạo thông báo cục bộ
  static Future<void> _initializeLocalNotifications(BuildContext context) async {
    // Cấu hình cho Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Cấu hình cho iOS
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    
    // Khởi tạo cấu hình
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    // Khởi tạo plugin
    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Nhấn thông báo cục bộ: ${response.payload}');
        _handleNotificationTap(response.payload, context);
      },
    );
    
    // Tạo kênh thông báo cho Android (cần thiết cho Android 8.0+)
    await _createNotificationChannels();
  }
  
  // Tạo các kênh thông báo
  static Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      // Kênh cho tin nhắn chat
      const chatChannel = AndroidNotificationChannel(
        'chat_messages_channel',
        'Tin nhắn',
        description: 'Thông báo khi có tin nhắn mới',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );
      
      // Kênh cho thông báo hệ thống
      const systemChannel = AndroidNotificationChannel(
        'system_notifications_channel',
        'Thông báo hệ thống',
        description: 'Thông báo hệ thống và cập nhật',
        importance: Importance.defaultImportance,
      );
      
      // Kênh cho thông báo khẩn cấp (cao nhất)
      const highImportanceChannel = AndroidNotificationChannel(
        'high_importance_channel',
        'Thông báo quan trọng',
        description: 'Thông báo quan trọng cần chú ý ngay',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
      );

      // Tạo các kênh thông báo
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(chatChannel);
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(systemChannel);
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(highImportanceChannel);
    }
  }

  // Lưu token thông báo của thiết bị vào Firestore
  static Future<void> _saveTokenToFirestore(String token) async {
    if (_auth.currentUser == null) {
      debugPrint('Không có người dùng đăng nhập, không lưu token');
      return;
    }

    try {
      final userId = _auth.currentUser!.uid;
      final userRef = _firestore.collection('users').doc(userId);
      
      // Lấy thông tin người dùng hiện tại
      final userDoc = await userRef.get();
      
      if (userDoc.exists) {
        final userData = userDoc.data();
        final List<String> existingTokens = userData != null && userData['fcmTokens'] is List
            ? List<String>.from(userData['fcmTokens'])
            : [];
        
        // Chỉ thêm token mới nếu chưa tồn tại
        if (!existingTokens.contains(token)) {
          existingTokens.add(token);
          
          await userRef.update({
            'fcmTokens': existingTokens,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          });
          
          debugPrint('Đã lưu token thành công: $token');
        } else {
          debugPrint('Token đã tồn tại, không cần cập nhật');
        }
      } else {
        // Nếu document không tồn tại, tạo mới với token
        await userRef.set({
          'fcmTokens': [token],
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        debugPrint('Đã tạo document mới với token: $token');
      }
    } catch (e) {
      debugPrint('Lỗi khi lưu FCM token: $e');
    }
  }

  // Hiển thị thông báo cục bộ
  static Future<void> _showNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final android = message.notification?.android;
      final data = message.data;
      final type = data['type'] ?? 'system';
      
      // Lựa chọn kênh thông báo dựa trên loại
      String channelId;
      if (type == 'chat_message') {
        channelId = 'chat_messages_channel';
      } else if (type == 'high_importance' || type == 'order') {
        channelId = 'high_importance_channel';
      } else {
        channelId = 'system_notifications_channel';
      }
      
      // Cấu hình cho Android
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelId == 'chat_messages_channel' ? 'Tin nhắn' : 
          (channelId == 'high_importance_channel' ? 'Thông báo quan trọng' : 'Thông báo hệ thống'),
        channelDescription: 'Thông báo từ Student Market NTTU',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: android?.smallIcon ?? '@mipmap/ic_launcher',
      );

      // Cấu hình cho iOS
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Cấu hình chung
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      // Hiển thị thông báo nếu có nội dung
      if (notification != null) {
        await _flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title ?? 'Thông báo mới',
          notification.body ?? '',
          details,
          payload: json.encode(message.data),
        );
        
        debugPrint('Đã hiển thị thông báo: ${notification.title}');
        
        // Thêm thông báo vào cơ sở dữ liệu nếu người dùng đã đăng nhập
        await _saveNotificationToDatabase(notification, data);
      } else if (data.isNotEmpty) {
        // Nếu không có thông báo nhưng có data, hiển thị dựa trên data
        await _flutterLocalNotificationsPlugin.show(
          data.hashCode,
          data['title'] ?? 'Thông báo mới',
          data['body'] ?? '',
          details,
          payload: json.encode(data),
        );
        
        debugPrint('Đã hiển thị thông báo từ data: ${data['title']}');
        
        // Thêm thông báo vào cơ sở dữ liệu nếu người dùng đã đăng nhập
        await _saveNotificationToDatabase(null, data);
      }
    } catch (e) {
      debugPrint('Lỗi khi hiển thị thông báo: $e');
    }
  }
  
  // Lưu thông báo vào cơ sở dữ liệu
  static Future<void> _saveNotificationToDatabase(
    RemoteNotification? notification, 
    Map<String, dynamic> data
  ) async {
    if (_auth.currentUser == null) return;
    
    try {
      final userId = _auth.currentUser!.uid;
      
      // Không tạo thông báo trùng lặp nếu đã có notificationId
      if (data.containsKey('notificationId')) return;
      
      // Tạo thông báo trong Firestore
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': notification?.title ?? data['title'] ?? 'Thông báo mới',
        'body': notification?.body ?? data['body'] ?? '',
        'type': data['type'] ?? 'system',
        'data': data,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      
      debugPrint('Đã lưu thông báo vào cơ sở dữ liệu');
    } catch (e) {
      debugPrint('Lỗi khi lưu thông báo vào cơ sở dữ liệu: $e');
    }
  }

  // Xử lý khi nhấn vào thông báo
  static void _handleNotificationTap(String? payload, BuildContext context) {
    if (payload == null) return;

    try {
      final data = json.decode(payload) as Map<String, dynamic>;
      final type = data['type'] as String?;
      
      debugPrint('Xử lý tap thông báo loại: $type');
      
      if (type == 'chat_message') {
        final chatId = data['chatId'] as String?;
        if (chatId != null) {
          // Điều hướng đến màn hình chat cụ thể
          Navigator.of(context, rootNavigator: true).pushNamed(
            '/chat-detail',
            arguments: {
              'chatId': chatId,
            },
          );
        }
      } else if (type == 'order') {
        final orderId = data['orderId'] as String?;
        if (orderId != null) {
          // Điều hướng đến màn hình chi tiết đơn hàng
          Navigator.of(context, rootNavigator: true).pushNamed(
            '/order-detail',
            arguments: {
              'orderId': orderId,
            },
          );
        }
      } else if (type == 'product') {
        final productId = data['productId'] as String?;
        if (productId != null) {
          // Điều hướng đến màn hình chi tiết sản phẩm
          Navigator.of(context, rootNavigator: true).pushNamed(
            '/product-detail',
            arguments: {
              'productId': productId,
            },
          );
        }
      } else {
        // Nếu không có loại cụ thể, điều hướng đến màn hình thông báo
        Navigator.of(context, rootNavigator: true).pushNamed('/notifications');
      }
    } catch (e) {
      debugPrint('Lỗi khi xử lý tap thông báo: $e');
    }
  }

  // Gửi thông báo đến người dùng cụ thể (sử dụng Cloud Functions)
  static Future<void> sendNotificationToUser({
    required String targetUserId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Kiểm tra người dùng đã đăng nhập
      if (_auth.currentUser == null) {
        debugPrint('Người dùng chưa đăng nhập, không thể gửi thông báo');
        return;
      }

      // Chuẩn bị dữ liệu cho Cloud Function
      final params = {
        'targetUserId': targetUserId,
        'title': title,
        'body': body,
        'data': data,
        'sender': {
          'uid': _auth.currentUser!.uid,
          'email': _auth.currentUser!.email ?? '',
        },
      };

      // Gọi Cloud Function để gửi thông báo
      final callable = _functions.httpsCallable('sendFCM');
      final result = await callable.call(params);

      // Xử lý kết quả
      if (result.data != null && result.data['success'] == true) {
        debugPrint('Gửi thông báo thành công: ${result.data['successCount']} thiết bị');
        
        // Lưu thông báo vào cơ sở dữ liệu nếu thành công
        await _firestore.collection('notifications').add({
          'userId': targetUserId,
          'title': title,
          'body': body,
          'type': data['type'] ?? 'system',
          'data': data,
          'senderId': _auth.currentUser!.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      } else {
        debugPrint('Không thể gửi thông báo: ${result.data?['message'] ?? 'Lỗi không xác định'}');
      }
    } catch (e) {
      debugPrint('Lỗi khi gọi Cloud Function sendFCM: $e');
    }
  }
} 