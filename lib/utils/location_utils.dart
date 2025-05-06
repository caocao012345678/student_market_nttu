import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationUtils {
  /// Tính khoảng cách giữa hai tọa độ địa lý bằng công thức Haversine
  /// Trả về khoảng cách tính bằng km
  static double calculateDistance(
    double lat1, 
    double lon1, 
    double lat2, 
    double lon2,
  ) {
    // Chuyển đổi từ độ sang radian
    final latRad1 = _degreesToRadians(lat1);
    final lonRad1 = _degreesToRadians(lon1);
    final latRad2 = _degreesToRadians(lat2);
    final lonRad2 = _degreesToRadians(lon2);

    // Công thức Haversine
    final dLat = latRad2 - latRad1;
    final dLon = lonRad2 - lonRad1;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(latRad1) * cos(latRad2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    // Bán kính Trái Đất (km)
    const earthRadius = 6371.0;
    
    return earthRadius * c;
  }

  /// Chuyển đổi từ độ sang radian
  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Chuyển đổi địa chỉ thành vị trí thông qua collection locations
  static Map<String, double>? getLocationFromAddress(dynamic address) {
    // Nếu address là null
    if (address == null) {
      print('⚠️ LocationUtils: Địa chỉ null, trả về null');
      return null;
    }
    
    // Nếu address đã là Map có lat và lng, sử dụng trực tiếp
    if (address is Map<String, dynamic>) {
      if (address.containsKey('lat') && address.containsKey('lng')) {
        double? lat = (address['lat'] is double) 
            ? address['lat']
            : double.tryParse(address['lat'].toString());
            
        double? lng = (address['lng'] is double) 
            ? address['lng']
            : double.tryParse(address['lng'].toString());
        
        if (lat != null && lng != null) {
          print('ℹ️ LocationUtils: Lấy vị trí từ Map: $lat, $lng');
          return {'lat': lat, 'lng': lng};
        }
      } else if (address.containsKey('address')) {
        // Nếu không có tọa độ nhưng có địa chỉ text, dùng địa chỉ để tìm
        print('ℹ️ LocationUtils: Lấy vị trí từ address field');
        return getLocationFromAddress(address['address']);
      }
      
      print('⚠️ LocationUtils: Map không chứa thông tin vị trí hợp lệ, trả về null');
      return null;
    }
    
    // Chuyển đổi sang String
    String addressStr = address.toString();
    
    // Nếu địa chỉ rỗng
    if (addressStr.isEmpty) {
      print('⚠️ LocationUtils: Địa chỉ rỗng, trả về null');
      return null;
    }

    // Danh sách vị trí mẫu
    final locationMap = {
      'Nguyen Tat Thanh University': {'lat': 10.7326, 'lng': 106.6975},
      'Đại học Nguyễn Tất Thành': {'lat': 10.7326, 'lng': 106.6975},
      'NTTU': {'lat': 10.7326, 'lng': 106.6975},
      'Nguyễn Tất Thành': {'lat': 10.7326, 'lng': 106.6975},
      'Quận 1': {'lat': 10.7769, 'lng': 106.6989},
      'Quận 3': {'lat': 10.7800, 'lng': 106.6820},
      'Quận 4': {'lat': 10.7590, 'lng': 106.7040},
      'Quận 5': {'lat': 10.7551, 'lng': 106.6608},
      'Quận 6': {'lat': 10.7469, 'lng': 106.6350},
      'Quận 7': {'lat': 10.7382, 'lng': 106.7321},
      'Quận 8': {'lat': 10.7226, 'lng': 106.6283},
      'Quận 10': {'lat': 10.7731, 'lng': 106.6607},
      'Quận 11': {'lat': 10.7629, 'lng': 106.6507},
      'Quận 12': {'lat': 10.8671, 'lng': 106.6413},
      'Quận Bình Thạnh': {'lat': 10.8105, 'lng': 106.7091},
      'Quận Tân Bình': {'lat': 10.8031, 'lng': 106.6522},
      'Quận Tân Phú': {'lat': 10.7900, 'lng': 106.6281},
      'Quận Phú Nhuận': {'lat': 10.7999, 'lng': 106.6816},
      'Quận Gò Vấp': {'lat': 10.8386, 'lng': 106.6646},
      'Quận Thủ Đức': {'lat': 10.8555, 'lng': 106.7936},
      'Quận Bình Tân': {'lat': 10.7654, 'lng': 106.6017},
      'Ký túc xá NTTU': {'lat': 10.7340, 'lng': 106.6990},
      'Thành Phố Thủ Đức': {'lat': 10.8555, 'lng': 106.7936},
      // Thêm địa chỉ mới từ log
      '300A, Nguyễn Tất Thành, P.13, Q.4, Tp.HCM': {'lat': 10.761020, 'lng': 106.710520},
      'Nguyễn Tất Thành, Q.4': {'lat': 10.761020, 'lng': 106.710520},
    };

    // Tìm vị trí từ danh sách cứng trước
    for (final entry in locationMap.entries) {
      if (addressStr.toLowerCase().contains(entry.key.toLowerCase())) {
        final result = {'lat': entry.value['lat']!, 'lng': entry.value['lng']!};
        print('✅ LocationUtils: Tìm thấy vị trí cho "$addressStr" từ danh sách cứng: ${result['lat']}, ${result['lng']}');
        return result;
      }
    }

    // Ghi log rõ ràng
    print('⚠️ LocationUtils: Không tìm thấy vị trí cho "$addressStr" trong danh sách cứng. Thử sử dụng getLocationFromAddressAsync để truy vấn Firestore');
    
    // Trả về null thay vì vị trí mặc định
    return null;
  }

  /// Phương thức bất đồng bộ để tìm địa chỉ từ collection locations trong Firestore
  static Future<Map<String, double>?> getLocationFromAddressAsync(dynamic address) async {
    // Nếu address là null hoặc rỗng, trả về null
    if (address == null) {
      print('⚠️ LocationUtils: Địa chỉ null, trả về null');
      return null;
    }
    
    // Xử lý nếu address đã là Map
    if (address is Map<String, dynamic>) {
      if (address.containsKey('lat') && address.containsKey('lng')) {
        double? lat = (address['lat'] is double) 
            ? address['lat']
            : double.tryParse(address['lat'].toString());
            
        double? lng = (address['lng'] is double) 
            ? address['lng']
            : double.tryParse(address['lng'].toString());
        
        if (lat != null && lng != null) {
          print('ℹ️ LocationUtils: Lấy vị trí từ Map: $lat, $lng');
          return {'lat': lat, 'lng': lng};
        }
      } else if (address.containsKey('address')) {
        return getLocationFromAddressAsync(address['address']);
      }
      
      print('⚠️ LocationUtils: Map không chứa thông tin vị trí hợp lệ, trả về null');
      return null;
    }
    
    // Chuyển đổi sang String
    String addressStr = address.toString();
    
    if (addressStr.isEmpty) {
      print('⚠️ LocationUtils: Địa chỉ rỗng, trả về null');
      return null;
    }
    
    try {
      print('🔍 LocationUtils: Đang tìm kiếm địa chỉ "$addressStr" trong Firestore');
      
      // Truy vấn collection locations để tìm địa chỉ tương ứng
      final QuerySnapshot locationsSnapshot = await FirebaseFirestore.instance
          .collection('locations')
          .get();
      
      // So sánh địa chỉ và tìm kết quả gần nhất
      String matchedAddress = '';
      Map<String, double>? coordinates;
      
      for (var doc in locationsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final locationAddress = data['address'] as String? ?? '';
        
        // Kiểm tra nếu địa chỉ chứa chuỗi tìm kiếm hoặc ngược lại
        if (locationAddress.toLowerCase().contains(addressStr.toLowerCase()) || 
            addressStr.toLowerCase().contains(locationAddress.toLowerCase())) {
          
          // Nếu tìm thấy địa chỉ phù hợp hơn (dài hơn) thì cập nhật
          if (locationAddress.length > matchedAddress.length) {
            matchedAddress = locationAddress;
            
            // Lấy tọa độ từ dữ liệu
            if (data.containsKey('coordinates') && data['coordinates'] != null) {
              final coords = data['coordinates'] as Map<String, dynamic>;
              coordinates = {
                'lat': coords['lat'] as double,
                'lng': coords['lng'] as double,
              };
            }
          }
        }
      }
      
      if (coordinates != null) {
        print('✅ LocationUtils: Tìm thấy vị trí cho "$addressStr" từ Firestore: ${coordinates['lat']}, ${coordinates['lng']}');
        return coordinates;
      }
      
      print('⚠️ LocationUtils: Không tìm thấy vị trí cho "$addressStr" trong Firestore');
      
      // Sử dụng getLocationFromAddress để fallback về danh sách cứng
      return getLocationFromAddress(addressStr);
      
    } catch (e) {
      print('❌ LocationUtils: Lỗi khi tìm kiếm địa chỉ từ Firestore: $e');
      
      // Sử dụng getLocationFromAddress để fallback về danh sách cứng
      return getLocationFromAddress(addressStr);
    }
  }
} 