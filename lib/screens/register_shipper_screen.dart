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

class _RegisterShipperScreenState extends State<RegisterShipperScreen> {
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng nhập họ và tên'), backgroundColor: Colors.red),
          );
          return false;
        }
        if (!phoneValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng nhập số điện thoại'), backgroundColor: Colors.red),
          );
          return false;
        }
        if (!phoneFormatValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Số điện thoại phải có đúng 10 chữ số'), backgroundColor: Colors.red),
          );
          return false;
        }
        if (!idValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng nhập CMND/CCCD'), backgroundColor: Colors.red),
          );
          return false;
        }
        if (!idFormatValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CMND phải có 9 chữ số hoặc CCCD phải có 12 chữ số'), backgroundColor: Colors.red),
          );
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAreas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất một khu vực giao hàng'),
          backgroundColor: Colors.red,
        ),
      );
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
          title: const Text('Đăng ký thành công!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 64,
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return to previous screen
              },
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Lỗi đăng ký shipper: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<Step> _buildSteps() {
    return [
      Step(
        title: const Text('Thông tin cá nhân'),
        content: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Họ và tên',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
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
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
                hintText: 'Nhập đúng 10 chữ số',
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
              decoration: const InputDecoration(
                labelText: 'CMND/CCCD',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
                hintText: 'CMND (9 số) hoặc CCCD (12 số)',
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
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Thông tin phương tiện'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Loại phương tiện:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedVehicleType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions_bike),
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
              decoration: const InputDecoration(
                labelText: 'Biển số xe',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.confirmation_number),
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
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Khu vực giao hàng'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chọn khu vực bạn có thể giao hàng:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Chọn càng nhiều khu vực, cơ hội nhận đơn hàng càng cao',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
                  ),
                  child: Text(
                    _selectedAreas.length == _availableAreas.length
                        ? 'Bỏ chọn tất cả'
                        : 'Chọn tất cả',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
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
                          return FilterChip(
                            label: Text(area),
                            selected: isSelected,
                            checkmarkColor: Colors.white,
                            selectedColor: Colors.blue,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedAreas.add(area);
                                } else {
                                  _selectedAreas.remove(area);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
            ),
            if (_selectedAreas.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đã chọn ${_selectedAreas.length} khu vực',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
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
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Xác nhận thông tin'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vui lòng kiểm tra lại thông tin trước khi gửi:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoItem('Họ và tên', _nameController.text),
            _buildInfoItem('Số điện thoại', _phoneController.text),
            _buildInfoItem('CMND/CCCD', _identityCardController.text),
            _buildInfoItem('Loại phương tiện', _selectedVehicleType),
            _buildInfoItem('Biển số xe', _vehiclePlateController.text),
            _buildInfoItem(
              'Khu vực giao hàng', 
              _selectedAreas.length > 3 
                  ? '${_selectedAreas.take(3).join(", ")} và ${_selectedAreas.length - 3} khu vực khác'
                  : _selectedAreas.join(', ')
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: const Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Lưu ý quan trọng',
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: Colors.red
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Thông tin của bạn sẽ được xem xét bởi đội ngũ quản trị viên. Quá trình xét duyệt có thể mất đến 24 giờ. Vui lòng đảm bảo thông tin chính xác để quá trình xét duyệt diễn ra nhanh chóng.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        isActive: _currentStep >= 3,
        state: StepState.indexed,
      ),
    ];
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 4,
            backgroundColor: Colors.blue[700],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
      body: Form(
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
                setState(() => _currentStep += 1);
              }
            },
            onStepCancel: _currentStep == 0
                ? null
                : () => setState(() => _currentStep -= 1),
            controlsBuilder: (context, details) {
              final isLastStep = _currentStep == _buildSteps().length - 1;
              return Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[900],
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(isLastStep ? 'Gửi đăng ký' : 'Tiếp theo'),
                      ),
                    ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: details.onStepCancel,
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
    );
  }
} 