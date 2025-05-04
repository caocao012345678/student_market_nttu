import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_market_nttu/models/product.dart';
import 'package:student_market_nttu/models/user.dart';
import 'package:student_market_nttu/screens/chat_detail_screen.dart';
import 'package:student_market_nttu/screens/order_detail_screen.dart';
import 'package:student_market_nttu/screens/product_detail_screen.dart';
import 'package:student_market_nttu/services/notification_service.dart' as app_notification;
import 'package:student_market_nttu/services/product_service.dart';
import 'package:student_market_nttu/services/user_service.dart';

class NotificationDetailScreen extends StatefulWidget {
  static const routeName = '/notification-detail';
  
  final String notificationId;
  
  const NotificationDetailScreen({
    Key? key,
    required this.notificationId,
  }) : super(key: key);
  
  @override
  State<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  app_notification.Notification? _notification;
  
  @override
  void initState() {
    super.initState();
    _loadNotificationData();
  }
  
  Future<void> _loadNotificationData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
    
    try {
      // Tìm thông báo trong danh sách thông báo của người dùng
      final notificationService = Provider.of<app_notification.NotificationService>(context, listen: false);
      
      // Đánh dấu thông báo đã đọc
      await notificationService.markAsRead(widget.notificationId);
      
      // Tìm thông báo trong danh sách
      final notification = notificationService.notifications.firstWhere(
        (n) => n.id == widget.notificationId,
        orElse: () => throw Exception('Không tìm thấy thông báo'),
      );
      
      setState(() {
        _notification = notification;
      });
      
      // Điều hướng đến màn hình tương ứng
      _navigateToDetailScreen(notification);
    } catch (e) {
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
  
  Future<void> _navigateToDetailScreen(app_notification.Notification notification) async {
    try {
      switch (notification.type) {
        case app_notification.NotificationType.chat:
          final chatId = notification.data?['chatId'] as String?;
          final senderId = notification.data?['senderId'] as String?;
          
          if (chatId != null) {
            // Lấy thông tin người gửi
            final userService = Provider.of<UserService>(context, listen: false);
            UserModel? sender;
            
            if (senderId != null) {
              sender = await userService.getUserById(senderId);
            }
            
            if (!mounted) return;
            
            // Thay thế màn hình hiện tại
            Navigator.of(context).pushReplacement(
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
            Navigator.of(context).pushReplacementNamed(
              OrderDetailScreen.routeName,
              arguments: {'orderId': orderId},
            );
          }
          break;
          
        case app_notification.NotificationType.product:
          final productId = notification.data?['productId'] as String?;
          if (productId != null && mounted) {
            try {
              // Lấy thông tin sản phẩm trước khi điều hướng
              final productService = Provider.of<ProductService>(context, listen: false);
              final product = await productService.getProductById(productId);
              
              if (!mounted) return;
              
              // Điều hướng đến màn hình chi tiết sản phẩm với thông tin đã tải
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(product: product),
                ),
              );
            } catch (error) {
              // Nếu không tải được sản phẩm, chuyển đến màn hình với thông tin cơ bản
              if (!mounted) return;
              Navigator.of(context).pushReplacementNamed(
                ProductDetailScreen.routeName,
                arguments: {
                  'productId': productId,
                  'fromNotification': true,
                },
              );
            }
          }
          break;
          
        case app_notification.NotificationType.promo:
          final promoId = notification.data?['promoId'] as String?;
          if (promoId != null && mounted) {
            Navigator.of(context).pushReplacementNamed(
              ProductDetailScreen.routeName,
              arguments: {'promoId': promoId},
            );
          }
          break;
          
        default:
          // Hiển thị thông tin thông báo nếu không có loại cụ thể
          break;
      }
    } catch (e) {
      debugPrint('Lỗi khi điều hướng: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết thông báo'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildErrorView()
              : _buildNotificationDetailView(),
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
            onPressed: _loadNotificationData,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotificationDetailView() {
    if (_notification == null) {
      return const Center(
        child: Text('Không tìm thấy thông báo'),
      );
    }
    
    // Biểu tượng tùy theo loại thông báo
    IconData iconData;
    Color iconColor;
    
    switch (_notification!.type) {
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
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: iconColor.withOpacity(0.2),
                child: Icon(
                  iconData,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _notification!.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            _notification!.body,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 32),
          if (_notification!.data != null)
            ..._buildDataDetails(_notification!.data!),
        ],
      ),
    );
  }
  
  List<Widget> _buildDataDetails(Map<String, dynamic> data) {
    final widgets = <Widget>[];
    
    // Hiển thị dữ liệu theo loại thông báo
    switch (_notification!.type) {
      case app_notification.NotificationType.chat:
        final chatId = data['chatId'] as String?;
        final senderId = data['senderId'] as String?;
        
        if (chatId != null) {
          widgets.add(
            ElevatedButton.icon(
              onPressed: () => _navigateToDetailScreen(_notification!),
              icon: const Icon(Icons.chat),
              label: const Text('Xem tin nhắn'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          );
        }
        break;
        
      case app_notification.NotificationType.order:
        final orderId = data['orderId'] as String?;
        if (orderId != null) {
          widgets.add(
            ElevatedButton.icon(
              onPressed: () => _navigateToDetailScreen(_notification!),
              icon: const Icon(Icons.shopping_bag),
              label: const Text('Xem chi tiết đơn hàng'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          );
        }
        break;
        
      case app_notification.NotificationType.product:
        final productId = data['productId'] as String?;
        if (productId != null) {
          widgets.add(
            ElevatedButton.icon(
              onPressed: () => _navigateToDetailScreen(_notification!),
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Xem sản phẩm'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          );
        }
        break;
        
      default:
        // Hiển thị các trường dữ liệu khác
        data.forEach((key, value) {
          if (key != 'type' && key != 'notificationId') {
            widgets.add(
              ListTile(
                title: Text(key),
                subtitle: Text(value.toString()),
              ),
            );
          }
        });
        break;
    }
    
    return widgets;
  }
} 