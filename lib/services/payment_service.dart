import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:intl/intl.dart';
import '../models/purchase_order.dart';
import '../models/user.dart';
import '../utils/config.dart';

class PaymentService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isProcessing = false;

  bool get isProcessing => _isProcessing;

  // Xử lý thanh toán đơn hàng
  Future<String> processPayment(PurchaseOrder order, String paymentMethod) async {
    try {
      _isProcessing = true;
      notifyListeners();

      // Tạo document mới cho đơn hàng
      final orderData = {
        'buyerId': order.buyerId,
        'buyerName': order.buyerName,
        'sellerId': order.sellerId,
        'productId': order.productId,
        'productTitle': order.productTitle,
        'productImage': order.productImage,
        'price': order.price,
        'quantity': order.quantity,
        'status': order.status,
        'address': order.address,
        'phone': order.phone,
        'createdAt': FieldValue.serverTimestamp(),
        'paymentMethod': paymentMethod,
        'paymentDetails': {
          'method': paymentMethod,
          'status': 'completed',
          'paidAt': FieldValue.serverTimestamp(),
        },
        'isPaid': true,
      };

      // Tạo document mới và lấy reference
      final docRef = await _firestore.collection('orders').add(orderData);
      
      // Gửi email xác nhận đơn hàng
      await sendOrderConfirmationEmail(order.copyWith(id: docRef.id));

      _isProcessing = false;
      notifyListeners();
      return docRef.id; // Trả về ID của đơn hàng mới
    } catch (e) {
      _isProcessing = false;
      notifyListeners();
      throw e;
    }
  }

  // Gửi email xác nhận đơn hàng
  Future<void> sendOrderConfirmationEmail(PurchaseOrder order) async {
    print('Bắt đầu gửi email xác nhận đơn hàng ${order.id}...');
    try {
      print('Đang lấy thông tin người mua...');
      final buyerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(order.buyerId)
          .get();
      
      if (!buyerDoc.exists) {
        throw Exception('Không tìm thấy thông tin người mua');
      }
      
      final buyerEmail = buyerDoc.data()?['email'] as String?;
      if (buyerEmail == null || buyerEmail.isEmpty) {
        throw Exception('Email người mua không hợp lệ');
      }

      print('Đang lấy thông tin người bán...');
      final sellerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(order.sellerId)
          .get();
      
      if (!sellerDoc.exists) {
        throw Exception('Không tìm thấy thông tin người bán');
      }
      
      final sellerData = sellerDoc.data() ?? {};

      // Format giá tiền
      final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
      final price = currencyFormat.format(order.price);
      final total = currencyFormat.format(order.price * order.quantity);

      // Tạo nội dung email với template đẹp
      final emailBody = '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background-color: #1565C0; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }
            .content { background-color: #fff; padding: 20px; border: 1px solid #ddd; border-radius: 0 0 5px 5px; }
            .order-details { background-color: #f9f9f9; padding: 15px; border-radius: 5px; margin: 15px 0; }
            .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
            .button { background-color: #1565C0; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block; }
            .status { display: inline-block; padding: 5px 10px; border-radius: 3px; font-size: 14px; background-color: #E3F2FD; color: #1565C0; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>Xác nhận đơn hàng #${order.id}</h1>
            </div>
            <div class="content">
              <p>Xin chào ${order.buyerName},</p>
              <p>Cảm ơn bạn đã đặt hàng tại Student Market NTTU! Dưới đây là chi tiết đơn hàng của bạn:</p>
              
              <div class="order-details">
                <h3>Chi tiết đơn hàng:</h3>
                <p><strong>Sản phẩm:</strong> ${order.productTitle}</p>
                <p><strong>Số lượng:</strong> ${order.quantity}</p>
                <p><strong>Đơn giá:</strong> ${price}</p>
                <p><strong>Tổng cộng:</strong> ${total}</p>
                <p><strong>Phương thức thanh toán:</strong> ${order.paymentDetails?['method'] ?? 'Chưa xác định'}</p>
                <p><strong>Trạng thái:</strong> <span class="status">${_getStatusText(order.status)}</span></p>
              </div>

              <div class="order-details">
                <h3>Thông tin giao hàng:</h3>
                <p><strong>Người nhận:</strong> ${order.buyerName}</p>
                <p><strong>Địa chỉ:</strong> ${order.address}</p>
                <p><strong>Số điện thoại:</strong> ${order.phone}</p>
              </div>

              <div class="order-details">
                <h3>Thông tin người bán:</h3>
                <p><strong>Tên shop:</strong> ${sellerData['shopName'] ?? sellerData['displayName']}</p>
                <p><strong>Email:</strong> ${sellerData['email']}</p>
                <p><strong>Số điện thoại:</strong> ${sellerData['phone'] ?? 'Chưa cung cấp'}</p>
              </div>

              <p>Bạn có thể theo dõi đơn hàng trong mục "Lịch sử đơn hàng" trên ứng dụng.</p>
              
              <p>Nếu bạn có bất kỳ thắc mắc nào, vui lòng liên hệ với chúng tôi qua:</p>
              <ul>
                <li>Email: ${AppConfig.supportEmail}</li>
                <li>Hotline: ${AppConfig.supportPhone}</li>
              </ul>
            </div>
            <div class="footer">
              <p>Email này được gửi tự động, vui lòng không trả lời email này.</p>
              <p>&copy; ${DateTime.now().year} Student Market NTTU. All rights reserved.</p>
            </div>
          </div>
        </body>
        </html>
      ''';

      // Cấu hình SMTP server
      final smtpServer = SmtpServer(
        AppConfig.smtpHost,
        username: AppConfig.smtpUsername,
        password: AppConfig.smtpPassword,
        port: AppConfig.smtpPort,
        ssl: AppConfig.smtpUseSsl,
        ignoreBadCertificate: true,
      );

      // Tạo message từ hệ thống
      final message = Message()
        ..from = Address(AppConfig.smtpUsername, 'Student Market NTTU')
        ..recipients.add(buyerEmail)
        ..ccRecipients.add(sellerData['email']) // CC cho người bán
        ..subject = 'Xác nhận đơn hàng #${order.id} - Student Market NTTU'
        ..html = emailBody;

      print('Đang gửi email đến $buyerEmail...');
      print('CC đến: ${sellerData['email']}');
      print('Sử dụng SMTP server: ${AppConfig.smtpHost}:${AppConfig.smtpPort}');
      
      try {
        await send(message, smtpServer);
        print('Đã gửi email thành công!');
      } catch (e) {
        print('Lỗi khi gửi email: $e');
        throw Exception('Không thể gửi email: $e');
      }

      // Cập nhật trạng thái gửi email trong Firestore
      await _firestore.collection('orders').doc(order.id).update({
        'emailSent': true,
        'emailSentAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Lỗi trong quá trình gửi email: $e');
      rethrow; // Ném lỗi để hàm gọi có thể xử lý
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Đang xử lý';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'shipping':
        return 'Đang giao hàng';
      case 'delivered':
        return 'Đã giao hàng';
      case 'cancelled':
        return 'Đã hủy';
      case 'refunded':
        return 'Đã hoàn tiền';
      default:
        return 'Không xác định';
    }
  }
} 