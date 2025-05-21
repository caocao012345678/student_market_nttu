import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../ai_agent/screens/ai_agent_dashboard_screen.dart';
import '../../ai_agent/screens/ai_agent_report_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang quản trị'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('AI Agent Tự Động'),
          _buildAdminTile(
            icon: Icons.smart_toy,
            title: 'Dashboard AI Agent',
            subtitle: 'Quản lý AI tự động duyệt bài đăng',
            onTap: () {
              Navigator.of(context).pushNamed(AIAgentDashboardScreen.routeName);
            },
          ),
          _buildAdminTile(
            icon: Icons.insert_chart,
            title: 'Báo cáo AI Agent',
            subtitle: 'Xem thống kê và hiệu suất của AI Agent',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => AIAgentReportScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildAdminTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
} 