import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ai_agent_service.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../config/app_colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_indicator.dart';

class AIAgentDashboardScreen extends StatefulWidget {
  static const routeName = '/admin/ai-agent-dashboard';
  
  const AIAgentDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AIAgentDashboardScreen> createState() => _AIAgentDashboardScreenState();
}

class _AIAgentDashboardScreenState extends State<AIAgentDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Product> _pendingProducts = [];
  
  // Thêm timer để cập nhật định kỳ
  late final _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchPendingProducts();
    
    // Thiết lập auto refresh mỗi 15 giây
    _refreshTimer = Stream.periodic(Duration(seconds: 15)).listen((_) {
      _fetchPendingProducts();
    });
    
    // Đăng ký lắng nghe thay đổi AI Agent
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final aiAgentService = Provider.of<AIAgentService>(context, listen: false);
      aiAgentService.addListener(_updateState);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    final aiAgentService = Provider.of<AIAgentService>(context, listen: false);
    aiAgentService.removeListener(_updateState);
    _tabController.dispose();
    super.dispose();
  }

  // Cập nhật state khi có thông báo từ service
  void _updateState() {
    if (mounted) {
      setState(() {
        // Chỉ cập nhật state, dữ liệu thực tế lấy từ service ở build
      });
    }
  }

  Future<void> _fetchPendingProducts() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final productService = Provider.of<ProductService>(context, listen: false);
      final products = await productService.getProductsByStatus('pending_review');
      
      if (!mounted) return;
      setState(() {
        _pendingProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Lỗi khi tải sản phẩm đang chờ duyệt: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleAgentStatus() {
    final aiAgentService = Provider.of<AIAgentService>(context, listen: false);
    if (aiAgentService.isRunning) {
      aiAgentService.stop();
    } else {
      aiAgentService.start();
    }
  }

  void _resetStats() {
    final aiAgentService = Provider.of<AIAgentService>(context, listen: false);
    aiAgentService.resetStats();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã đặt lại thống kê')),
    );
  }

  void _clearLogs() {
    final aiAgentService = Provider.of<AIAgentService>(context, listen: false);
    aiAgentService.clearLog();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã xóa nhật ký')),
    );
  }

  Future<void> _processSelectedProduct(Product product) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final aiAgentService = Provider.of<AIAgentService>(context, listen: false);
      await aiAgentService.processProduct(product);
      await _fetchPendingProducts(); // Refresh list after processing
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xử lý sản phẩm: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiAgentService = Provider.of<AIAgentService>(context);
    final isRunning = aiAgentService.isRunning;
    final isProcessing = aiAgentService.isProcessing;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'AI Agent Dashboard',
        showBackButton: true,
      ),
      body: _isLoading
          ? Center(child: LoadingIndicator())
          : Column(
              children: [
                _buildStatusBar(aiAgentService),
                _buildStatisticsCards(aiAgentService),
                TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: 'Nhật ký'),
                    Tab(text: 'Sản phẩm chờ duyệt'),
                    Tab(text: 'Cài đặt'),
                  ],
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.primary,
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLogsTab(aiAgentService),
                      _buildPendingProductsTab(),
                      _buildSettingsTab(aiAgentService),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleAgentStatus,
        backgroundColor: isRunning ? Colors.red : AppColors.primary,
        icon: Icon(isRunning ? Icons.stop : Icons.play_arrow),
        label: Text(isRunning ? 'Dừng Agent' : 'Khởi động Agent'),
      ),
    );
  }

  Widget _buildStatusBar(AIAgentService aiAgentService) {
    final isRunning = aiAgentService.isRunning;
    final isProcessing = aiAgentService.isProcessing;

    return Container(
      padding: EdgeInsets.all(16),
      color: isRunning ? Colors.green.shade100 : Colors.grey.shade200,
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRunning
                  ? (isProcessing ? Colors.orange : Colors.green)
                  : Colors.grey,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              isRunning
                  ? (isProcessing
                      ? 'Đang xử lý sản phẩm...'
                      : 'Đang chạy và chờ sản phẩm mới')
                  : 'AI Agent đang dừng',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (isRunning)
            TextButton.icon(
              onPressed: _toggleAgentStatus,
              icon: Icon(Icons.stop, color: Colors.red),
              label: Text('Dừng', style: TextStyle(color: Colors.red)),
            )
          else
            TextButton.icon(
              onPressed: _toggleAgentStatus,
              icon: Icon(Icons.play_arrow, color: Colors.green),
              label: Text('Bắt đầu', style: TextStyle(color: Colors.green)),
            ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(AIAgentService aiAgentService) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thống kê duyệt bài',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () => setState(() {}), // Force refresh UI
                tooltip: 'Refresh thống kê',
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Tổng xử lý',
                  value: aiAgentService.totalProcessed.toString(),
                  color: Colors.blue,
                  icon: Icons.analytics,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  title: 'Phê duyệt',
                  value: aiAgentService.approved.toString(),
                  color: Colors.green,
                  icon: Icons.check_circle,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  title: 'Từ chối',
                  value: aiAgentService.rejected.toString(),
                  color: Colors.red,
                  icon: Icons.cancel,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  title: 'Chuyển duyệt',
                  value: aiAgentService.flaggedForReview.toString(),
                  color: Colors.orange,
                  icon: Icons.flag,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _resetStats,
              icon: Icon(Icons.refresh, size: 18),
              label: Text('Đặt lại thống kê'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsTab(AIAgentService aiAgentService) {
    final logs = aiAgentService.processingLog;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nhật ký hoạt động',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: _clearLogs,
                icon: Icon(Icons.clear_all, size: 18),
                label: Text('Xóa nhật ký'),
              ),
            ],
          ),
        ),
        Expanded(
          child: logs.isEmpty
              ? Center(
                  child: Text(
                    'Chưa có hoạt động nào được ghi nhận',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return ListTile(
                      dense: true,
                      title: Text(
                        log,
                        style: TextStyle(fontSize: 14),
                      ),
                      leading: Icon(Icons.circle, size: 8, color: Colors.grey),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPendingProductsTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sản phẩm đang chờ duyệt (${_pendingProducts.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _fetchPendingProducts,
              ),
            ],
          ),
        ),
        Expanded(
          child: _pendingProducts.isEmpty
              ? Center(
                  child: Text(
                    'Không có sản phẩm nào đang chờ duyệt',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchPendingProducts,
                  child: ListView.builder(
                    itemCount: _pendingProducts.length,
                    itemBuilder: (context, index) {
                      final product = _pendingProducts[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: product.images.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    product.images.first,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey.shade200,
                                      child: Icon(Icons.image_not_supported,
                                          color: Colors.grey),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey.shade200,
                                  child: Icon(Icons.image,
                                      color: Colors.grey.shade400),
                                ),
                          title: Text(
                            product.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            product.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.play_circle_filled,
                                color: AppColors.primary),
                            onPressed: () => _processSelectedProduct(product),
                            tooltip: 'Xử lý sản phẩm này',
                          ),
                          onTap: () {
                            // Mở chi tiết sản phẩm
                          },
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab(AIAgentService aiAgentService) {
    return SingleChildScrollView( // Wrap the content in SingleChildScrollView
      padding: EdgeInsets.all(16), // Apply padding here instead of the Column
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cài đặt AI Agent',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Tự động khởi động khi ứng dụng mở'),
                  subtitle: Text('AI Agent sẽ tự động bắt đầu khi ứng dụng khởi động'),
                  value: false, // Kết nối với cài đặt thực tế
                  onChanged: (value) {
                    // Cập nhật cài đặt
                  },
                ),
                Divider(),
                SwitchListTile(
                  title: Text('Tự động duyệt sản phẩm'),
                  subtitle: Text('Tự động duyệt sản phẩm với độ tin cậy cao'),
                  value: true, // Kết nối với cài đặt thực tế
                  onChanged: (value) {
                    // Cập nhật cài đặt
                  },
                ),
                Divider(),
                SwitchListTile(
                  title: Text('Gửi thông báo cho người dùng'),
                  subtitle: Text('Thông báo kết quả duyệt sản phẩm cho người đăng'),
                  value: true, // Kết nối với cài đặt thực tế
                  onChanged: (value) {
                    // Cập nhật cài đặt
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Cấu hình máy chủ LM Studio',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Địa chỉ máy chủ',
                      hintText: 'http://localhost:1234/v1',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: 'http://localhost:1234/v1',
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'API Key (nếu có)',
                      hintText: 'Để trống nếu không sử dụng',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Lưu cấu hình
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã lưu cấu hình máy chủ')),
                      );
                    },
                    child: Text('Lưu cấu hình'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 