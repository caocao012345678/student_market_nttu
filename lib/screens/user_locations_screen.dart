import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_market_nttu/services/user_service.dart';

class UserLocationScreen extends StatefulWidget {
  const UserLocationScreen({Key? key}) : super(key: key);

  @override
  _UserLocationScreenState createState() => _UserLocationScreenState();
}

class _UserLocationScreenState extends State<UserLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _provinceController = TextEditingController();
  final _districtController = TextEditingController();
  final _wardController = TextEditingController();
  final _addressDetailController = TextEditingController();
  
  // Controller cho form chỉnh sửa
  final _editProvinceController = TextEditingController();
  final _editDistrictController = TextEditingController();
  final _editWardController = TextEditingController();
  final _editAddressDetailController = TextEditingController();
  
  bool _isAdding = false;
  bool _isEditing = false;
  String? _editingLocationId;
  bool _isLoading = false;

  @override
  void dispose() {
    _provinceController.dispose();
    _districtController.dispose();
    _wardController.dispose();
    _addressDetailController.dispose();
    _editProvinceController.dispose();
    _editDistrictController.dispose();
    _editWardController.dispose();
    _editAddressDetailController.dispose();
    super.dispose();
  }

  // Thêm địa điểm mới
  Future<void> _addLocation() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      await userService.addLocation({
        'province': _provinceController.text,
        'district': _districtController.text,
        'ward': _wardController.text,
        'addressDetail': _addressDetailController.text,
      });
      
      setState(() {
        _isAdding = false;
        _provinceController.clear();
        _districtController.clear();
        _wardController.clear();
        _addressDetailController.clear();
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Địa điểm đã được thêm thành công')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Cập nhật địa điểm
  Future<void> _updateLocation() async {
    if (!_formKey.currentState!.validate() || _editingLocationId == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      await userService.updateLocation(
        _editingLocationId!,
        {
          'province': _editProvinceController.text,
          'district': _editDistrictController.text,
          'ward': _editWardController.text,
          'addressDetail': _editAddressDetailController.text,
        }
      );
      
      setState(() {
        _isEditing = false;
        _editingLocationId = null;
        _editProvinceController.clear();
        _editDistrictController.clear();
        _editWardController.clear();
        _editAddressDetailController.clear();
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Địa điểm đã được cập nhật thành công')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Xóa địa điểm
  Future<void> _deleteLocation(String locationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa địa điểm này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      await userService.deleteLocation(locationId);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Địa điểm đã được xóa thành công')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Chuyển sang chế độ chỉnh sửa
  void _startEditing(Map<String, dynamic> location) {
    setState(() {
      _isEditing = true;
      _isAdding = false;
      _editingLocationId = location['id'];
      _editProvinceController.text = location['province'] ?? '';
      _editDistrictController.text = location['district'] ?? '';
      _editWardController.text = location['ward'] ?? '';
      _editAddressDetailController.text = location['addressDetail'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context);
    final locations = userService.getUserLocations();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Địa điểm của tôi'),
        actions: [
          if (!_isAdding && !_isEditing)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                setState(() {
                  _isAdding = true;
                  _isEditing = false;
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isAdding || _isEditing
              ? _buildForm()
              : _buildLocationList(locations),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isAdding ? 'Thêm địa điểm mới' : 'Chỉnh sửa địa điểm',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _isEditing ? _editProvinceController : _provinceController,
              decoration: const InputDecoration(
                labelText: 'Tỉnh/Thành phố',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tỉnh/thành phố';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _isEditing ? _editDistrictController : _districtController,
              decoration: const InputDecoration(
                labelText: 'Quận/Huyện',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập quận/huyện';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _isEditing ? _editWardController : _wardController,
              decoration: const InputDecoration(
                labelText: 'Phường/Xã',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập phường/xã';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _isEditing ? _editAddressDetailController : _addressDetailController,
              decoration: const InputDecoration(
                labelText: 'Số nhà, tên đường',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập số nhà, tên đường';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isAdding = false;
                        _isEditing = false;
                        
                        // Xóa dữ liệu đã nhập
                        if (_isAdding) {
                          _provinceController.clear();
                          _districtController.clear();
                          _wardController.clear();
                          _addressDetailController.clear();
                        } else {
                          _editProvinceController.clear();
                          _editDistrictController.clear();
                          _editWardController.clear();
                          _editAddressDetailController.clear();
                          _editingLocationId = null;
                        }
                      });
                    },
                    child: const Text('Hủy'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isAdding ? _addLocation : _updateLocation,
                    child: Text(_isAdding ? 'Thêm địa điểm' : 'Cập nhật'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationList(List<Map<String, dynamic>> locations) {
    if (locations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Bạn chưa có địa điểm nào',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isAdding = true;
                });
              },
              icon: const Icon(Icons.add_location),
              label: const Text('Thêm địa điểm mới'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: locations.length,
      itemBuilder: (context, index) {
        final location = locations[index];
        final address = [
          location['addressDetail'],
          location['ward'],
          location['district'],
          location['province'],
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Thêm ngày: ${location['createdAt'] != null ? DateTime.fromMillisecondsSinceEpoch(int.parse(location['id'])).toString().substring(0, 10) : 'N/A'}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _startEditing(location),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteLocation(location['id']),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailItem('Tỉnh/TP:', location['province'] ?? 'N/A'),
                          _buildDetailItem('Quận/Huyện:', location['district'] ?? 'N/A'),
                          _buildDetailItem('Phường/Xã:', location['ward'] ?? 'N/A'),
                          _buildDetailItem('Địa chỉ:', location['addressDetail'] ?? 'N/A'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 