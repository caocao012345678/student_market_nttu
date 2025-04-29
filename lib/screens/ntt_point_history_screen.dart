import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:student_market_nttu/models/ntt_point_transaction.dart';
import 'package:student_market_nttu/services/auth_service.dart';
import 'package:student_market_nttu/services/ntt_point_service.dart';
import 'package:student_market_nttu/widgets/common_app_bar.dart';

class NTTPointHistoryScreen extends StatefulWidget {
  static const routeName = '/ntt-point-history';
  
  const NTTPointHistoryScreen({Key? key}) : super(key: key);

  @override
  State<NTTPointHistoryScreen> createState() => _NTTPointHistoryScreenState();
}

class _NTTPointHistoryScreenState extends State<NTTPointHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPointHistory();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadPointHistory() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userId = Provider.of<AuthService>(context, listen: false).currentUser!.uid;
      await Provider.of<NTTPointService>(context, listen: false).loadTransactions(userId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải lịch sử điểm: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  String _getTransactionTypeText(NTTPointTransactionType type) {
    switch (type) {
      case NTTPointTransactionType.earned:
        return 'Tích lũy';
      case NTTPointTransactionType.spent:
        return 'Sử dụng';
      case NTTPointTransactionType.expired:
        return 'Hết hạn';
      case NTTPointTransactionType.refunded:
        return 'Hoàn lại';
      case NTTPointTransactionType.deducted:
        return 'Bị trừ';
      default:
        return 'Không xác định';
    }
  }
  
  Color _getTransactionColor(NTTPointTransactionType type) {
    switch (type) {
      case NTTPointTransactionType.earned:
      case NTTPointTransactionType.refunded:
        return Colors.green;
      case NTTPointTransactionType.spent:
      case NTTPointTransactionType.expired:
      case NTTPointTransactionType.deducted:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String _getTransactionAmountText(NTTPointTransaction transaction) {
    switch (transaction.type) {
      case NTTPointTransactionType.earned:
      case NTTPointTransactionType.refunded:
        return '+${transaction.points}';
      case NTTPointTransactionType.spent:
      case NTTPointTransactionType.expired:
      case NTTPointTransactionType.deducted:
        return '-${transaction.points}';
      default:
        return '${transaction.points}';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        title: 'Lịch sử NTTPoint',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }
  
  Widget _buildContent() {
    final pointService = Provider.of<NTTPointService>(context);
    final transactions = pointService.transactions;
    final availablePoints = pointService.availablePoints;
    
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Chưa có giao dịch điểm nào',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Đăng sản phẩm đồ tặng để nhận điểm',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadPointHistory,
              child: const Text('Làm mới'),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.blue[900],
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Tổng điểm hiện có',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$availablePoints',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mỗi 100 điểm = 10.000đ',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          labelColor: Colors.blue[900],
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue[900],
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: 'Tích lũy'),
            Tab(text: 'Sử dụng'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTransactionList(transactions),
              _buildTransactionList(transactions.where((t) => 
                t.type == NTTPointTransactionType.earned || 
                t.type == NTTPointTransactionType.refunded).toList()),
              _buildTransactionList(transactions.where((t) => 
                t.type == NTTPointTransactionType.spent || 
                t.type == NTTPointTransactionType.expired || 
                t.type == NTTPointTransactionType.deducted).toList()),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildTransactionList(List<NTTPointTransaction> transactions) {
    return RefreshIndicator(
      onRefresh: _loadPointHistory,
      child: ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          final isExpired = transaction.isExpired;
          
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getTransactionColor(transaction.type).withOpacity(0.2),
                child: Icon(
                  _getTransactionIcon(transaction.type),
                  color: _getTransactionColor(transaction.type),
                ),
              ),
              title: Text(
                transaction.description,
                style: TextStyle(
                  decoration: isExpired ? TextDecoration.lineThrough : null,
                  color: isExpired ? Colors.grey : Colors.black,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: isExpired ? Colors.grey : null,
                    ),
                  ),
                  if (transaction.type == NTTPointTransactionType.earned && !isExpired)
                    Text(
                      'Hết hạn: ${DateFormat('dd/MM/yyyy').format(transaction.expiryDate)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                ],
              ),
              trailing: Text(
                _getTransactionAmountText(transaction),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isExpired ? Colors.grey : _getTransactionColor(transaction.type),
                ),
              ),
              isThreeLine: transaction.type == NTTPointTransactionType.earned && !isExpired,
            ),
          );
        },
      ),
    );
  }
  
  IconData _getTransactionIcon(NTTPointTransactionType type) {
    switch (type) {
      case NTTPointTransactionType.earned:
        return Icons.add_circle;
      case NTTPointTransactionType.spent:
        return Icons.shopping_cart;
      case NTTPointTransactionType.expired:
        return Icons.timer_off;
      case NTTPointTransactionType.refunded:
        return Icons.replay;
      case NTTPointTransactionType.deducted:
        return Icons.remove_circle;
      default:
        return Icons.help;
    }
  }
} 