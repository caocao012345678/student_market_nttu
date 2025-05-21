import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../ai_agent_service.dart';
import '../models/review_decision.dart';
import '../../config/app_colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/loading_indicator.dart';

class AIAgentReportScreen extends StatefulWidget {
  static const routeName = '/admin/ai-agent-report';
  
  const AIAgentReportScreen({Key? key}) : super(key: key);

  @override
  State<AIAgentReportScreen> createState() => _AIAgentReportScreenState();
}

class _AIAgentReportScreenState extends State<AIAgentReportScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  
  // Thống kê hiệu suất
  Map<String, int> _decisionCounts = {
    'approved': 0,
    'rejected': 0,
    'flaggedForReview': 0,
    'total': 0,
  };
  
  // Thống kê theo ngày
  List<Map<String, dynamic>> _dailyStats = [];
  
  // Thống kê về lý do từ chối
  Map<String, int> _rejectionReasons = {};
  
  // Khoảng thời gian báo cáo
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }
  
  Future<void> _fetchReportData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Reset các biến thống kê
      _decisionCounts = {
        'approved': 0,
        'rejected': 0,
        'flaggedForReview': 0,
        'total': 0,
      };
      _dailyStats = [];
      _rejectionReasons = {};
      
      // Truy vấn dữ liệu từ Firestore
      final querySnapshot = await _firestore
        .collection('product_reviews')
        .where('reviewedBy', isEqualTo: 'ai_agent')
        .where('reviewedAt', isGreaterThanOrEqualTo: _startDate)
        .where('reviewedAt', isLessThanOrEqualTo: _endDate)
        .orderBy('reviewedAt', descending: true)
        .get();
      
      // Biến tạm lưu thống kê theo ngày
      Map<String, Map<String, int>> dailyData = {};
      
      // Xử lý dữ liệu
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final decision = data['decision'] as String;
        final reviewedAt = (data['reviewedAt'] as Timestamp).toDate();
        final dateStr = DateFormat('yyyy-MM-dd').format(reviewedAt);
        
        // Cập nhật tổng số quyết định
        _decisionCounts['total'] = (_decisionCounts['total'] ?? 0) + 1;
        _decisionCounts[decision] = (_decisionCounts[decision] ?? 0) + 1;
        
        // Cập nhật thống kê theo ngày
        if (!dailyData.containsKey(dateStr)) {
          dailyData[dateStr] = {
            'approved': 0,
            'rejected': 0,
            'flaggedForReview': 0,
            'total': 0,
          };
        }
        dailyData[dateStr]!['total'] = (dailyData[dateStr]!['total'] ?? 0) + 1;
        dailyData[dateStr]![decision] = (dailyData[dateStr]![decision] ?? 0) + 1;
        
        // Thống kê lý do từ chối
        if (decision == 'rejected') {
          final reason = data['reason'] as String;
          _rejectionReasons[reason] = (_rejectionReasons[reason] ?? 0) + 1;
        }
      }
      
      // Chuyển đổi thống kê theo ngày thành danh sách để hiển thị
      dailyData.forEach((date, counts) {
        _dailyStats.add({
          'date': date,
          ...counts,
        });
      });
      
      // Sắp xếp theo ngày
      _dailyStats.sort((a, b) => a['date'].compareTo(b['date']));
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Lỗi khi tải dữ liệu báo cáo: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      helpText: 'Chọn khoảng thời gian báo cáo',
      cancelText: 'HỦY',
      confirmText: 'CHỌN',
      saveText: 'CHỌN',
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      
      _fetchReportData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Báo Cáo AI Agent',
        showBackButton: true,
      ),
      body: _isLoading
          ? Center(child: LoadingIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateRangeSelector(),
                    SizedBox(height: 24),
                    _buildPerformanceOverview(),
                    SizedBox(height: 24),
                    _buildDailyChart(),
                    SizedBox(height: 24),
                    _buildRejectionReasonsPieChart(),
                    SizedBox(height: 24),
                    _buildRecentDecisions(),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildDateRangeSelector() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thống kê hoạt động',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Từ ${dateFormat.format(_startDate)} đến ${dateFormat.format(_endDate)}',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _selectDateRange,
                  icon: Icon(Icons.date_range),
                  label: Text('Thay đổi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPerformanceOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tổng quan hiệu suất',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Tổng xử lý',
                    value: _decisionCounts['total'].toString(),
                    color: Colors.blue,
                    icon: Icons.analytics,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    title: 'Phê duyệt',
                    value: _decisionCounts['approved'].toString(),
                    color: Colors.green,
                    icon: Icons.check_circle,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    title: 'Từ chối',
                    value: _decisionCounts['rejected'].toString(),
                    color: Colors.red,
                    icon: Icons.cancel,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    title: 'Chuyển kiểm duyệt',
                    value: _decisionCounts['flaggedForReview'].toString(),
                    color: Colors.orange,
                    icon: Icons.flag,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Tỷ lệ xử lý',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            _buildApprovalRatioBar(),
          ],
        ),
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
        padding: const EdgeInsets.all(12),
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
  
  Widget _buildApprovalRatioBar() {
    final total = _decisionCounts['total'] ?? 0;
    if (total == 0) {
      return Container(
        height: 40,
        alignment: Alignment.center,
        child: Text('Không có dữ liệu'),
      );
    }
    
    final approved = _decisionCounts['approved'] ?? 0;
    final rejected = _decisionCounts['rejected'] ?? 0;
    final flagged = _decisionCounts['flaggedForReview'] ?? 0;
    
    final approvedPercent = approved / total;
    final rejectedPercent = rejected / total;
    final flaggedPercent = flagged / total;
    
    return Column(
      children: [
        Container(
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Expanded(
                flex: (approvedPercent * 100).round(),
                child: Container(color: Colors.green),
              ),
              Expanded(
                flex: (rejectedPercent * 100).round(),
                child: Container(color: Colors.red),
              ),
              Expanded(
                flex: (flaggedPercent * 100).round(),
                child: Container(color: Colors.orange),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildLegendItem('Phê duyệt', Colors.green, '${(approvedPercent * 100).round()}%'),
            _buildLegendItem('Từ chối', Colors.red, '${(rejectedPercent * 100).round()}%'),
            _buildLegendItem('Chuyển xem xét', Colors.orange, '${(flaggedPercent * 100).round()}%'),
          ],
        ),
      ],
    );
  }
  
  Widget _buildLegendItem(String label, Color color, String percentage) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        SizedBox(width: 4),
        Text('$label: $percentage'),
      ],
    );
  }
  
  Widget _buildDailyChart() {
    if (_dailyStats.isEmpty) {
      return Card(
        child: Container(
          height: 300,
          padding: EdgeInsets.all(16),
          alignment: Alignment.center,
          child: Text('Không có dữ liệu thống kê theo ngày'),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thống kê theo ngày',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _dailyStats.map((e) => e['total'] as int).reduce((a, b) => a > b ? a : b) * 1.2,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < _dailyStats.length) {
                            final date = _dailyStats[value.toInt()]['date'].toString().substring(5);
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                date,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return Text('');
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    drawHorizontalLine: true,
                    horizontalInterval: 1,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                      left: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  barGroups: List.generate(
                    _dailyStats.length,
                    (index) {
                      final data = _dailyStats[index];
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: data['approved'] * 1.0,
                            color: Colors.green,
                            width: 15,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                          BarChartRodData(
                            toY: data['rejected'] * 1.0,
                            color: Colors.red,
                            width: 15,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                          BarChartRodData(
                            toY: data['flaggedForReview'] * 1.0,
                            color: Colors.orange,
                            width: 15,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Phê duyệt', Colors.green, ''),
                SizedBox(width: 16),
                _buildLegendItem('Từ chối', Colors.red, ''),
                SizedBox(width: 16),
                _buildLegendItem('Chuyển xem xét', Colors.orange, ''),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRejectionReasonsPieChart() {
    if (_rejectionReasons.isEmpty) {
      return Card(
        child: Container(
          height: 300,
          padding: EdgeInsets.all(16),
          alignment: Alignment.center,
          child: Text('Không có dữ liệu về lý do từ chối'),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lý do từ chối',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 300,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: _getRejectionReasonSections(),
                ),
              ),
            ),
            SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _rejectionReasons.entries.map((entry) {
                final color = _getColorForReasonIndex(
                  _rejectionReasons.keys.toList().indexOf(entry.key),
                );
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: _buildLegendItem(
                    entry.key,
                    color,
                    '${entry.value} lần',
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  List<PieChartSectionData> _getRejectionReasonSections() {
    final reasons = _rejectionReasons.entries.toList();
    final total = reasons.fold<int>(0, (sum, entry) => sum + entry.value);
    
    return List.generate(reasons.length, (i) {
      final data = reasons[i];
      final percent = data.value / total;
      final color = _getColorForReasonIndex(i);
      
      return PieChartSectionData(
        color: color,
        value: data.value.toDouble(),
        title: '${(percent * 100).round()}%',
        radius: 100,
        titleStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }
  
  Color _getColorForReasonIndex(int index) {
    final colors = [
      Colors.red.shade700,
      Colors.red.shade500,
      Colors.red.shade300,
      Colors.orange.shade700,
      Colors.orange.shade500,
      Colors.orange.shade300,
      Colors.amber.shade700,
      Colors.amber.shade500,
      Colors.amber.shade300,
    ];
    
    return colors[index % colors.length];
  }
  
  Widget _buildRecentDecisions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quyết định gần đây',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                .collection('product_reviews')
                .where('reviewedBy', isEqualTo: 'ai_agent')
                .orderBy('reviewedAt', descending: true)
                .limit(10)
                .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: LoadingIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    height: 100,
                    alignment: Alignment.center,
                    child: Text('Không có quyết định nào gần đây'),
                  );
                }
                
                final decisions = snapshot.data!.docs;
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: decisions.length,
                  itemBuilder: (context, index) {
                    final data = decisions[index].data() as Map<String, dynamic>;
                    final decision = data['decision'] as String;
                    final productId = data['productId'] as String;
                    final reviewedAt = (data['reviewedAt'] as Timestamp).toDate();
                    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(reviewedAt);
                    
                    IconData icon;
                    Color color;
                    
                    switch (decision) {
                      case 'approved':
                        icon = Icons.check_circle;
                        color = Colors.green;
                        break;
                      case 'rejected':
                        icon = Icons.cancel;
                        color = Colors.red;
                        break;
                      case 'flaggedForReview':
                        icon = Icons.flag;
                        color = Colors.orange;
                        break;
                      default:
                        icon = Icons.help;
                        color = Colors.grey;
                    }
                    
                    return ListTile(
                      leading: Icon(icon, color: color, size: 28),
                      title: Text('Sản phẩm: $productId'),
                      subtitle: Text(
                        'Lý do: ${data['reason'] ?? 'Không có lý do'}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(formattedDate),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 