import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/moderation_result.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/auth_service.dart';
import 'product_detail_screen.dart';
import 'my_products_screen.dart';

class ModerationHistoryScreen extends StatefulWidget {
  const ModerationHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ModerationHistoryScreen> createState() => _ModerationHistoryScreenState();
}

class _ModerationHistoryScreenState extends State<ModerationHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Map<String, dynamic>> _historyItems = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadModerationHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadModerationHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = Provider.of<AuthService>(context, listen: false).user;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      // Lấy các sản phẩm của người dùng
      final products = await Provider.of<ProductService>(context, listen: false)
          .getUserProductsList(user.uid);

      final List<Map<String, dynamic>> historyItems = [];

      // Lấy lịch sử kiểm duyệt cho từng sản phẩm
      for (final product in products) {
        final moderationResults = await Provider.of<ProductService>(context, listen: false)
            .getProductModerationHistory(product.id);

        for (final result in moderationResults) {
          historyItems.add({
            'product': product,
            'moderation': result,
            'timestamp': result.createdAt.millisecondsSinceEpoch,
          });
        }
      }

      // Sắp xếp theo thời gian mới nhất
      historyItems.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      setState(() {
        _historyItems = historyItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử kiểm duyệt'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Đang duyệt'),
            Tab(text: 'Đã duyệt'),
            Tab(text: 'Bị từ chối'),
          ],
          labelColor: Colors.white,
          indicatorColor: Colors.white,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab Đang duyệt
                _buildHistoryList(ModerationStatus.pending),
                // Tab Đã duyệt
                _buildHistoryList(ModerationStatus.approved),
                // Tab Bị từ chối
                _buildHistoryList(ModerationStatus.rejected),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadModerationHistory,
        tooltip: 'Làm mới',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildHistoryList(ModerationStatus? filterStatus) {
    List<Map<String, dynamic>> filteredItems;

    if (filterStatus == ModerationStatus.pending) {
      // Hiển thị cả pending và in_review trong tab "Đang duyệt"
      filteredItems = _historyItems.where((item) {
        final status = (item['moderation'] as ModerationResult).status;
        return status == ModerationStatus.pending || status == ModerationStatus.in_review;
      }).toList();
    } else {
      filteredItems = _historyItems.where((item) => 
          (item['moderation'] as ModerationResult).status == filterStatus).toList();
    }

    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history_toggle_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              filterStatus == ModerationStatus.approved
                  ? 'Không có sản phẩm nào đã được duyệt'
                  : filterStatus == ModerationStatus.rejected
                      ? 'Không có sản phẩm nào bị từ chối'
                      : 'Không có sản phẩm nào đang chờ duyệt',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nếu bạn mới đăng sản phẩm, hệ thống cần một chút thời gian để xử lý',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadModerationHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('Làm mới'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MyProductsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.shopping_bag),
              label: const Text('Xem sản phẩm của tôi'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        final product = item['product'] as Product;
        final moderation = item['moderation'] as ModerationResult;
        final List<String>? images = product.images;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () => _showModerationDetails(product, moderation),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (images != null && images.isNotEmpty && images.first.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: images.first,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image, color: Colors.grey),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[300],
                              child: const Icon(Icons.error, color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(moderation.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(moderation.status),
                    ],
                  ),
                  if (moderation.status == ModerationStatus.rejected && moderation.rejectionReason != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lý do từ chối:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            moderation.rejectionReason!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(ModerationStatus status) {
    Color color;
    IconData icon;
    String text;

    switch (status) {
      case ModerationStatus.approved:
        color = Colors.green;
        icon = Icons.check_circle;
        text = 'Đã duyệt';
        break;
      case ModerationStatus.rejected:
        color = Colors.red;
        icon = Icons.cancel;
        text = 'Từ chối';
        break;
      case ModerationStatus.pending:
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        text = 'Đang duyệt';
        break;
      case ModerationStatus.in_review:
        color = Colors.blue;
        icon = Icons.rate_review;
        text = 'Đang xem xét';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showModerationDetails(Product product, ModerationResult moderation) {
    final List<String>? images = product.images;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Row(
              children: [
                const Text(
                  'Chi tiết kiểm duyệt',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            // Product info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (images != null && images.isNotEmpty && images.first.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: images.first,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
                            .format(product.price),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildStatusBadge(moderation.status),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Moderation details
            const Text(
              'Thông tin kiểm duyệt',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Thời gian:', DateFormat('dd/MM/yyyy HH:mm').format(moderation.createdAt)),
            _buildInfoRow('Trạng thái:', _getStatusText(moderation.status)),
            if (moderation.status == ModerationStatus.rejected && moderation.rejectionReason != null)
              _buildInfoRow('Lý do từ chối:', moderation.rejectionReason!),
            if (moderation.issues != null && moderation.issues!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Các vấn đề được phát hiện:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              ...moderation.issues!.map((issue) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            issue.description,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            const SizedBox(height: 24),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (moderation.status == ModerationStatus.rejected)
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Chỉnh sửa sản phẩm'),
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate to edit product
                        // TODO: Navigate to edit product screen
                      },
                    ),
                  ),
                if (moderation.status == ModerationStatus.approved) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.visibility),
                      label: const Text('Xem sản phẩm'),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(product: product),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _getStatusText(ModerationStatus status) {
    switch (status) {
      case ModerationStatus.approved:
        return 'Đã được phê duyệt';
      case ModerationStatus.rejected:
        return 'Đã bị từ chối';
      case ModerationStatus.pending:
        return 'Đang chờ phê duyệt';
      case ModerationStatus.in_review:
        return 'Đang được xem xét';
    }
  }
} 