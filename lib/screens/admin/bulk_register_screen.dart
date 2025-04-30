import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_market_nttu/services/user_service.dart';
import 'package:flutter/services.dart';
import 'package:cloud_functions/cloud_functions.dart';

class BulkRegisterScreen extends StatefulWidget {
  const BulkRegisterScreen({Key? key}) : super(key: key);

  @override
  State<BulkRegisterScreen> createState() => _BulkRegisterScreenState();
}

class _BulkRegisterScreenState extends State<BulkRegisterScreen> {
  // Controllers cho các trường nhập liệu
  final _startIndexController = TextEditingController(text: '2200000001');
  final _endIndexController = TextEditingController(text: '2200000010');
  final _batchSizeController = TextEditingController(text: '10');

  // Trạng thái đăng ký
  bool _isRegistering = false;
  int _successCount = 0;
  int _failCount = 0;
  int _totalCount = 0;
  double _progress = 0.0;

  @override
  void dispose() {
    _startIndexController.dispose();
    _endIndexController.dispose();
    _batchSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký hàng loạt'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo ứng dụng
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Image.asset(
                'assets/images/logo.png',
                width: 120,
                height: 120,
              ),
            ),
            
            // Tiêu đề và mô tả
            const Text(
              'Đăng ký hàng loạt tài khoản',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tạo tài khoản sinh viên với định dạng:\n'
              '- Tên người dùng: 2200000001 đến 2200030000\n'
              '- Email: [tên người dùng]@nttu.edu.vn\n'
              '- Mật khẩu: [tên người dùng]',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            
            const SizedBox(height: 32),
            
            // Phần cấu hình (chỉ hiển thị khi chưa bắt đầu đăng ký)
            if (!_isRegistering) ...[
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Cấu hình',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _startIndexController,
                        decoration: const InputDecoration(
                          labelText: 'Bắt đầu từ',
                          hintText: '2200000001',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _endIndexController,
                        decoration: const InputDecoration(
                          labelText: 'Kết thúc ở',
                          hintText: '2200000010',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _batchSizeController,
                        decoration: const InputDecoration(
                          labelText: 'Số lượng mỗi lô',
                          hintText: '10',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _startBulkRegister,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Bắt đầu đăng ký'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            // Phần hiển thị tiến trình (chỉ hiển thị khi đang đăng ký)
            if (_isRegistering) ...[
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Đang xử lý',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      LinearProgressIndicator(
                        value: _progress,
                        minHeight: 10,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Đang xử lý...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Hiển thị kết quả sau khi đăng ký
            if (!_isRegistering && (_successCount > 0 || _failCount > 0)) ...[
              const SizedBox(height: 32),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Kết quả',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatusCard(
                            title: 'Thành công',
                            count: _successCount,
                            color: Colors.green,
                          ),
                          _buildStatusCard(
                            title: 'Thất bại',
                            count: _failCount,
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required int count,
    required Color color,
  }) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _startBulkRegister() async {
    // Lấy các giá trị từ các trường nhập liệu
    final startIndex = int.tryParse(_startIndexController.text) ?? 2200000001;
    final endIndex = int.tryParse(_endIndexController.text) ?? 2200000010;
    final batchSize = int.tryParse(_batchSizeController.text) ?? 10;

    // Kiểm tra dữ liệu đầu vào
    if (startIndex > endIndex) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ số bắt đầu phải nhỏ hơn hoặc bằng chỉ số kết thúc'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (batchSize <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kích thước lô phải là số dương'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Hiển thị dialog xác nhận
    _showConfirmDialog(startIndex, endIndex, batchSize);
  }
  
  void _showConfirmDialog(int startIndex, int endIndex, int batchSize) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng ký tài khoản', 
          style: TextStyle(color: Colors.blue)),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black, fontSize: 16),
            children: [
              const TextSpan(
                text: 'Bạn sắp đăng ký ',
              ),
              TextSpan(
                text: '${endIndex - startIndex + 1} tài khoản',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue
                ),
              ),
              const TextSpan(
                text: ' từ ID ',
              ),
              TextSpan(
                text: startIndex.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(
                text: ' đến ',
              ),
              TextSpan(
                text: endIndex.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(
                text: '.\n\nThông tin mỗi tài khoản:\n',
              ),
              const TextSpan(
                text: '- Username: [ID]\n- Email: [ID]@nttu.edu.vn\n- Mật khẩu: [ID]',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              const TextSpan(
                text: '\n\nQuá trình sẽ được thực hiện với ',
              ),
              TextSpan(
                text: 'kích thước lô: $batchSize',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            onPressed: () {
              Navigator.pop(context);
              _callCreateBulkAccountsFunction(startIndex, endIndex, batchSize);
            },
            child: const Text('Đăng ký'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _callCreateBulkAccountsFunction(
    int startIndex, 
    int endIndex, 
    int batchSize
  ) async {
    setState(() {
      _isRegistering = true;
      _progress = 0.0;
      _totalCount = endIndex - startIndex + 1;
      _successCount = 0;
      _failCount = 0;
    });

    try {
      // Lấy thông tin user hiện tại để kiểm tra
      final userService = Provider.of<UserService>(context, listen: false);
      final isAdmin = await userService.isCurrentUserAdmin();
      
      if (!isAdmin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bạn không có quyền thực hiện chức năng này'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Hiển thị thông báo bắt đầu
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bắt đầu tạo ${_totalCount} tài khoản...'),
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Chuẩn bị danh sách tài khoản
      final List<Map<String, dynamic>> accounts = [];
      
      for (int i = startIndex; i <= endIndex; i++) {
        final String username = i.toString();
        accounts.add({
          'email': '$username@nttu.edu.vn',
          'password': username,
          'displayName': username,
          'studentId': username,
          'role': 'user'
        });
      }
      
      // Chia thành các lô nhỏ để cải thiện phản hồi UI
      final int totalBatches = (accounts.length / batchSize).ceil();
      int processedAccounts = 0;
      
      for (int batch = 0; batch < totalBatches; batch++) {
        if (!mounted) break;
        
        final int startIdx = batch * batchSize;
        final int endIdx = (startIdx + batchSize > accounts.length) 
            ? accounts.length 
            : startIdx + batchSize;
        
        final batchAccounts = accounts.sublist(startIdx, endIdx);
        
        // Gọi Cloud Function cho mỗi lô
        final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
          'createBulkAccounts',
        );
        
        setState(() {
          _progress = processedAccounts / _totalCount;
        });
        
        // Hiển thị thông báo cho mỗi lô
        if (batch > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đang xử lý lô ${batch + 1}/$totalBatches...'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
        
        final result = await callable.call({
          'accounts': batchAccounts
        });
        
        // Xử lý kết quả từng lô
        final data = result.data;
        
        if (data['success'] == true) {
          // Cập nhật UI với số lượng tài khoản đã xử lý
          final int batchSuccessCount = data['successCount'] ?? 0;
          final int batchFailCount = data['failedCount'] ?? 0;
          
          setState(() {
            _successCount += batchSuccessCount;
            _failCount += batchFailCount;
            processedAccounts += batchAccounts.length;
            _progress = processedAccounts / _totalCount;
          });
          
          // Hiển thị kết quả của lô hiện tại
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Lô ${batch + 1}: Thành công: $batchSuccessCount, Thất bại: $batchFailCount'
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
      
      // Hoàn thành - cập nhật tiến trình và hiển thị kết quả cuối cùng
      setState(() {
        _progress = 1.0;
      });
      
      // Hiển thị thông báo kết quả cuối cùng
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hoàn thành: $_successCount thành công, $_failCount thất bại'),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.green,
        ),
      );
      
      // Hiển thị dialog danh sách tài khoản đã tạo thành công nếu có
      if (_successCount > 0) {
        // Tạo danh sách email từ khoảng ID đã tạo thành công
        final List<String> successEmails = [];
        for (int i = startIndex; i <= endIndex; i++) {
          final String email = '$i@nttu.edu.vn';
          if (successEmails.length < _successCount) {
            successEmails.add(email);
          }
        }
        
        if (successEmails.isNotEmpty) {
          _showSuccessAccountsDialog(successEmails);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 10),
        ),
      );
    } finally {
      setState(() {
        _isRegistering = false;
      });
    }
  }
  
  // Hiển thị dialog với danh sách tài khoản đã tạo thành công
  void _showSuccessAccountsDialog(List<String> emails) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Danh sách tài khoản đã tạo',
            style: TextStyle(color: Colors.green, fontSize: 16)),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Các tài khoản sau đã được tạo thành công:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: emails.length > 100 ? 100 : emails.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        dense: true,
                        title: Text(emails[index], style: const TextStyle(fontSize: 12)),
                        leading: const Icon(Icons.person_add, size: 16, color: Colors.green),
                      );
                    },
                  ),
                ),
                if (emails.length > 100)
                  Text('... và ${emails.length - 100} tài khoản khác'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Đóng'),
            ),
            TextButton(
              onPressed: () {
                // Sao chép danh sách email vào clipboard
                final String emailList = emails.join('\n');
                Clipboard.setData(ClipboardData(text: emailList));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã sao chép danh sách email vào clipboard'),
                  ),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Sao chép danh sách'),
            ),
          ],
        );
      },
    );
  }
} 