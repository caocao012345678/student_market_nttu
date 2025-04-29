import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';
import '../services/payment_service.dart';
import '../services/auth_service.dart';
import '../models/purchase_order.dart';
import '../services/ntt_point_service.dart';
import 'package:intl/intl.dart';

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
  final _pointController = TextEditingController(text: '0');
  bool _isLoading = false;
  String _selectedPaymentMethod = 'COD';
  bool _useNTTPoint = false;
  int _maxPointsCanUse = 0;
  int _pointsToUse = 0;
  double _finalAmount = 0;
  
  // Định dạng tiền tệ VN
  final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  
  // Tỷ lệ quy đổi NTTPoint (1000đ = 10 điểm)
  final int _pointExchangeRate = 10; 

  @override
  void initState() {
    super.initState();
    _finalAmount = widget.totalAmount;
    _loadUserPoints();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _pointController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserPoints() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final pointService = Provider.of<NTTPointService>(context, listen: false);
    
    if (authService.currentUser != null) {
      await pointService.loadTransactions(authService.currentUser!.uid);
      
      // Tính số điểm tối đa có thể dùng
      final availablePoints = pointService.availablePoints;
      final maxPointsForOrder = (widget.totalAmount / 100 * _pointExchangeRate).floor();
      
      setState(() {
        _maxPointsCanUse = availablePoints < maxPointsForOrder ? availablePoints : maxPointsForOrder;
      });
    }
  }
  
  void _updatePointsToUse(String value) {
    int points = int.tryParse(value) ?? 0;
    
    if (points > _maxPointsCanUse) {
      points = _maxPointsCanUse;
      _pointController.text = points.toString();
    }
    
    setState(() {
      _pointsToUse = points;
      
      // Tính lại tổng tiền sau khi trừ điểm
      final discount = points / _pointExchangeRate * 100;
      _finalAmount = widget.totalAmount - discount;
      
      if (_finalAmount < 0) _finalAmount = 0;
    });
  }

  Future<void> _processCheckout() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final cartService = Provider.of<CartService>(context, listen: false);
      final paymentService = Provider.of<PaymentService>(context, listen: false);
      final pointService = Provider.of<NTTPointService>(context, listen: false);
      
      final user = authService.currentUser;
      if (user == null) throw Exception('Vui lòng đăng nhập để thanh toán');

      List<String> orderIds = [];
      
      // Tổng điểm được sử dụng
      final pointsUsed = _useNTTPoint ? _pointsToUse : 0;
      
      // Tổng tiền sau khi trừ điểm
      final amountAfterDiscount = _finalAmount;

      // Tạo đơn hàng cho từng sản phẩm trong giỏ hàng
      for (var item in widget.cartItems) {
        // Tính phân bổ điểm cho từng sản phẩm theo tỷ lệ
        int productPointsUsed = 0;
        double itemDiscount = 0;
        
        if (pointsUsed > 0) {
          // Tính tỷ lệ giá sản phẩm trên tổng giá trị đơn hàng
          final itemRatio = (item.price * item.quantity) / widget.totalAmount;
          // Phân bổ điểm theo tỷ lệ
          productPointsUsed = (pointsUsed * itemRatio).round();
          // Tính tiền giảm giá tương ứng với điểm
          itemDiscount = productPointsUsed / _pointExchangeRate * 100;
        }
        
        // Tính giá sau khi giảm
        final discountedPrice = item.price - (itemDiscount / item.quantity);
        
        final order = PurchaseOrder(
          id: '', // ID sẽ được tạo tự động bởi Firestore
          buyerId: user.uid,
          buyerName: user.displayName ?? user.email ?? 'Không có tên',
          sellerId: item.sellerId,
          productId: item.productId,
          productTitle: item.productName,
          productImage: item.productImage,
          price: discountedPrice > 0 ? discountedPrice : 0,
          originalPrice: item.price,
          quantity: item.quantity,
          status: 'pending',
          address: _addressController.text,
          phone: _phoneController.text,
          createdAt: DateTime.now(),
          pointsUsed: productPointsUsed,
          discountAmount: itemDiscount,
        );

        // Xử lý thanh toán và tạo đơn hàng
        final orderId = await paymentService.processPayment(order, _selectedPaymentMethod);
        orderIds.add(orderId);
      }
      
      // Sử dụng NTTPoint nếu được chọn và có điểm để sử dụng
      if (_useNTTPoint && pointsUsed > 0) {
        final ordersJoined = orderIds.join(', ');
        await pointService.usePointsForPurchase(
          user.uid, 
          ordersJoined, 
          pointsUsed, 
          'Thanh toán ${widget.cartItems.length} sản phẩm'
        );
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
    // Lấy thông tin điểm từ service
    final pointService = Provider.of<NTTPointService>(context);
    final availablePoints = pointService.availablePoints;
    
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

            // Sử dụng NTTPoint
            const Text(
              'NTTPoint',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Số điểm hiện có: $availablePoints',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Tỷ lệ: 10 điểm = 1.000đ',
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Sử dụng NTTPoint'),
                    value: _useNTTPoint,
                    contentPadding: EdgeInsets.zero,
                    onChanged: availablePoints > 0 
                      ? (value) {
                          setState(() {
                            _useNTTPoint = value;
                            if (!value) {
                              _pointController.text = '0';
                              _updatePointsToUse('0');
                            }
                          });
                        }
                      : null,
                  ),
                  if (_useNTTPoint) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _pointController,
                            decoration: InputDecoration(
                              labelText: 'Số điểm muốn dùng (tối đa $_maxPointsCanUse)',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.upload_outlined),
                                tooltip: 'Dùng tối đa',
                                onPressed: () {
                                  _pointController.text = _maxPointsCanUse.toString();
                                  _updatePointsToUse(_maxPointsCanUse.toString());
                                },
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: _updatePointsToUse,
                            validator: (value) {
                              final points = int.tryParse(value ?? '') ?? 0;
                              if (points < 0) {
                                return 'Số điểm không hợp lệ';
                              }
                              if (points > _maxPointsCanUse) {
                                return 'Vượt quá số điểm có thể sử dụng';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Giảm: ${formatCurrency.format(_pointsToUse / _pointExchangeRate * 100)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
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
              subtitle: Text('${item.quantity}x ${formatCurrency.format(item.price)}'),
              trailing: Text(formatCurrency.format(item.price * item.quantity)),
            )),
            const Divider(),
            ListTile(
              title: const Text('Tổng tiền sản phẩm'),
              trailing: Text(
                formatCurrency.format(widget.totalAmount),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (_useNTTPoint && _pointsToUse > 0)
              ListTile(
                title: const Text('Giảm giá (NTTPoint)'),
                trailing: Text(
                  '- ${formatCurrency.format(_pointsToUse / _pointExchangeRate * 100)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ListTile(
              title: const Text(
                'Tổng thanh toán',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Text(
                formatCurrency.format(_finalAmount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.blue[900],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      )
                    : const Text('Xác nhận đặt hàng'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 