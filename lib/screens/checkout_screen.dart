import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';
import '../services/payment_service.dart';
import '../services/auth_service.dart';
import '../models/purchase_order.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final double totalAmount;

  const CheckoutScreen({
    Key? key,
    required this.cartItems,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String _selectedPaymentMethod = 'COD';

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _processCheckout() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final cartService = Provider.of<CartService>(context, listen: false);
      final paymentService = Provider.of<PaymentService>(context, listen: false);
      
      final user = authService.currentUser;
      if (user == null) throw Exception('Vui lòng đăng nhập để thanh toán');

      List<String> orderIds = [];

      // Tạo đơn hàng cho từng sản phẩm trong giỏ hàng
      for (var item in widget.cartItems) {
        final order = PurchaseOrder(
          id: '', // ID sẽ được tạo tự động bởi Firestore
          buyerId: user.uid,
          buyerName: user.displayName ?? user.email ?? 'Không có tên',
          sellerId: item.sellerId,
          productId: item.productId,
          productTitle: item.productName,
          productImage: item.productImage,
          price: item.price,
          quantity: item.quantity,
          status: 'pending',
          address: _addressController.text,
          phone: _phoneController.text,
          createdAt: DateTime.now(),
        );

        // Xử lý thanh toán và tạo đơn hàng
        final orderId = await paymentService.processPayment(order, _selectedPaymentMethod);
        orderIds.add(orderId);
      }

      // Xóa giỏ hàng sau khi thanh toán thành công
      if (orderIds.isNotEmpty) {
        await cartService.clearCart(user.uid);

        if (!mounted) return;
        
        // Hiển thị thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đặt hàng thành công! Vui lòng kiểm tra email của bạn.'),
            backgroundColor: Colors.green,
          ),
        );

        // Quay về màn hình chính
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Thông tin giao hàng
            const Text(
              'Thông tin giao hàng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ nhận hàng',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập địa chỉ nhận hàng';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập số điện thoại';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Phương thức thanh toán
            const Text(
              'Phương thức thanh toán',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            RadioListTile<String>(
              title: const Text('Thanh toán khi nhận hàng (COD)'),
              value: 'COD',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() => _selectedPaymentMethod = value!);
              },
            ),
            RadioListTile<String>(
              title: const Text('Thẻ tín dụng/ghi nợ'),
              value: 'CARD',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() => _selectedPaymentMethod = value!);
              },
            ),
            RadioListTile<String>(
              title: const Text('Ví điện tử'),
              value: 'E_WALLET',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() => _selectedPaymentMethod = value!);
              },
            ),
            const SizedBox(height: 24),

            // Tổng kết đơn hàng
            const Text(
              'Tổng kết đơn hàng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...widget.cartItems.map((item) => ListTile(
              title: Text(item.productName),
              subtitle: Text('${item.quantity}x ${item.price} VNĐ'),
              trailing: Text('${(item.price * item.quantity).toStringAsFixed(0)} VNĐ'),
            )),
            const Divider(),
            ListTile(
              title: const Text(
                'Tổng cộng',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Text(
                '${widget.totalAmount.toStringAsFixed(0)} VNĐ',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Nút thanh toán
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processCheckout,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Xác nhận đặt hàng',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 