import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_market_nttu/models/purchase_order.dart';
import 'package:student_market_nttu/services/order_service.dart';

class OrderDetailScreen extends StatefulWidget {
  static const routeName = '/order-detail';
  
  final String orderId;
  
  const OrderDetailScreen({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  PurchaseOrder? _orderData;
  
  @override
  void initState() {
    super.initState();
    _loadOrderData();
  }
  
  Future<void> _loadOrderData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    
    try {
      // Thử tải thông tin đơn hàng
      final orderService = Provider.of<OrderService>(context, listen: false);
      _orderData = await orderService.getOrderById(widget.orderId);
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildErrorView()
              : _buildOrderDetailView(),
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
            onPressed: _loadOrderData,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOrderDetailView() {
    if (_orderData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              size: 72,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Không tìm thấy thông tin đơn hàng',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Text(
              'Mã đơn hàng: ${widget.orderId}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Quay lại'),
            ),
          ],
        ),
      );
    }
    
    // Hiển thị chi tiết đơn hàng khi chức năng này được hoàn thiện
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.construction,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            const Text(
              'Chức năng này đang được phát triển',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Mã đơn hàng: ${widget.orderId}',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Quay lại'),
            ),
          ],
        ),
      ),
    );
  }
} 