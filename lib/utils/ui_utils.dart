import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UIUtils {
  // Format tiền tệ
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return formatter.format(amount);
  }

  // Format thời gian
  static String formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(dateTime);
  }

  // Format ngày
  static String formatDate(DateTime dateTime) {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(dateTime);
  }

  // Hiển thị thông báo lỗi
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Hiển thị thông báo thành công
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Hiển thị dialog xác nhận
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmButtonText = 'Xác nhận',
    String cancelButtonText = 'Hủy',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelButtonText),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                confirmButtonText,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  // Hiển thị dialog loading
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(message ?? 'Đang xử lý...'),
            ],
          ),
        );
      },
    );
  }

  // Ẩn dialog
  static void hideDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  // Tạo bóng đổ cho widget
  static List<BoxShadow> getShadow({Color? color, double? blurRadius}) {
    return [
      BoxShadow(
        color: color ?? Colors.black.withOpacity(0.1),
        blurRadius: blurRadius ?? 10,
        offset: const Offset(0, 2),
      ),
    ];
  }

  // Lấy màu dựa trên độ sáng của theme
  static Color getOnPrimaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.onPrimary;
  }

  // Tạo gradient chính
  static LinearGradient getPrimaryGradient() {
    return LinearGradient(
      colors: [Colors.blue[900]!, Colors.blue[700]!],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
} 