import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:student_market_nttu/models/user.dart';
import 'package:student_market_nttu/screens/chat_detail_screen.dart';
import 'package:student_market_nttu/screens/order_detail_screen.dart';
import 'package:student_market_nttu/screens/product_detail_screen.dart';
import 'package:student_market_nttu/services/notification_service.dart' as app_notification;
import 'package:student_market_nttu/services/user_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class NotificationScreen extends StatefulWidget {
  static const routeName = '/notifications';

  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Khởi tạo dữ liệu thông báo
      final notificationService = Provider.of<app_notification.NotificationService>(context, listen: false);
      await notificationService.initializeNotifications();
    } catch (e) {
      debugPrint('Lỗi khi tải dữ liệu thông báo: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshNotifications() async {
    await _initData();
  }

  Future<void> _markAllAsRead() async {
    try {
      final notificationService = Provider.of<app_notification.NotificationService>(context, listen: false);
      await notificationService.markAllAsRead();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đánh dấu tất cả thông báo là đã đọc')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _deleteAllNotifications() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc chắn muốn xóa tất cả thông báo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final notificationService = Provider.of<app_notification.NotificationService>(context, listen: false);
        await notificationService.deleteAllNotifications();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa tất cả thông báo')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _handleNotificationTap(app_notification.Notification notification) async {
    try {
      // Đánh dấu đã đọc khi nhấn vào
      final notificationService = Provider.of<app_notification.NotificationService>(context, listen: false);
      await notificationService.markAsRead(notification.id);

      // Điều hướng tùy theo loại thông báo
      switch (notification.type) {
        case app_notification.NotificationType.chat:
          final chatId = notification.data?['chatId'] as String?;
          final senderId = notification.data?['senderId'] as String?;
          final productId = notification.data?['productId'] as String?;
          
          if (chatId != null) {
            // Lấy thông tin người gửi
            final userService = Provider.of<UserService>(context, listen: false);
            UserModel? sender;
            
            if (senderId != null) {
              sender = await userService.getUserById(senderId);
            }
            
            if (!mounted) return;
            
            // Nếu là thông báo chat về sản phẩm, hiển thị thông tin bổ sung
            if (productId != null) {
              final productTitle = notification.data?['productTitle'] as String? ?? 'Sản phẩm';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tin nhắn về sản phẩm: $productTitle'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(
                  chatId: chatId,
                  otherUser: sender,
                ),
              ),
            );
          }
          break;
          
        case app_notification.NotificationType.order:
          final orderId = notification.data?['orderId'] as String?;
          if (orderId != null && mounted) {
            Navigator.of(context).pushNamed(
              OrderDetailScreen.routeName,
              arguments: {'orderId': orderId},
            );
          }
          break;
          
        case app_notification.NotificationType.product:
          final productId = notification.data?['productId'] as String?;
          if (productId != null && mounted) {
            Navigator.of(context).pushNamed(
              ProductDetailScreen.routeName,
              arguments: {'productId': productId},
            );
          }
          break;
          
        default:
          // Không làm gì với các loại thông báo khác
          break;
      }
    } catch (e) {
      debugPrint('Lỗi khi xử lý thông báo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Đánh dấu tất cả là đã đọc',
            onPressed: _markAllAsRead,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Xóa tất cả thông báo',
            onPressed: _deleteAllNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildErrorView()
              : _buildNotificationList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Đã xảy ra lỗi: $_errorMessage',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshNotifications,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return Consumer<app_notification.NotificationService>(
      builder: (context, notificationService, child) {
        return StreamBuilder<List<app_notification.Notification>>(
          stream: notificationService.getUserNotifications(),
          builder: (context, snapshot) {
            // Chỉ hiển thị loading indicator khi đang loading lần đầu
            // và chưa có dữ liệu trong snapshot
            if (snapshot.connectionState == ConnectionState.waiting && 
                !snapshot.hasData && 
                _isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Lỗi khi tải thông báo: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshNotifications,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }

            final notifications = snapshot.data ?? [];

            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_off,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bạn chưa có thông báo nào',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refreshNotifications,
              child: ListView.builder(
                key: PageStorageKey<String>('notification_list'),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _buildNotificationItem(notification);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationItem(app_notification.Notification notification) {
    // Biểu tượng tùy theo loại thông báo
    IconData iconData;
    Color iconColor;
    
    switch (notification.type) {
      case app_notification.NotificationType.chat:
        iconData = Icons.chat;
        iconColor = Colors.blue;
        break;
      case app_notification.NotificationType.order:
        iconData = Icons.shopping_bag;
        iconColor = Colors.orange;
        break;
      case app_notification.NotificationType.product:
        iconData = Icons.shopping_cart;
        iconColor = Colors.green;
        break;
      case app_notification.NotificationType.promo:
        iconData = Icons.discount;
        iconColor = Colors.purple;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
        break;
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xác nhận'),
            content: const Text('Bạn có chắc chắn muốn xóa thông báo này?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Xóa'),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) async {
        try {
          final notificationService = Provider.of<app_notification.NotificationService>(context, listen: false);
          await notificationService.deleteNotification(notification.id);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa thông báo')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi xóa thông báo: $e')),
          );
        }
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.2),
          child: Icon(
            iconData,
            color: iconColor,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeago.format(notification.createdAt, locale: 'vi'),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () => _handleNotificationTap(notification),
      ),
    );
  }
} 