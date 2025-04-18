import 'package:flutter/material.dart';
import 'package:student_market_nttu/screens/chatbot_screen.dart';
import 'package:student_market_nttu/screens/models_info_screen.dart';
import 'package:student_market_nttu/widgets/app_drawer.dart';

class AIHubScreen extends StatelessWidget {
  const AIHubScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('AI Hub'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trung tâm AI',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Khám phá các tính năng AI trong ứng dụng Student Market NTTU. Sử dụng trợ lý ảo để trò chuyện hoặc xem thông tin về các mô hình AI được sử dụng.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            
            // Cards Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  // Chatbot Card
                  _buildFeatureCard(
                    context,
                    title: 'Trợ lý ảo',
                    description: 'Trò chuyện với trợ lý ảo thông minh.',
                    icon: Icons.chat_bubble_outline,
                    color: Colors.blue[800],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatbotScreen(),
                        ),
                      );
                    },
                  ),
                  
                  // Models Info Card
                  _buildFeatureCard(
                    context,
                    title: 'Mô hình AI',
                    description: 'Xem thông tin về các mô hình AI được sử dụng.',
                    icon: Icons.model_training,
                    color: Colors.indigo[800],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GeminiModelsInfoScreen(),
                        ),
                      );
                    },
                  ),
                  
                  // Research Card
                  _buildFeatureCard(
                    context,
                    title: 'Tài liệu nghiên cứu',
                    description: 'Tìm hiểu thêm về công nghệ AI.',
                    icon: Icons.science_outlined,
                    color: Colors.purple[800],
                    onTap: () {
                      _showComingSoonDialog(context);
                    },
                  ),
                  
                  // Settings Card
                  _buildFeatureCard(
                    context,
                    title: 'Cài đặt AI',
                    description: 'Tùy chỉnh cài đặt AI trong ứng dụng.',
                    icon: Icons.settings_outlined,
                    color: Colors.green[800],
                    onTap: () {
                      _showComingSoonDialog(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color? color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color?.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showComingSoonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tính năng sắp ra mắt'),
          content: const Text('Tính năng này sẽ được cập nhật trong phiên bản tiếp theo.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }
} 