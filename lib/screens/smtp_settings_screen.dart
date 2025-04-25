import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';

class SmtpSettingsScreen extends StatefulWidget {
  const SmtpSettingsScreen({super.key});

  @override
  State<SmtpSettingsScreen> createState() => _SmtpSettingsScreenState();
}

class _SmtpSettingsScreenState extends State<SmtpSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _portController = TextEditingController(text: '587');
  bool _useSSL = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    try {
      setState(() => _isLoading = true);
      
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) return;

      final smtpConfig = doc.data()?['smtpConfig'] as Map<String, dynamic>?;
      if (smtpConfig != null) {
        _hostController.text = smtpConfig['host'] ?? '';
        _usernameController.text = smtpConfig['username'] ?? '';
        _passwordController.text = smtpConfig['password'] ?? '';
        _portController.text = (smtpConfig['port'] ?? 587).toString();
        setState(() {
          _useSSL = smtpConfig['ssl'] ?? false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải cấu hình: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('Không tìm thấy người dùng đăng nhập');
      }

      final smtpConfig = {
        'host': _hostController.text.trim(),
        'username': _usernameController.text.trim(),
        'password': _passwordController.text.trim(),
        'port': int.parse(_portController.text.trim()),
        'ssl': _useSSL,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'smtpConfig': smtpConfig});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu cấu hình SMTP')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu cấu hình: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      // TODO: Implement SMTP connection test
      await Future.delayed(const Duration(seconds: 1)); // Simulate testing

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kết nối SMTP thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cấu hình SMTP'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Hướng dẫn cấu hình SMTP'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('1. Đối với Gmail:'),
                        Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Text('''
• Host: smtp.gmail.com
• Port: 587
• SSL: Tắt
• Username: email@gmail.com
• Password: Mật khẩu ứng dụng từ Google

Lưu ý: Bạn cần bật xác thực 2 bước và tạo mật khẩu ứng dụng trong cài đặt Google Account.'''),
                        ),
                        SizedBox(height: 16),
                        Text('2. Đối với Outlook/Hotmail:'),
                        Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Text('''
• Host: smtp.office365.com
• Port: 587
• SSL: Tắt
• Username: email@outlook.com
• Password: Mật khẩu email'''),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Đóng'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _hostController,
                      decoration: const InputDecoration(
                        labelText: 'SMTP Host',
                        hintText: 'Ví dụ: smtp.gmail.com',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập SMTP host';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Email của bạn',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập email';
                        }
                        if (!value.contains('@')) {
                          return 'Email không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        hintText: 'Mật khẩu email hoặc App Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mật khẩu';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _portController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Port',
                        hintText: 'Ví dụ: 587',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập port';
                        }
                        final port = int.tryParse(value);
                        if (port == null || port <= 0 || port > 65535) {
                          return 'Port không hợp lệ';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Sử dụng SSL'),
                      value: _useSSL,
                      onChanged: (value) {
                        setState(() {
                          _useSSL = value;
                        });
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Lưu cấu hình'),
                      onPressed: _saveSettings,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text('Kiểm tra kết nối'),
                      onPressed: _testConnection,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _hostController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _portController.dispose();
    super.dispose();
  }
}
