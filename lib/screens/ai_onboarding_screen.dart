import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_market_nttu/screens/ai_hub_screen.dart';

class AIOnboardingScreen extends StatefulWidget {
  const AIOnboardingScreen({Key? key}) : super(key: key);

  @override
  State<AIOnboardingScreen> createState() => _AIOnboardingScreenState();
}

class _AIOnboardingScreenState extends State<AIOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<Map<String, dynamic>> _onboardingData = [
    {
      'title': 'Chào mừng đến với trợ lý AI',
      'description': 'Khám phá các tính năng AI mới nhất trong ứng dụng Student Market NTTU.',
      'image': 'assets/images/ai/onboarding1.png',
      'color': Colors.blue[800],
      'icon': Icons.smart_toy_outlined,
    },
    {
      'title': 'Trợ lý ảo thông minh',
      'description': 'Trò chuyện với trợ lý ảo thông minh để nhận thông tin nhanh chóng về ứng dụng, sản phẩm, và nhiều hơn nữa.',
      'image': 'assets/images/ai/onboarding2.png',
      'color': Colors.indigo[800],
      'icon': Icons.chat_bubble_outline,
    },
    {
      'title': 'Khám phá các mô hình AI',
      'description': 'Tìm hiểu về các mô hình AI mới nhất được sử dụng trong ứng dụng và khám phá các tính năng của chúng.',
      'image': 'assets/images/ai/onboarding3.png',
      'color': Colors.purple[800],
      'icon': Icons.model_training,
    },
    {
      'title': 'Đã sẵn sàng!',
      'description': 'Bạn đã sẵn sàng để trải nghiệm trợ lý AI của chúng tôi và các tính năng thông minh của nó.',
      'image': 'assets/images/ai/onboarding4.png',
      'color': Colors.green[800],
      'icon': Icons.rocket_launch,
    },
  ];
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  void _markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ai_onboarding_completed', true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _onboardingData[_currentPage]['color']!.withOpacity(0.8),
                  _onboardingData[_currentPage]['color']!.withOpacity(0.4),
                ],
              ),
            ),
          ),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextButton(
                      onPressed: () {
                        _markOnboardingComplete();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AIHubScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Bỏ qua',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Page content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemCount: _onboardingData.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icon
                            Icon(
                              _onboardingData[index]['icon'],
                              size: 100,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 40),
                            // Title
                            Text(
                              _onboardingData[index]['title'],
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            // Description
                            Text(
                              _onboardingData[index]['description'],
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                // Pagination dots
                Padding(
                  padding: const EdgeInsets.only(bottom: 30.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingData.length,
                      (index) => buildDot(index),
                    ),
                  ),
                ),
                
                // Navigation buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      _currentPage > 0
                          ? TextButton(
                              onPressed: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: const Text(
                                'Trước',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : const SizedBox(width: 80),
                      
                      // Next/Finish button
                      ElevatedButton(
                        onPressed: () {
                          if (_currentPage < _onboardingData.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _markOnboardingComplete();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AIHubScreen(),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _onboardingData[_currentPage]['color'],
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          _currentPage < _onboardingData.length - 1 ? 'Tiếp theo' : 'Bắt đầu',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
} 