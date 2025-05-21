import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_market_nttu/ai_agent/ai_agent_service.dart';
import 'package:student_market_nttu/services/user_service.dart';
import 'package:student_market_nttu/services/product_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIAgentDashboardScreen extends StatefulWidget {
  static const routeName = '/admin/ai-agent-dashboard';
  
  const AIAgentDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AIAgentDashboardScreen> createState() => _AIAgentDashboardScreenState();
}

class _AIAgentDashboardScreenState extends State<AIAgentDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isAdmin = false;
  bool _isLoading = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkAdminAccess();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _checkAdminAccess() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final userService = Provider.of<UserService>(context, listen: false);
      final isAdmin = await userService.isCurrentUserAdmin();

      setState(() {
        _isAdmin = isAdmin;
        _isLoading = false;
      });

      if (!isAdmin && mounted) {
        setState(() {
          _errorMessage = 'Bạn không có quyền truy cập vào trang này';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bạn không có quyền truy cập vào trang quản trị'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Đã xảy ra lỗi: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('AI Agent - Kiểm duyệt thông minh'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isAdmin || _errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('AI Agent - Kiểm duyệt thông minh'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        body: Center(
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
                _errorMessage ?? 'Bạn không có quyền truy cập vào trang này',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Agent - Kiểm duyệt thông minh'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Bảng điều khiển'),
            Tab(text: 'Log hoạt động'),
            Tab(text: 'Cấu hình'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          _buildLogTab(),
          _buildConfigTab(),
        ],
      ),
    );
  }
  
  Widget _buildDashboardTab() {
    final aiAgentService = Provider.of<AIAgentService>(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trạng thái AI Agent
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        aiAgentService.isRunning
                            ? Icons.play_circle_filled
                            : Icons.pause_circle_filled,
                        size: 36,
                        color: aiAgentService.isRunning ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trạng thái: ${aiAgentService.isRunning ? 'Đang chạy' : 'Tạm dừng'}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            aiAgentService.isProcessing
                                ? 'Đang xử lý bài đăng...'
                                : 'Đang chờ bài đăng mới',
                            style: TextStyle(
                              fontSize: 14,
                              color: aiAgentService.isProcessing ? Colors.blue : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: aiAgentService.isRunning
                            ? null
                            : () => aiAgentService.start(),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Bắt đầu'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white60,
                          disabledBackgroundColor: Colors.green.withOpacity(0.6),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: !aiAgentService.isRunning
                            ? null
                            : () => aiAgentService.stop(),
                        icon: const Icon(Icons.stop),
                        label: const Text('Dừng'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white60,
                          disabledBackgroundColor: Colors.red.withOpacity(0.6),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => aiAgentService.resetStats(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset thống kê'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Biểu đồ thống kê
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thống kê kiểm duyệt',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Thống kê số lượng
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        'Đã xử lý',
                        aiAgentService.totalProcessed.toString(),
                        Icons.checklist,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Đã duyệt',
                        aiAgentService.approved.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Đã từ chối',
                        aiAgentService.rejected.toString(),
                        Icons.cancel,
                        Colors.red,
                      ),
                      _buildStatCard(
                        'Cần xem xét',
                        aiAgentService.flaggedForReview.toString(),
                        Icons.flag,
                        Colors.orange,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Biểu đồ tròn
                  SizedBox(
                    height: 200,
                    child: aiAgentService.totalProcessed > 0 
                      ? _buildPieChart(aiAgentService)
                      : const Center(
                          child: Text(
                            'Chưa có dữ liệu thống kê',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Đang xử lý
          if (aiAgentService.isProcessing)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          child: const CircularProgressIndicator(
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Đang xử lý bài đăng',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 12),
                    const Text(
                      'AI Agent đang xử lý bài đăng. Quá trình này có thể mất vài giây.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildLogTab() {
    final aiAgentService = Provider.of<AIAgentService>(context);
    final logEntries = aiAgentService.processingLog;
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                'Log hoạt động',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => aiAgentService.clearLog(),
                icon: const Icon(Icons.delete),
                label: const Text('Xóa log'),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: logEntries.isEmpty
              ? const Center(
                  child: Text(
                    'Chưa có hoạt động nào được ghi lại',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: logEntries.length,
                  itemBuilder: (context, index) {
                    final logEntry = logEntries[index];
                    
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      title: Text(
                        logEntry,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildConfigTab() {
    final aiAgentService = Provider.of<AIAgentService>(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cấu hình AI Agent',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin LM Studio',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text('Server URL'),
                    subtitle: Text(
                      dotenv.env['LM_LOCAL_SERVER'] ?? 'Chưa cấu hình',
                    ),
                    leading: const Icon(Icons.computer),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('LLM Model'),
                    subtitle: Text(
                      dotenv.env['LM_API_LLM_IDENTIFIER'] ?? 'Chưa cấu hình',
                    ),
                    leading: const Icon(Icons.text_fields),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('VLM Model'),
                    subtitle: Text(
                      dotenv.env['LM_API_VLM_IDENTIFIER'] ?? 'Chưa cấu hình',
                    ),
                    leading: const Icon(Icons.image),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Hướng dẫn cấu hình',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Để thay đổi cấu hình của AI Agent:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('1. Dừng AI Agent nếu đang chạy'),
                  Text('2. Chỉnh sửa file .env trong thư mục gốc của dự án'),
                  Text('3. Khởi động lại ứng dụng để áp dụng thay đổi'),
                  SizedBox(height: 16),
                  Text(
                    'Cấu hình trong file .env:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('LM_LOCAL_SERVER=http://localhost:1234'),
                  Text('LM_API_LLM_IDENTIFIER=YOUR_LLM_MODEL'),
                  Text('LM_API_VLM_IDENTIFIER=YOUR_VLM_MODEL'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          Icon(
            icon,
            size: 30,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPieChart(AIAgentService aiAgentService) {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            color: Colors.green,
            value: aiAgentService.approved.toDouble(),
            title: 'Duyệt',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            color: Colors.red,
            value: aiAgentService.rejected.toDouble(),
            title: 'Từ chối',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            color: Colors.orange,
            value: aiAgentService.flaggedForReview.toDouble(),
            title: 'Xem xét',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        startDegreeOffset: 180,
      ),
    );
  }
} 