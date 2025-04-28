import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shipper.dart';
import '../services/shipper_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterShipperScreen extends StatefulWidget {
  const RegisterShipperScreen({Key? key}) : super(key: key);

  @override
  _RegisterShipperScreenState createState() => _RegisterShipperScreenState();
}

class _RegisterShipperScreenState extends State<RegisterShipperScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _identityCardController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _searchAreaController = TextEditingController();
  final List<String> _selectedAreas = [];
  bool _isLoading = false;
  int _currentStep = 0;
  bool _searchMode = false;
  List<String> _filteredAreas = [];
  
  // Animation controller để tạo hiệu ứng chuyển tiếp
  late AnimationController _animationController;
  late Animation<double> _animation;

  final List<String> _availableAreas = [
    'Quận 1',
    'Quận 2',
    'Quận 3',
    'Quận 4',
    'Quận 5',
    'Quận 6',
    'Quận 7',
    'Quận 8',
    'Quận 9',
    'Quận 10',
    'Quận 11',
    'Quận 12',
    'Quận Bình Thạnh',
    'Quận Tân Bình',
    'Quận Gò Vấp',
    'Quận Phú Nhuận',
    'Quận Thủ Đức',
    'Huyện Nhà Bè',
    'Huyện Bình Chánh',
    'Huyện Củ Chi',
    'Huyện Hóc Môn',
    'Huyện Cần Giờ',
  ];

  final List<String> _vehicleTypes = [
    'Xe máy',
    'Ô tô',
    'Xe đạp điện',
    'Xe đạp'
  ];

  String _selectedVehicleType = 'Xe máy';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _filteredAreas = List.from(_availableAreas);
    _searchAreaController.addListener(_filterAreas);
    
    // Khởi tạo animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _animationController.forward();
  }

  void _filterAreas() {
    final query = _searchAreaController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredAreas = List.from(_availableAreas);
        _searchMode = false;
      } else {
        _searchMode = true;
        _filteredAreas = _availableAreas
            .where((area) => area.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _loadUserData() async {
    final user = Provider.of<AuthService>(context, listen: false).user;
    final userService = Provider.of<UserService>(context, listen: false);
    
    if (user != null) {
      final userData = userService.currentUser;
      if (userData != null) {
        setState(() {
          _nameController.text = userData.displayName;
          _phoneController.text = userData.phoneNumber;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _identityCardController.dispose();
    _vehicleTypeController.dispose();
    _vehiclePlateController.dispose();
    _searchAreaController.removeListener(_filterAreas);
    _searchAreaController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _selectAllAreas() {
    setState(() {
      if (_selectedAreas.length == _availableAreas.length) {
        // Nếu đã chọn tất cả, bỏ chọn tất cả
        _selectedAreas.clear();
      } else {
        // Nếu chưa chọn tất cả, chọn tất cả
        _selectedAreas.clear();
        _selectedAreas.addAll(_availableAreas);
      }
    });
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Thông tin cá nhân
        final nameValid = _nameController.text.isNotEmpty;
        final phoneValid = _phoneController.text.isNotEmpty;
        final phoneFormatValid = RegExp(r'^\d{10}$').hasMatch(_phoneController.text.trim());
        final idValid = _identityCardController.text.isNotEmpty;
        final idFormatValid = RegExp(r'^\d{9}(\d{3})?$').hasMatch(_identityCardController.text.trim());
        
        if (!nameValid) {
          _showErrorSnackBar('Vui lòng nhập họ và tên');
          return false;
        }
        if (!phoneValid) {
          _showErrorSnackBar('Vui lòng nhập số điện thoại');
          return false;
        }
        if (!phoneFormatValid) {
          _showErrorSnackBar('Số điện thoại phải có đúng 10 chữ số');
          return false;
        }
        if (!idValid) {
          _showErrorSnackBar('Vui lòng nhập CMND/CCCD');
          return false;
        }
        if (!idFormatValid) {
          _showErrorSnackBar('CMND phải có 9 chữ số hoặc CCCD phải có 12 chữ số');
          return false;
        }
        
        return true;
      
      case 1: // Thông tin phương tiện
        return _vehiclePlateController.text.isNotEmpty;
      case 2: // Khu vực giao hàng
        return _selectedAreas.isNotEmpty;
      default:
        return true;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(8),
      ),
    );
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;
    
    // Reset animation
    _animationController.reset();
    
    setState(() {
      _currentStep += 1;
    });
    
    // Play animation
    _animationController.forward();
  }

  void _previousStep() {
    // Reset animation
    _animationController.reset();
    
    setState(() {
      _currentStep -= 1;
    });
    
    // Play animation
    _animationController.forward();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAreas.isEmpty) {
      _showErrorSnackBar('Vui lòng chọn ít nhất một khu vực giao hàng');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Provider.of<AuthService>(context, listen: false).user;
      if (user == null) throw Exception('Vui lòng đăng nhập để tiếp tục');

      final shipper = Shipper(
        id: user.uid,
        userId: user.uid,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        identityCard: _identityCardController.text.trim(),
        vehicleType: _selectedVehicleType,
        vehiclePlate: _vehiclePlateController.text.trim(),
        status: 'pending',
        createdAt: DateTime.now(),
        deliveryAreas: _selectedAreas,
      );

      // Bước 1: Đăng ký shipper
      print('Bắt đầu đăng ký shipper...');
      await Provider.of<ShipperService>(context, listen: false)
          .registerShipper(shipper);
      print('Đăng ký shipper thành công!');
      
      // Bước 2: Cập nhật trạng thái isShipper trong Firestore
      print('Đang cập nhật trạng thái isShipper...');
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'isShipper': true});
        print('Cập nhật isShipper thành công!');
      } catch (firestoreError) {
        print('Lỗi khi cập nhật isShipper: $firestoreError');
        throw firestoreError;
      }

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Đăng ký thành công!', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 64,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cảm ơn bạn đã đăng ký làm Shipper!',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Chúng tôi sẽ xem xét thông tin của bạn và phản hồi trong vòng 24 giờ.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Thông báo kết quả sẽ được gửi đến bạn qua ứng dụng và email.',
                style: TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to previous screen
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  backgroundColor: Colors.blue[900],
                ),
                child: const Text('Đóng'),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Lỗi đăng ký shipper: $e');
      _showErrorSnackBar('Lỗi: ${e.toString()}');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<Step> _buildSteps() {
    return [
      Step(
        title: const Text('Thông tin cá nhân'),
        content: FadeTransition(
          opacity: _animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(_animation),
            child: _buildPersonalInfoStep(),
          ),
        ),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Thông tin phương tiện'),
        content: FadeTransition(
          opacity: _animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(_animation),
            child: _buildVehicleInfoStep(),
          ),
        ),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Khu vực giao hàng'),
        content: FadeTransition(
          opacity: _animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(_animation),
            child: _buildDeliveryAreaStep(),
          ),
        ),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Xác nhận thông tin'),
        content: FadeTransition(
          opacity: _animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(_animation),
            child: _buildConfirmationStep(),
          ),
        ),
        isActive: _currentStep >= 3,
        state: StepState.indexed,
      ),
    ];
  }

  Widget _buildPersonalInfoStep() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin cá nhân',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Họ và tên',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.person),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập họ và tên';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Số điện thoại',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.phone),
                hintText: 'Nhập đúng 10 chữ số',
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập số điện thoại';
                }
                if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) {
                  return 'Số điện thoại phải có đúng 10 chữ số';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _identityCardController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'CMND/CCCD',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.badge),
                hintText: 'CMND (9 số) hoặc CCCD (12 số)',
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập CMND/CCCD';
                }
                if (!RegExp(r'^\d{9}(\d{3})?$').hasMatch(value.trim())) {
                  return 'CMND phải có 9 chữ số hoặc CCCD phải có 12 chữ số';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleInfoStep() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thông tin phương tiện',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Loại phương tiện:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedVehicleType,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.directions_bike),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: _vehicleTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedVehicleType = value!;
                });
              },
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _vehiclePlateController,
              decoration: InputDecoration(
                labelText: 'Biển số xe',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.confirmation_number),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập biển số xe';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryAreaStep() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Khu vực giao hàng',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chọn càng nhiều khu vực, cơ hội nhận đơn hàng càng cao',
                      style: TextStyle(fontSize: 13, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchAreaController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm khu vực...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      suffixIcon: _searchAreaController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchAreaController.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _selectAllAreas,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    backgroundColor: Colors.blue[900],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _selectedAreas.length == _availableAreas.length
                        ? 'Bỏ chọn tất cả'
                        : 'Chọn tất cả',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              padding: const EdgeInsets.all(8),
              child: _searchMode && _filteredAreas.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Không có khu vực phù hợp'),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _filteredAreas.map((area) {
                          final isSelected = _selectedAreas.contains(area);
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedAreas.remove(area);
                                  } else {
                                    _selectedAreas.add(area);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Ink(
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.blue[700] : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isSelected)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 4),
                                          child: Icon(Icons.check, size: 16, color: Colors.white),
                                        ),
                                      Text(
                                        area,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.black,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),
            if (_selectedAreas.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          'Đã chọn ${_selectedAreas.length} khu vực',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedAreas.join(', '),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationStep() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Xác nhận thông tin',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoItem('Họ và tên', _nameController.text, Icons.person),
                  _buildInfoItem('Số điện thoại', _phoneController.text, Icons.phone),
                  _buildInfoItem('CMND/CCCD', _identityCardController.text, Icons.badge),
                  _buildInfoItem('Loại phương tiện', _selectedVehicleType, Icons.directions_bike),
                  _buildInfoItem('Biển số xe', _vehiclePlateController.text, Icons.confirmation_number),
                  _buildInfoItem(
                    'Khu vực giao hàng',
                    _selectedAreas.length > 3
                        ? '${_selectedAreas.take(3).join(", ")} và ${_selectedAreas.length - 3} khu vực khác'
                        : _selectedAreas.join(', '),
                    Icons.place
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Lưu ý quan trọng',
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: Colors.red
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Thông tin của bạn sẽ được xem xét bởi đội ngũ quản trị viên. Quá trình xét duyệt có thể mất đến 24 giờ. Vui lòng đảm bảo thông tin chính xác để quá trình xét duyệt diễn ra nhanh chóng.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blue[700]),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Đăng ký làm Shipper'),
            Text(
              'Bước ${_currentStep + 1}/4',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.blue[900],
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 4,
            backgroundColor: Colors.blue[700],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          image: DecorationImage(
            image: const NetworkImage(
              'https://www.transparenttextures.com/patterns/subtle-white-feathers.png',
            ),
            repeat: ImageRepeat.repeat,
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.9),
              BlendMode.dstATop,
            ),
          ),
        ),
        child: Form(
          key: _formKey,
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Colors.blue[900]!,
              ),
            ),
            child: Stepper(
              type: StepperType.vertical,
              physics: const ScrollPhysics(),
              currentStep: _currentStep,
              onStepTapped: (step) => setState(() => _currentStep = step),
              onStepContinue: () {
                final isLastStep = _currentStep == _buildSteps().length - 1;
                
                if (!_validateCurrentStep()) {
                  // Thông báo lỗi đã được hiển thị trong _validateCurrentStep
                  return;
                }
                
                if (isLastStep) {
                  _register();
                } else {
                  _nextStep();
                }
              },
              onStepCancel: _currentStep == 0
                  ? null
                  : () => _previousStep(),
              controlsBuilder: (context, details) {
                final isLastStep = _currentStep == _buildSteps().length - 1;
                return Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : details.onStepContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[900],
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: _isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(isLastStep ? 'Đang xử lý...' : 'Đang xử lý...'),
                                  ],
                                )
                              : Text(isLastStep ? 'Gửi đăng ký' : 'Tiếp theo'),
                        ),
                      ),
                      if (_currentStep > 0) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: details.onStepCancel,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue[900],
                              side: BorderSide(color: Colors.blue[900]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Quay lại'),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
              steps: _buildSteps(),
            ),
          ),
        ),
      ),
    );
  }
} 