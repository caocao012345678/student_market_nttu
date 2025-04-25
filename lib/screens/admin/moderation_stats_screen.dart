import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ModerationStatsScreen extends StatefulWidget {
  const ModerationStatsScreen({Key? key}) : super(key: key);

  @override
  State<ModerationStatsScreen> createState() => _ModerationStatsScreenState();
}

class _ModerationStatsScreenState extends State<ModerationStatsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  String _timeFrame = 'week'; // 'day', 'week', 'month'
  
  // Số liệu thống kê
  int _totalProducts = 0;
  int _approvedProducts = 0;
  int _rejectedProducts = 0;
  int _pendingProducts = 0;
  double _averageScore = 0;
  
  // Dữ liệu biểu đồ
  List<FlSpot> _scoreDataPoints = [];
  List<FlSpot> _volumeDataPoints = [];
  
  // Danh sách vấn đề phổ biến
  List<Map<String, dynamic>> _commonIssues = [];

  @override
  void initState() {
    super.initState();
    _loadModerationStats();
  }
  
  Future<void> _loadModerationStats() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Xác định khoảng thời gian dữ liệu
      DateTime startDate;
      final now = DateTime.now();
      
      switch (_timeFrame) {
        case 'day':
          startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'week':
        default:
          startDate = DateTime(now.year, now.month, now.day - 7);
          break;
      }
      
      // Truy vấn dữ liệu kiểm duyệt
      final QuerySnapshot moderationSnapshot = await _firestore
          .collection('moderation_results')
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .orderBy('createdAt')
          .get();
      
      if (moderationSnapshot.docs.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Đặt lại các biến thống kê
      int approved = 0;
      int rejected = 0;
      int pending = 0;
      int totalScore = 0;
      
      final List<FlSpot> scorePoints = [];
      final List<FlSpot> volumePoints = [];
      final Map<String, int> issueFrequency = {};
      
      // Tạo map theo thời gian
      final Map<String, List<Map<String, dynamic>>> dataByDay = {};
      
      // Xử lý dữ liệu
      for (var doc in moderationSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] as String? ?? 'pending';
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        final score = data['totalScore'] as int? ?? 0;
        
        // Đếm theo trạng thái
        if (status == 'approved') {
          approved++;
        } else if (status == 'rejected') {
          rejected++;
        } else {
          pending++;
        }
        
        // Tổng điểm
        totalScore += score;
        
        // Đếm vấn đề
        if (data['issues'] != null) {
          final issues = data['issues'] as List<dynamic>;
          for (var issue in issues) {
            final description = issue['description'] as String? ?? '';
            if (description.isNotEmpty) {
              issueFrequency[description] = (issueFrequency[description] ?? 0) + 1;
            }
          }
        }
        
        // Nhóm theo ngày
        final dayKey = DateFormat('yyyy-MM-dd').format(createdAt);
        if (!dataByDay.containsKey(dayKey)) {
          dataByDay[dayKey] = [];
        }
        dataByDay[dayKey]!.add(data);
      }
      
      // Sắp xếp ngày theo thứ tự
      final sortedDays = dataByDay.keys.toList()..sort();
      
      // Tạo điểm dữ liệu cho biểu đồ
      for (int i = 0; i < sortedDays.length; i++) {
        final day = sortedDays[i];
        final dayData = dataByDay[day]!;
        
        // Tính điểm trung bình trong ngày
        int totalDayScore = 0;
        for (var data in dayData) {
          totalDayScore += data['totalScore'] as int? ?? 0;
        }
        final averageDayScore = dayData.isNotEmpty ? totalDayScore / dayData.length : 0;
        
        // Thêm điểm vào biểu đồ
        scorePoints.add(FlSpot(i.toDouble(), averageDayScore.toDouble()));
        volumePoints.add(FlSpot(i.toDouble(), dayData.length.toDouble()));
      }
      
      // Sắp xếp vấn đề theo tần suất
      final sortedIssues = issueFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      // Lấy 5 vấn đề phổ biến nhất
      final top5Issues = sortedIssues.take(5).map((entry) => {
        'description': entry.key,
        'count': entry.value,
      }).toList();
      
      // Cập nhật state
      setState(() {
        _totalProducts = moderationSnapshot.docs.length;
        _approvedProducts = approved;
        _rejectedProducts = rejected;
        _pendingProducts = pending;
        _averageScore = _totalProducts > 0 ? totalScore / _totalProducts : 0;
        _scoreDataPoints = scorePoints;
        _volumeDataPoints = volumePoints;
        _commonIssues = top5Issues;
        _isLoading = false;
      });
    } catch (e) {
      print('Lỗi khi tải dữ liệu thống kê: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê kiểm duyệt'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildStatsContent(),
    );
  }
  
  Widget _buildStatsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bộ lọc thời gian
          _buildTimeFrameSelector(),
          const SizedBox(height: 16),
          
          // Thẻ tổng quan
          _buildOverviewCard(),
          const SizedBox(height: 16),
          
          // Biểu đồ điểm số
          _buildScoreChart(),
          const SizedBox(height: 16),
          
          // Biểu đồ khối lượng
          _buildVolumeChart(),
          const SizedBox(height: 16),
          
          // Vấn đề phổ biến
          _buildCommonIssuesCard(),
        ],
      ),
    );
  }
  
  Widget _buildTimeFrameSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildTimeFrameButton('day', 'Ngày'),
            _buildTimeFrameButton('week', 'Tuần'),
            _buildTimeFrameButton('month', 'Tháng'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTimeFrameButton(String value, String label) {
    final isSelected = _timeFrame == value;
    
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _timeFrame = value;
        });
        _loadModerationStats();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue[900] : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }
  
  Widget _buildOverviewCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tổng quan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Hàng đầu tiên
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  label: 'Tổng số',
                  value: _totalProducts.toString(),
                  icon: Icons.bar_chart,
                  color: Colors.blue,
                ),
                _buildStatItem(
                  label: 'Đã duyệt',
                  value: _approvedProducts.toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Hàng thứ hai
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  label: 'Từ chối',
                  value: _rejectedProducts.toString(),
                  icon: Icons.cancel,
                  color: Colors.red,
                ),
                _buildStatItem(
                  label: 'Chờ xử lý',
                  value: _pendingProducts.toString(),
                  icon: Icons.hourglass_empty,
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Điểm trung bình
            Center(
              child: Column(
                children: [
                  Text(
                    'Điểm trung bình',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_averageScore.toStringAsFixed(1)}/100',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(_averageScore),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildScoreChart() {
    if (_scoreDataPoints.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Không có dữ liệu điểm số'),
        ),
      );
    }
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Điểm trung bình theo thời gian',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: _scoreDataPoints,
                      isCurved: true,
                      color: Colors.blue[900],
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue[200]!.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVolumeChart() {
    if (_volumeDataPoints.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Không có dữ liệu khối lượng'),
        ),
      );
    }
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Khối lượng kiểm duyệt theo thời gian',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  minY: 0,
                  barGroups: List.generate(
                    _volumeDataPoints.length,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: _volumeDataPoints[index].y,
                          color: Colors.greenAccent,
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCommonIssuesCard() {
    if (_commonIssues.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Không có dữ liệu về vấn đề phổ biến'),
        ),
      );
    }
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vấn đề phổ biến',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _commonIssues.length,
              itemBuilder: (context, index) {
                final issue = _commonIssues[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red[100],
                    child: Text('${index + 1}'),
                  ),
                  title: Text(issue['description']),
                  trailing: Text(
                    '${issue['count']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getScoreColor(double score) {
    if (score >= 80) {
      return Colors.green;
    } else if (score >= 60) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
} 