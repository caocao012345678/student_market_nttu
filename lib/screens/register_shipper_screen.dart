import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shipper.dart';
import '../services/shipper_service.dart';
import '../services/auth_service.dart';

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
  final List<String> _selectedAreas = [];
  bool _isLoading = false;

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
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _identityCardController.dispose();
    _vehicleTypeController.dispose();
    _vehiclePlateController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAreas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất một khu vực giao hàng'),
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
        vehicleType: _vehicleTypeController.text.trim(),
        vehiclePlate: _vehiclePlateController.text.trim(),
        status: 'pending',
        createdAt: DateTime.now(),
        deliveryAreas: _selectedAreas,
      );

      await Provider.of<ShipperService>(context, listen: false)
          .registerShipper(shipper);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Đăng ký thành công! Chúng tôi sẽ xem xét và phản hồi sớm nhất.'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký làm Shipper'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  border: OutlineInputBorder(),
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
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số điện thoại';
                  }
                  if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                    return 'Số điện thoại không hợp lệ';
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
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập CMND/CCCD';
                  }
                  if (!RegExp(r'^\d{9}(\d{3})?$').hasMatch(value)) {
                    return 'CMND/CCCD không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _vehicleTypeController,
                decoration: const InputDecoration(
                  labelText: 'Loại xe',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập loại xe';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _vehiclePlateController,
                decoration: const InputDecoration(
                  labelText: 'Biển số xe',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập biển số xe';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Khu vực giao hàng:',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _availableAreas.map((area) {
                  final isSelected = _selectedAreas.contains(area);
                  return FilterChip(
                    label: Text(area),
                    selected: isSelected,
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
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Đăng ký'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 