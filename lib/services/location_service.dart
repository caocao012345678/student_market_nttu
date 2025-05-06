import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/location.dart';
import '../utils/location_utils.dart';

class LocationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'locations';
  bool _isLoading = false;
  bool _disposed = false;
  String _errorMessage = '';
  
  // Getter
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  
  // Constructor
  LocationService();
  
  // Phương thức lấy tất cả vị trí
  Stream<List<LocationModel>> getAllLocations() {
    return _firestore
        .collection(_collectionName)
        .where('isActive', isEqualTo: true)
        .orderBy('district')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LocationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
  
  // Phương thức lấy tất cả vị trí (bao gồm cả không hoạt động) cho trang admin
  Stream<List<LocationModel>> getAllLocationsForAdmin() {
    return _firestore
        .collection(_collectionName)
        .orderBy('district')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LocationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
  
  // Phương thức lấy vị trí theo quận
  Stream<List<LocationModel>> getLocationsByDistrict(String district) {
    return _firestore
        .collection(_collectionName)
        .where('district', isEqualTo: district)
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LocationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
  
  // Phương thức lấy danh sách quận
  Future<List<String>> getDistrictList() async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .get();
      
      // Sử dụng Set để loại bỏ các giá trị trùng lặp
      final Set<String> districts = {};
      for (var doc in snapshot.docs) {
        districts.add(doc.data()['district'] as String);
      }
      
      // Chuyển đổi set thành list và sắp xếp
      final List<String> result = districts.toList()..sort();
      return result;
    } catch (e) {
      print('Lỗi khi lấy danh sách quận: $e');
      return [];
    }
  }
  
  // Phương thức lấy vị trí theo ID
  Future<LocationModel?> getLocationById(String locationId) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(locationId).get();
      if (doc.exists) {
        return LocationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Lỗi khi lấy vị trí theo ID: $e');
      return null;
    }
  }
  
  // Phương thức tạo vị trí mới
  Future<LocationModel?> createLocation({
    required String district,
    required String name,
    required String address,
    Map<String, double>? coordinates,
    int order = 0,
    bool isActive = true,
  }) async {
    if (!_disposed) {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();
    }
    
    try {
      // Tự động lấy tọa độ từ địa chỉ nếu không cung cấp
      if (coordinates == null) {
        final locationMap = await LocationUtils.getLocationFromAddressAsync(address);
        if (locationMap != null) {
          coordinates = {
            'lat': locationMap['lat']!,
            'lng': locationMap['lng']!,
          };
        } else {
          // Nếu không thể lấy được tọa độ, báo lỗi thay vì sử dụng giá trị mặc định
          if (!_disposed) {
            _isLoading = false;
            _errorMessage = 'Không thể tìm thấy tọa độ cho địa chỉ này. Vui lòng cung cấp tọa độ hoặc chọn địa chỉ khác.';
            notifyListeners();
          }
          return null;
        }
      }
      
      final locationData = {
        'district': district,
        'name': name,
        'address': address,
        'coordinates': coordinates,
        'order': order,
        'isActive': isActive,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      };
      
      final docRef = await _firestore.collection(_collectionName).add(locationData);
      final doc = await docRef.get();
      
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
      
      return LocationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      if (!_disposed) {
        _isLoading = false;
        _errorMessage = 'Lỗi khi tạo vị trí: $e';
        notifyListeners();
      }
      print('Lỗi khi tạo vị trí: $e');
      return null;
    }
  }
  
  // Phương thức cập nhật vị trí
  Future<bool> updateLocation(LocationModel location) async {
    if (!_disposed) {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();
    }
    
    try {
      await _firestore.collection(_collectionName).doc(location.id).update({
        'district': location.district,
        'name': location.name,
        'address': location.address,
        'coordinates': location.coordinates,
        'order': location.order,
        'isActive': location.isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      if (!_disposed) {
        _isLoading = false;
        _errorMessage = 'Lỗi khi cập nhật vị trí: $e';
        notifyListeners();
      }
      print('Lỗi khi cập nhật vị trí: $e');
      return false;
    }
  }
  
  // Phương thức xóa vị trí
  Future<bool> deleteLocation(String locationId) async {
    if (!_disposed) {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();
    }
    
    try {
      await _firestore.collection(_collectionName).doc(locationId).delete();
      
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      if (!_disposed) {
        _isLoading = false;
        _errorMessage = 'Lỗi khi xóa vị trí: $e';
        notifyListeners();
      }
      print('Lỗi khi xóa vị trí: $e');
      return false;
    }
  }
  
  // Phương thức cập nhật trạng thái vị trí
  Future<bool> updateLocationStatus(String locationId, bool isActive) async {
    try {
      await _firestore.collection(_collectionName).doc(locationId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Lỗi khi cập nhật trạng thái vị trí: $e');
      return false;
    }
  }
  
  // Phương thức khởi tạo dữ liệu mẫu (chỉ chạy một lần khi cần)
  Future<void> initializeDefaultLocations() async {
    try {
      // Kiểm tra xem đã có dữ liệu chưa
      final snapshot = await _firestore.collection(_collectionName).limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        print('Đã có dữ liệu vị trí, không cần khởi tạo');
        return;
      }
      
      // Dữ liệu mẫu từ hard-code hiện tại
      final locationsData = [
        {
          'district': 'Quận 4',
          'name': 'Cơ sở Quận 4 (A)',
          'address': '300A, Nguyễn Tất Thành, P.13, Q.4, Tp.HCM',
          'coordinates': {'lat': 10.761020473905095, 'lng': 106.71052025463426},
          'order': 1,
          'isActive': true
        },
        {
          'district': 'Quận 4',
          'name': 'Cơ sở Quận 4 (B,C,D)',
          'address': '298A, Nguyễn Tất Thành, P.13, Q.4, Tp.HCM',
          'coordinates': {'lat': 10.761403624947588, 'lng': 106.70981592707493},
          'order': 2,
          'isActive': true
        },
        {
          'district': 'Quận 7',
          'name': 'Cơ sở Quận 7 (M, M.VL)',
          'address': '458/3F, Nguyễn Hữu Thọ, P. Tân Hưng, Q.7, Tp.HCM',
          'coordinates': {'lat': 10.743288078830943, 'lng': 106.70158916656443},
          'order': 1,
          'isActive': true
        },
        {
          'district': 'Quận 12',
          'name': 'Cơ sở Quận 12 (L, L.VT)',
          'address': '331, Quốc lộ 1A, P. An Phú Đông, Q.12, Tp.HCM',
          'coordinates': {'lat': 10.860464246001364, 'lng': 106.6944025665662},
          'order': 1,
          'isActive': true
        },
        {
          'district': 'Quận 12',
          'name': 'Cơ sở Quận 12 (L2)',
          'address': '1165, Quốc lộ 1A, P. An Phú Đông, Q. 12, TP. HCM',
          'coordinates': {'lat': 10.859489170521993, 'lng': 106.70577117044816},
          'order': 2,
          'isActive': true
        },
        {
          'district': 'Quận 12',
          'name': 'Cơ sở Quận 12 (VK)',
          'address': '117/5 Võ Thị Thừa, P. An Phú Đông, Q. 12, TP. HCM',
          'coordinates': {'lat': 10.864418667956953, 'lng': 106.7078083420168},
          'order': 3,
          'isActive': true
        },
        {
          'district': 'Thành Phố Thủ Đức',
          'name': 'Cơ sở Thành Phố Thủ Đức (Khu Công Nghệ Cao)',
          'address': 'Lô E3-I.1, E3-I.2, E3-I.3, đường D1, Khu Công nghệ cao TP.HCM, P. Long Thạnh Mỹ, TP. Thủ Đức, TP.HCM',
          'coordinates': {'lat': 10.837901369123824, 'lng': 106.80960105508971},
          'order': 1,
          'isActive': true
        },
      ];
      
      // Bắt đầu batch write để tối ưu hiệu suất
      final batch = _firestore.batch();
      
      // Thêm từng vị trí vào batch
      for (final locationData in locationsData) {
        final docRef = _firestore.collection(_collectionName).doc();
        locationData['createdAt'] = FieldValue.serverTimestamp();
        locationData['updatedAt'] = FieldValue.serverTimestamp();
        batch.set(docRef, locationData);
      }
      
      // Thực hiện batch write
      await batch.commit();
      print('Đã khởi tạo ${locationsData.length} vị trí mặc định');
    } catch (e) {
      print('Lỗi khi khởi tạo dữ liệu vị trí: $e');
    }
  }
  
  // Phương thức lấy dữ liệu vị trí dạng Map cho dropdown
  Future<Map<String, List<Map<String, dynamic>>>> getLocationsAsMap() async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .orderBy('district')
          .orderBy('order')
          .get();
          
      // Tạo map theo cấu trúc giống với hardcode
      final Map<String, List<Map<String, dynamic>>> result = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final district = (data['district'] as String?) ?? 'Chưa phân loại';
        
        // Tạo entry cho district nếu chưa có
        if (!result.containsKey(district)) {
          result[district] = [];
        }
        
        // Thêm location vào district, xử lý trường hợp name hoặc address bị null
        result[district]?.add({
          'id': doc.id,
          'name': data['name'] ?? 'Không có tên',
          'address': data['address'] ?? 'Không có địa chỉ',
        });
      }
      
      return result;
    } catch (e) {
      print('Lỗi khi lấy dữ liệu vị trí dạng Map: $e');
      return {};
    }
  }
  
  // Phương thức cập nhật thứ tự
  Future<bool> updateOrder(String locationId, int newOrder) async {
    try {
      await _firestore.collection(_collectionName).doc(locationId).update({
        'order': newOrder,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Lỗi khi cập nhật thứ tự: $e');
      return false;
    }
  }
  
  // Phương thức thêm địa chỉ 300A Nguyễn Tất Thành vào locations
  Future<LocationModel?> addNguyenTatThanhLocation() async {
    try {
      // Kiểm tra xem địa chỉ này đã tồn tại chưa
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('address', isEqualTo: '300A, Nguyễn Tất Thành, P.13, Q.4, Tp.HCM')
          .limit(1)
          .get();
          
      if (querySnapshot.docs.isNotEmpty) {
        print('Địa chỉ 300A Nguyễn Tất Thành đã tồn tại trong collection locations');
        return LocationModel.fromMap(querySnapshot.docs.first.data(), querySnapshot.docs.first.id);
      }
      
      // Tạo vị trí mới với tọa độ chính xác
      return await createLocation(
        district: 'Quận 4',
        name: 'Nguyễn Tất Thành',
        address: '300A, Nguyễn Tất Thành, P.13, Q.4, Tp.HCM',
        coordinates: {
          'lat': 10.761020,
          'lng': 106.710520,
        },
        isActive: true,
      );
    } catch (e) {
      print('Lỗi khi thêm địa chỉ Nguyễn Tất Thành: $e');
      return null;
    }
  }
  
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
} 