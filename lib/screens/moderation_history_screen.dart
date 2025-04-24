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
            Tab(text: 'Tất cả'),
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
                // Tab Tất cả
                _buildHistoryList(null),
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
    final filteredItems = filterStatus == null
        ? _historyItems
        : _historyItems.where((item) => 
            (item['moderation'] as ModerationResult).status == filterStatus).toList();

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
                      : 'Không có lịch sử kiểm duyệt',
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
                      if (product.images.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: product.images.first,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
                                  .format(product.price),
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(moderation.createdAt),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusChip(moderation.status),
                    ],
                  ),
                  if (moderation.status == ModerationStatus.rejected &&
                      moderation.rejectionReason != null &&
                      moderation.rejectionReason!.isNotEmpty) ...[
                    const Divider(),
                    Text(
                      'Lý do: ${moderation.rejectionReason}',
                      style: const TextStyle(color: Colors.red),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildScoreBadge('Nội dung', moderation.contentScore),
                      _buildScoreBadge('Hình ảnh', moderation.imageScore),
                      _buildScoreBadge('Tuân thủ', moderation.complianceScore),
                      _buildScoreBadge('Tổng', moderation.totalScore, true),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(ModerationStatus status) {
    String label;
    Color color;

    switch (status) {
      case ModerationStatus.approved:
        label = 'Đã duyệt';
        color = Colors.green;
        break;
      case ModerationStatus.rejected:
        label = 'Bị từ chối';
        color = Colors.red;
        break;
      case ModerationStatus.in_review:
        label = 'Đang xem xét';
        color = Colors.orange;
        break;
      case ModerationStatus.pending:
      default:
        label = 'Đang chờ';
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildScoreBadge(String label, int score, [bool isTotal = false]) {
    Color getScoreColor(int value) {
      if (value >= 80) return Colors.green;
      if (value >= 60) return Colors.orange;
      return Colors.red;
    }

    return Tooltip(
      message: '$label: $score/100',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isTotal ? getScoreColor(score).withOpacity(0.2) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isTotal ? getScoreColor(score) : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isTotal ? getScoreColor(score) : Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '$score',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                color: getScoreColor(score),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showModerationDetails(Product product, ModerationResult moderationResult) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chi tiết kiểm duyệt: ${product.title}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Trạng thái:'),
                subtitle: Text(
                  moderationResult.status == ModerationStatus.approved ? 'Đã duyệt' :
                  moderationResult.status == ModerationStatus.rejected ? 'Bị từ chối' :
                  moderationResult.status == ModerationStatus.in_review ? 'Đang xem xét' : 'Đang chờ duyệt',
                  style: TextStyle(
                    color: moderationResult.status == ModerationStatus.approved ? Colors.green :
                    moderationResult.status == ModerationStatus.rejected ? Colors.red : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                title: const Text('Thời gian:'),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy - HH:mm').format(moderationResult.createdAt),
                ),
              ),
              if (moderationResult.rejectionReason != null && moderationResult.rejectionReason!.isNotEmpty) 
                ListTile(
                  title: const Text('Lý do từ chối:'),
                  subtitle: Text(moderationResult.rejectionReason!),
                ),
              const Divider(),
              const Text('Điểm đánh giá:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildScoreItem('Nội dung', moderationResult.contentScore / 10),
              _buildScoreItem('Hình ảnh', moderationResult.imageScore / 10),
              _buildScoreItem('Tuân thủ', moderationResult.complianceScore / 10),
              _buildScoreItem('Tổng', moderationResult.totalScore / 10),
              if (moderationResult.issues != null && moderationResult.issues!.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('Vấn đề được phát hiện:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                ...moderationResult.issues!.map((issue) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        issue.severity == 'high' ? Icons.error : 
                        issue.severity == 'medium' ? Icons.warning : Icons.info_outline,
                        color: issue.severity == 'high' ? Colors.red : 
                              issue.severity == 'medium' ? Colors.orange : Colors.blue,
                        size: 16
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(issue.description)),
                    ],
                  ),
                )).toList(),
              ],
              if (moderationResult.suggestedTags != null && moderationResult.suggestedTags!.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('Thẻ gợi ý:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: moderationResult.suggestedTags!.map((tag) => Chip(
                    label: Text(tag, style: const TextStyle(fontSize: 12)),
                    backgroundColor: Colors.blue[50],
                    visualDensity: VisualDensity.compact,
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (product.status == ProductStatus.rejected)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Navigate to edit product screen to fix issues
              },
              child: const Text('Chỉnh sửa sản phẩm'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(product: product),
                ),
              ).then((_) => Navigator.of(context).pop());
            },
            child: const Text('Xem sản phẩm'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, double score) {
    Color color;
    if (score >= 8) {
      color = Colors.green;
    } else if (score >= 6) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Text('$label: '),
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Text('/10'),
        ],
      ),
    );
  }
} 