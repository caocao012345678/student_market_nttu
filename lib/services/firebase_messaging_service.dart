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

class FirebaseMessagingService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  // Khởi tạo dịch vụ thông báo
  static Future<void> initialize(BuildContext context) async {
    // Yêu cầu quyền thông báo trên iOS
    if (Platform.isIOS) {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Khởi tạo thông báo cục bộ
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        _handleNotificationTap(response.payload, context);
      },
    );

    // Xử lý khi nhận thông báo trong foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    // Xử lý khi nhấn vào thông báo để mở ứng dụng từ terminated state
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(json.encode(message.data), context);
      }
    });

    // Xử lý khi nhấn vào thông báo để mở ứng dụng từ background state
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(json.encode(message.data), context);
    });

    // Đăng ký token mới mỗi khi token thay đổi
    FirebaseMessaging.instance.onTokenRefresh.listen(_saveTokenToFirestore);

    // Lấy và lưu token hiện tại
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
    }
  }

  // Lưu token thông báo của thiết bị vào Firestore
  static Future<void> _saveTokenToFirestore(String token) async {
    if (_auth.currentUser == null) return;

    final userId = _auth.currentUser!.uid;
    final tokensRef = _firestore.collection('users').doc(userId);

    await tokensRef.update({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'lastTokenUpdate': FieldValue.serverTimestamp(),
    });
  }

  // Hiển thị thông báo cục bộ
  static Future<void> _showNotification(RemoteMessage message) async {
    final androidDetails = AndroidNotificationDetails(
      'chat_messages_channel',
      'Tin nhắn',
      channelDescription: 'Thông báo khi có tin nhắn mới',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    final notification = message.notification;

    if (notification != null) {
      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        details,
        payload: json.encode(message.data),
      );
    }
  }

  // Xử lý khi nhấn vào thông báo
  static void _handleNotificationTap(String? payload, BuildContext context) {
    if (payload == null) return;

    try {
      final data = json.decode(payload) as Map<String, dynamic>;
      final type = data['type'] as String?;
      
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
      }
    } catch (e) {
      debugPrint('Lỗi khi xử lý thông báo: $e');
    }
  }

  // Gửi thông báo đến người dùng cụ thể
  static Future<void> sendNotificationToUser({
    required String targetUserId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Lấy API key từ biến môi trường
      final fcmServerKey = dotenv.env['FCM_SERVER_KEY'];
      if (fcmServerKey == null || fcmServerKey.isEmpty) {
        debugPrint('FCM_SERVER_KEY không được cấu hình');
        return;
      }

      // Lấy danh sách token của người dùng từ Firestore
      final userDoc = await _firestore.collection('users').doc(targetUserId).get();
      if (!userDoc.exists) return;

      final userData = userDoc.data();
      if (userData == null) return;

      final tokens = List<String>.from(userData['fcmTokens'] ?? []);
      if (tokens.isEmpty) return;

      // Chuẩn bị dữ liệu thông báo
      final Map<String, dynamic> notification = {
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
          'badge': '1',
        },
        'data': data,
        'registration_ids': tokens, // Gửi đến nhiều thiết bị
      };

      // Gửi yêu cầu HTTP đến FCM API
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$fcmServerKey',
        },
        body: json.encode(notification),
      );

      if (response.statusCode != 200) {
        debugPrint('Lỗi khi gửi thông báo FCM: ${response.body}');
      }
    } catch (e) {
      debugPrint('Lỗi khi gửi thông báo: $e');
    }
  }
} 