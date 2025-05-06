import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/location.dart';
import '../../services/location_service.dart';
import '../../utils/location_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

class LocationManagementScreen extends StatefulWidget {
  static const routeName = '/admin/locations';
  
  const LocationManagementScreen({Key? key}) : super(key: key);

  @override
  State<LocationManagementScreen> createState() => _LocationManagementScreenState();
}

class _LocationManagementScreenState extends State<LocationManagementScreen> {
  late LocationService _locationService;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Tất cả';
  
  @override
  void initState() {
    super.initState();
    _locationService = Provider.of<LocationService>(context, listen: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý địa điểm'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchFilter(),
          Expanded(
            child: _buildLocationList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openLocationForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm địa điểm...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Tất cả'),
                _buildFilterChip('Hoạt động'),
                _buildFilterChip('Không hoạt động'),
                _buildFilterChip('Quận 4'),
                _buildFilterChip('Quận 7'),
                _buildFilterChip('Quận 12'),
                _buildFilterChip('Thủ Đức'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? label : 'Tất cả';
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.blue[100],
        checkmarkColor: Colors.blue[800],
      ),
    );
  }

  Widget _buildLocationList() {
    return StreamBuilder<List<LocationModel>>(
      stream: _locationService.getAllLocationsForAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Không có địa điểm nào'));
        }
        
        // Apply filters
        var locations = snapshot.data!;
        
        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          final lowerCaseQuery = _searchQuery.toLowerCase();
          locations = locations.where((location) {
            return location.district.toLowerCase().contains(lowerCaseQuery) ||
                   location.name.toLowerCase().contains(lowerCaseQuery) ||
                   location.address.toLowerCase().contains(lowerCaseQuery);
          }).toList();
        }
        
        // Filter by selected filter
        if (_selectedFilter != 'Tất cả') {
          if (_selectedFilter == 'Hoạt động') {
            locations = locations.where((location) => location.isActive).toList();
          } else if (_selectedFilter == 'Không hoạt động') {
            locations = locations.where((location) => !location.isActive).toList();
          } else {
            // Filter by district
            locations = locations.where((location) => 
              location.district.contains(_selectedFilter)).toList();
          }
        }
        
        // Group by district
        final Map<String, List<LocationModel>> groupedLocations = {};
        for (var location in locations) {
          if (!groupedLocations.containsKey(location.district)) {
            groupedLocations[location.district] = [];
          }
          groupedLocations[location.district]!.add(location);
        }
        
        return ListView.builder(
          itemCount: groupedLocations.keys.length,
          itemBuilder: (context, index) {
            final district = groupedLocations.keys.elementAt(index);
            final districtLocations = groupedLocations[district]!;
            
            return _buildDistrictGroup(district, districtLocations);
          },
        );
      },
    );
  }

  Widget _buildDistrictGroup(String district, List<LocationModel> locations) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          district,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text('${locations.length} địa điểm'),
        initiallyExpanded: true,
        children: locations.map((location) => _buildLocationItem(location)).toList(),
      ),
    );
  }

  Widget _buildLocationItem(LocationModel location) {
    return ListTile(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: location.isActive ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              location.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: location.isActive ? Colors.green[800] : Colors.red[800],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Thứ tự: ${location.order}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            location.address,
            style: const TextStyle(fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (location.coordinates != null)
            Text(
              'Tọa độ: ${location.coordinates!['lat']}, ${location.coordinates!['lng']}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              location.isActive ? Icons.toggle_on : Icons.toggle_off,
              color: location.isActive ? Colors.green : Colors.grey,
              size: 28,
            ),
            onPressed: () => _toggleLocationStatus(location),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _openLocationForm(context, location: location),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDeleteLocation(location),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  void _toggleLocationStatus(LocationModel location) async {
    try {
      final newStatus = !location.isActive;
      final success = await _locationService.updateLocationStatus(
        location.id, 
        newStatus
      );
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã ${newStatus ? "kích hoạt" : "vô hiệu hóa"} địa điểm: ${location.name}',
            ),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể cập nhật trạng thái địa điểm'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmDeleteLocation(LocationModel location) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa địa điểm ${location.name} (${location.district})?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteLocation(location);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _deleteLocation(LocationModel location) async {
    try {
      final success = await _locationService.deleteLocation(location.id);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa địa điểm: ${location.name}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể xóa địa điểm'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openLocationForm(BuildContext context, {LocationModel? location}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => LocationFormSheet(
        location: location,
        onSave: (savedLocation) {
          if (location == null) {
            // Trường hợp thêm mới
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã thêm địa điểm mới thành công'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            // Trường hợp cập nhật
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã cập nhật địa điểm thành công'),
                backgroundColor: Colors.blue,
              ),
            );
          }
          Navigator.of(ctx).pop();
        },
      ),
    );
  }
}

class LocationFormSheet extends StatefulWidget {
  final LocationModel? location;
  final Function(LocationModel) onSave;
  
  const LocationFormSheet({
    Key? key,
    this.location,
    required this.onSave,
  }) : super(key: key);

  @override
  State<LocationFormSheet> createState() => _LocationFormSheetState();
}

class _LocationFormSheetState extends State<LocationFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _districtController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _orderController = TextEditingController();
  bool _isActive = true;
  bool _isLoading = false;
  Map<String, double>? _coordinates;

  @override
  void initState() {
    super.initState();
    
    // Nếu có location, đổ dữ liệu vào form
    if (widget.location != null) {
      _districtController.text = widget.location!.district;
      _nameController.text = widget.location!.name;
      _addressController.text = widget.location!.address;
      _orderController.text = widget.location!.order.toString();
      _isActive = widget.location!.isActive;
      _coordinates = widget.location!.coordinates;
    } else {
      _orderController.text = '0';
    }
  }

  @override
  void dispose() {
    _districtController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.location != null;
    
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          top: 16,
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tiêu đề form
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Cập nhật địa điểm' : 'Thêm địa điểm mới',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Form fields
              TextFormField(
                controller: _districtController,
                decoration: const InputDecoration(
                  labelText: 'Quận/Huyện',
                  border: OutlineInputBorder(),
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
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên địa điểm',
                  border: OutlineInputBorder(),
                  hintText: 'Ví dụ: Cơ sở A, Khu B, ...',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên địa điểm';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ đầy đủ',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập địa chỉ đầy đủ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _orderController,
                      decoration: const InputDecoration(
                        labelText: 'Thứ tự',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập thứ tự';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Thứ tự phải là số';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _getCoordinatesFromAddress,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tọa độ',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _coordinates != null 
                                ? 'Lat: ${_coordinates!['lat']}, Lng: ${_coordinates!['lng']}'
                                : 'Chưa có tọa độ',
                              style: TextStyle(
                                color: _coordinates != null 
                                  ? Colors.black 
                                  : Colors.red,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (_coordinates == null)
                              const Text(
                                'Nhấn để tạo tự động',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Checkbox Trạng thái
              CheckboxListTile(
                title: const Text('Đang hoạt động'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value ?? true;
                  });
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 16),
              
              // Nút lưu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isEditing ? 'Cập nhật' : 'Thêm mới'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _getCoordinatesFromAddress() {
    final address = _addressController.text;
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập địa chỉ trước khi lấy tọa độ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final coordinates = LocationUtils.getLocationFromAddress(address);
    if (coordinates != null) {
      setState(() {
        _coordinates = {
          'lat': coordinates['lat']!,
          'lng': coordinates['lng']!,
        };
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lấy tọa độ thành công'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể xác định tọa độ từ địa chỉ này'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _saveLocation() async {
    // Kiểm tra form hợp lệ
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final locationService = Provider.of<LocationService>(context, listen: false);
      LocationModel? result;
      
      if (widget.location == null) {
        // Thêm mới
        result = await locationService.createLocation(
          district: _districtController.text,
          name: _nameController.text,
          address: _addressController.text,
          coordinates: _coordinates,
          order: int.parse(_orderController.text),
          isActive: _isActive,
        );
      } else {
        // Cập nhật
        final updatedLocation = widget.location!.copyWith(
          district: _districtController.text,
          name: _nameController.text,
          address: _addressController.text,
          coordinates: _coordinates,
          order: int.parse(_orderController.text),
          isActive: _isActive,
          updatedAt: DateTime.now(),
        );
        
        final success = await locationService.updateLocation(updatedLocation);
        if (success) {
          result = updatedLocation;
        }
      }
      
      if (result != null) {
        widget.onSave(result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không thể ${widget.location == null ? 'thêm' : 'cập nhật'} địa điểm'
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
} 