import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:student_market_nttu/screens/home_screen.dart';
import 'package:student_market_nttu/services/user_service.dart';

class UserSurveyScreen extends StatefulWidget {
  final bool fromProfile;

  const UserSurveyScreen({
    super.key,
    this.fromProfile = false,
  });

  @override
  State<UserSurveyScreen> createState() => _UserSurveyScreenState();
}

class _UserSurveyScreenState extends State<UserSurveyScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isStudent = false;
  int? _studentYear;
  String? _major;
  String? _specialization;
  final List<String> _selectedInterests = [];
  final List<String> _selectedCategories = [];
  bool _isLoading = false;

  // Danh sách các ngành học
  final List<String> _majors = [
    'Công nghệ thông tin',
    'Kỹ thuật phần mềm',
    'Quản trị kinh doanh',
    'Marketing',
    'Kế toán',
    'Tài chính - Ngân hàng',
    'Luật',
    'Ngôn ngữ Anh',
    'Du lịch',
    'Xây dựng',
    'Kiến trúc',
    'Y khoa',
    'Dược học',
    'Điều dưỡng',
  ];

  // Mapping các chuyên ngành tương ứng với ngành học
  final Map<String, List<String>> _specializationMap = {
    'Công nghệ thông tin': [
      'Trí tuệ nhân tạo',
      'An toàn thông tin',
      'Khoa học dữ liệu',
      'Phát triển game',
      'Hệ thống thông tin',
      'Mạng máy tính',
    ],
    'Kỹ thuật phần mềm': [
      'Phát triển ứng dụng di động',
      'Phát triển web',
      'DevOps',
      'Kiểm thử phần mềm',
      'Quản lý dự án phần mềm',
    ],
    'Quản trị kinh doanh': [
      'Quản trị nhân sự',
      'Quản trị chuỗi cung ứng',
      'Quản trị dự án',
      'Khởi nghiệp và đổi mới',
    ],
    // Các ngành khác sẽ có chuyên ngành riêng
  };

  // Danh sách sở thích
  final List<String> _allInterests = [
    'Âm nhạc',
    'Phim ảnh',
    'Đọc sách',
    'Du lịch',
    'Nấu ăn',
    'Nhiếp ảnh',
    'Thể thao',
    'Công nghệ',
    'Game',
    'Mỹ thuật',
    'Thời trang',
    'Thiết kế',
    'DIY',
    'Học ngoại ngữ',
    'Mua sắm',
  ];

  // Danh sách danh mục sản phẩm
  final List<String> _allCategories = [
    'Sách và học liệu',
    'Thiết bị điện tử',
    'Đồ dùng cá nhân',
    'Thời trang',
    'Đồ nội thất',
    'Máy tính và phụ kiện',
    'Thiết bị học tập',
    'Dụng cụ nhà bếp',
    'Thiết bị thể thao',
    'Dụng cụ âm nhạc',
    'Xe đạp và xe điện',
    'Quà tặng và đồ thủ công',
    'Mỹ phẩm và chăm sóc cá nhân',
    'Đồ ăn vặt và đồ uống',
    'Vật dụng trang trí',
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return widget.fromProfile;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Khảo sát sở thích'),
          automaticallyImplyLeading: widget.fromProfile,
          actions: [
            if (!widget.fromProfile)
              TextButton(
                onPressed: () {
                  _skipSurvey();
                },
                child: const Text(
                  'Bỏ qua',
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Giúp chúng tôi hiểu bạn hơn để đề xuất sản phẩm phù hợp',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Phần thông tin sinh viên
                      const Text(
                        'Thông tin học tập',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      SwitchListTile(
                        title: const Text('Bạn có phải là sinh viên không?'),
                        value: _isStudent,
                        onChanged: (value) {
                          setState(() {
                            _isStudent = value;
                          });
                        },
                      ),
                      
                      if (_isStudent) ...[
                        const SizedBox(height: 10),
                        
                        // Năm học
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Năm học',
                            border: OutlineInputBorder(),
                          ),
                          items: [1, 2, 3, 4, 5].map((year) {
                            return DropdownMenuItem<int>(
                              value: year,
                              child: Text('Năm $year'),
                            );
                          }).toList(),
                          value: _studentYear,
                          onChanged: (value) {
                            setState(() {
                              _studentYear = value;
                            });
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Ngành học
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Ngành học',
                            border: OutlineInputBorder(),
                          ),
                          items: _majors.map((major) {
                            return DropdownMenuItem<String>(
                              value: major,
                              child: Text(major),
                            );
                          }).toList(),
                          value: _major,
                          onChanged: (value) {
                            setState(() {
                              _major = value;
                              _specialization = null; // Reset chuyên ngành khi thay đổi ngành
                            });
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Chuyên ngành (nếu đã chọn ngành)
                        if (_major != null && _specializationMap.containsKey(_major))
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Chuyên ngành',
                              border: OutlineInputBorder(),
                            ),
                            items: _specializationMap[_major]!.map((spec) {
                              return DropdownMenuItem<String>(
                                value: spec,
                                child: Text(spec),
                              );
                            }).toList(),
                            value: _specialization,
                            onChanged: (value) {
                              setState(() {
                                _specialization = value;
                              });
                            },
                          ),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      // Phần sở thích cá nhân
                      const Text(
                        'Sở thích cá nhân',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Chọn các sở thích của bạn (có thể chọn nhiều):',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _allInterests.map((interest) {
                          final isSelected = _selectedInterests.contains(interest);
                          return FilterChip(
                            label: Text(interest),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedInterests.add(interest);
                                } else {
                                  _selectedInterests.remove(interest);
                                }
                              });
                            },
                            selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.25),
                            checkmarkColor: Theme.of(context).colorScheme.primary,
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Phần danh mục sản phẩm quan tâm
                      const Text(
                        'Danh mục sản phẩm quan tâm',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Chọn các danh mục sản phẩm bạn quan tâm (có thể chọn nhiều):',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _allCategories.map((category) {
                          final isSelected = _selectedCategories.contains(category);
                          return FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedCategories.add(category);
                                } else {
                                  _selectedCategories.remove(category);
                                }
                              });
                            },
                            selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.25),
                            checkmarkColor: Theme.of(context).colorScheme.primary,
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Nút lưu thông tin
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveSurvey,
                          child: const Text(
                            'Lưu thông tin',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _saveSurvey() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      // Lưu dữ liệu khảo sát vào Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isStudent': _isStudent,
        'studentYear': _isStudent ? _studentYear : null,
        'major': _isStudent ? _major : null,
        'specialization': _isStudent ? _specialization : null,
        'interests': _selectedInterests,
        'preferredCategories': _selectedCategories,
        'completedSurvey': true,
      });

      // Cập nhật dữ liệu người dùng trong UserService
      if (context.mounted) {
        await Provider.of<UserService>(context, listen: false).getUserData(userId);
      }

      // Chuyển hướng đến màn hình chính hoặc quay lại
      if (context.mounted) {
        if (widget.fromProfile) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật thông tin thành công'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _skipSurvey() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }
} 