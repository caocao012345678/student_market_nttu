import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_market_nttu/models/moderation_result.dart';
import 'package:student_market_nttu/models/product.dart';
import 'package:student_market_nttu/services/product_service.dart';
import 'package:intl/intl.dart';

class ModerationResultScreen extends StatelessWidget {
  final String productId;
  
  const ModerationResultScreen({Key? key, required this.productId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả kiểm duyệt'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<ModerationResult?>(
        future: Provider.of<ProductService>(context, listen: false).getProductModerationInfo(productId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('Không tìm thấy thông tin kiểm duyệt'),
            );
          }
          
          final result = snapshot.data!;
          return _buildModerationResultView(context, result);
        },
      ),
    );
  }
  
  Widget _buildModerationResultView(BuildContext context, ModerationResult result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(context, result),
          const SizedBox(height: 16),
          _buildScoreSection(context, result),
          const SizedBox(height: 16),
          if (result.issues != null && result.issues!.isNotEmpty)
            _buildIssuesSection(context, result),
          const SizedBox(height: 16),
          if (result.suggestedTags != null && result.suggestedTags!.isNotEmpty)
            _buildSuggestedTagsSection(context, result),
          const SizedBox(height: 16),
          _buildTimelineSection(context, result),
        ],
      ),
    );
  }
  
  Widget _buildStatusCard(BuildContext context, ModerationResult result) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (result.status) {
      case ModerationStatus.approved:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Đã phê duyệt';
        break;
      case ModerationStatus.rejected:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Bị từ chối';
        break;
      case ModerationStatus.in_review:
        statusColor = Colors.amber;
        statusIcon = Icons.hourglass_top;
        statusText = 'Đang xem xét';
        break;
      case ModerationStatus.pending:
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Đang chờ xử lý';
        break;
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              statusIcon,
              size: 48,
              color: statusColor,
            ),
            const SizedBox(height: 8),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 8),
            if (result.rejectionReason != null && result.rejectionReason!.isNotEmpty)
              Text(
                result.rejectionReason!,
                style: const TextStyle(
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildScoreSection(BuildContext context, ModerationResult result) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Điểm đánh giá',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildScoreIndicator('Tổng điểm', result.totalScore),
            const SizedBox(height: 8),
            _buildScoreIndicator('Nội dung', result.contentScore),
            const SizedBox(height: 8),
            _buildScoreIndicator('Hình ảnh', result.imageScore),
            const SizedBox(height: 8),
            _buildScoreIndicator('Tuân thủ', result.complianceScore),
          ],
        ),
      ),
    );
  }
  
  Widget _buildScoreIndicator(String label, int score) {
    Color progressColor;
    if (score >= 80) {
      progressColor = Colors.green;
    } else if (score >= 60) {
      progressColor = Colors.amber;
    } else {
      progressColor = Colors.red;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('$score/100'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: score / 100,
          minHeight: 8,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
  
  Widget _buildIssuesSection(BuildContext context, ModerationResult result) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Các vấn đề phát hiện',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: result.issues!.length,
              itemBuilder: (context, index) {
                final issue = result.issues![index];
                Icon severityIcon;
                
                if (issue.severity == 'high') {
                  severityIcon = const Icon(Icons.error, color: Colors.red);
                } else if (issue.severity == 'medium') {
                  severityIcon = const Icon(Icons.warning, color: Colors.orange);
                } else {
                  severityIcon = const Icon(Icons.info, color: Colors.blue);
                }
                
                return ListTile(
                  leading: severityIcon,
                  title: Text(issue.description),
                  subtitle: issue.field != null ? Text('Trường: ${issue.field}') : null,
                  dense: true,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSuggestedTagsSection(BuildContext context, ModerationResult result) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gợi ý tags',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.suggestedTags!.map((tag) {
                return Chip(
                  label: Text(tag),
                  backgroundColor: Colors.blue[50],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTimelineSection(BuildContext context, ModerationResult result) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dòng thời gian',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Thời gian tạo
            Row(
              children: [
                const Icon(Icons.fiber_new, color: Colors.blue),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gửi kiểm duyệt'),
                    Text(
                      dateFormat.format(result.createdAt),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            
            if (result.status != ModerationStatus.pending) ...[
              Container(
                margin: const EdgeInsets.only(left: 11.5),
                height: 30,
                width: 1,
                color: Colors.grey[300],
              ),
              
              // Thời gian xem xét
              Row(
                children: [
                  Icon(
                    result.status == ModerationStatus.approved 
                      ? Icons.check_circle 
                      : (result.status == ModerationStatus.rejected ? Icons.cancel : Icons.pending),
                    color: result.status == ModerationStatus.approved 
                      ? Colors.green 
                      : (result.status == ModerationStatus.rejected ? Colors.red : Colors.amber),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.status == ModerationStatus.approved 
                          ? 'Đã phê duyệt' 
                          : (result.status == ModerationStatus.rejected ? 'Bị từ chối' : 'Đang xem xét'),
                      ),
                      if (result.reviewedAt != null)
                        Text(
                          dateFormat.format(result.reviewedAt!),
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
} 