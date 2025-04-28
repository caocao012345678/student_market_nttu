import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/user_service.dart';
import 'package:student_market_nttu/widgets/common_app_bar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _departmentController = TextEditingController();
  
  dynamic _selectedImage;
  bool _imageChanged = false;
  bool _isStudent = false;

  @override
  void initState() {
    super.initState();
    final userService = Provider.of<UserService>(context, listen: false);
    final user = userService.currentUser;
    
    if (user != null) {
      _displayNameController.text = user.displayName;
      _phoneController.text = user.phoneNumber;
      _addressController.text = user.address;
      _isStudent = user.isStudent;
      _studentIdController.text = user.studentId ?? '';
      _departmentController.text = user.department ?? '';
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _studentIdController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        if (kIsWeb) {
          _selectedImage = pickedFile;
        } else {
          _selectedImage = File(pickedFile.path);
        }
        _imageChanged = true;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final userService = Provider.of<UserService>(context, listen: false);
      
      // Update profile information
      await userService.updateUserProfile(
        displayName: _displayNameController.text,
        phoneNumber: _phoneController.text,
        address: _addressController.text,
        isStudent: _isStudent,
        studentId: _isStudent ? _studentIdController.text : null,
        department: _isStudent ? _departmentController.text : null,
      );

      // Update profile photo if changed
      if (_imageChanged && _selectedImage != null) {
        await userService.updateUserPhoto(_selectedImage);
      }

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật hồ sơ thành công')),
      );
      
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context);
    final user = userService.currentUser;
    final isLoading = userService.isLoading;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Vui lòng đăng nhập để chỉnh sửa hồ sơ'),
        ),
      );
    }

    return Scaffold(
      appBar: const CommonAppBar(
        title: 'Chỉnh sửa hồ sơ',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile picture
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _imageChanged
                          ? _getImageProvider()
                          : (user.photoURL.isNotEmpty
                              ? NetworkImage(user.photoURL)
                              : null),
                      child: !_imageChanged && user.photoURL.isEmpty
                          ? const Icon(Icons.person, size: 60)
                          : null,
                    ),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Display name
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Tên hiển thị',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên hiển thị';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Phone number
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              
              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ',
                  prefixIcon: Icon(Icons.home),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              
              // Student information section
              SwitchListTile(
                title: const Text('Tôi là sinh viên'),
                subtitle: const Text('Kích hoạt để nhập thông tin sinh viên'),
                value: _isStudent,
                onChanged: (value) {
                  setState(() {
                    _isStudent = value;
                  });
                },
              ),
              
              if (_isStudent) ...[
                const SizedBox(height: 16),
                
                // Student ID field
                TextFormField(
                  controller: _studentIdController,
                  decoration: const InputDecoration(
                    labelText: 'Mã số sinh viên',
                    prefixIcon: Icon(Icons.school),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_isStudent && (value == null || value.isEmpty)) {
                      return 'Vui lòng nhập mã số sinh viên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Department field
                TextFormField(
                  controller: _departmentController,
                  decoration: const InputDecoration(
                    labelText: 'Khoa/Ngành học',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_isStudent && (value == null || value.isEmpty)) {
                      return 'Vui lòng nhập khoa/ngành học';
                    }
                    return null;
                  },
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Point and credit information
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin điểm',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow('NTT Point:', '${user.nttPoint} điểm'),
                      const SizedBox(height: 4),
                      _buildInfoRow('Điểm uy tín:', '${user.nttCredit} (${user.getCreditRating()})'),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Lưu thay đổi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(value),
      ],
    );
  }

  ImageProvider _getImageProvider() {
    if (kIsWeb) {
      if (_selectedImage is XFile) {
        return NetworkImage((_selectedImage as XFile).path);
      }
    } else {
      if (_selectedImage is File) {
        return FileImage(_selectedImage as File);
      }
    }
    return const AssetImage('assets/placeholder.png');
  }
} 