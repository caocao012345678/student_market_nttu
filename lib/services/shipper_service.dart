import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/shipper.dart';

class ShipperService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // Register as a shipper
  Future<void> registerShipper(Shipper shipper) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('ShipperService: Bắt đầu đăng ký shipper với id=${shipper.id}');
      
      // Kiểm tra xem shipper đã đăng ký chưa
      final existingShipper = await _firestore
          .collection('shippers')
          .doc(shipper.id)
          .get();
          
      if (existingShipper.exists) {
        print('ShipperService: Shipper đã tồn tại');
        // Nếu đã tồn tại, chỉ cập nhật thông tin
        await _firestore.collection('shippers').doc(shipper.id).update({
          'name': shipper.name,
          'phone': shipper.phone,
          'identityCard': shipper.identityCard,
          'vehicleType': shipper.vehicleType,
          'vehiclePlate': shipper.vehiclePlate,
          'deliveryAreas': shipper.deliveryAreas,
          'status': shipper.status, // Giữ nguyên trạng thái nếu chỉ đang cập nhật thông tin
        });
        print('ShipperService: Đã cập nhật thông tin shipper');
      } else {
        // Nếu chưa tồn tại, tạo mới
        print('ShipperService: Tạo mới thông tin shipper');
        await _firestore.collection('shippers').doc(shipper.id).set(shipper.toMap());
        print('ShipperService: Đã tạo mới shipper thành công');
      }

      _isLoading = false;
      notifyListeners();
      print('ShipperService: Hoàn tất quá trình đăng ký');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('ShipperService ERROR: $e');
      throw e;
    }
  }

  // Get shipper by userId
  Future<Shipper?> getShipperByUserId(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('shippers')
          .where('userId', isEqualTo: userId)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return Shipper.fromMap(
        querySnapshot.docs.first.data(),
        querySnapshot.docs.first.id,
      );
    } catch (e) {
      throw e;
    }
  }

  // Update shipper status
  Future<void> updateShipperStatus(String shipperId, String status) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('shippers').doc(shipperId).update({
        'status': status,
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Update shipper rating
  Future<void> updateShipperRating(String shipperId, double rating) async {
    try {
      final shipperDoc =
          await _firestore.collection('shippers').doc(shipperId).get();
      
      if (!shipperDoc.exists) throw Exception('Shipper not found');

      final currentRating = (shipperDoc.data()?['rating'] as num?)?.toDouble() ?? 0.0;
      final currentCount = shipperDoc.data()?['deliveryCount'] as int? ?? 0;

      // Calculate new average rating
      final newRating =
          ((currentRating * currentCount) + rating) / (currentCount + 1);

      await _firestore.collection('shippers').doc(shipperId).update({
        'rating': newRating,
        'deliveryCount': currentCount + 1,
      });
    } catch (e) {
      throw e;
    }
  }

  // Get all available shippers in an area
  Stream<List<Shipper>> getAvailableShippersInArea(String area) {
    return _firestore
        .collection('shippers')
        .where('status', isEqualTo: 'approved')
        .where('deliveryAreas', arrayContains: area)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Shipper.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Update shipper delivery areas
  Future<void> updateDeliveryAreas(String shipperId, List<String> areas) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('shippers').doc(shipperId).update({
        'deliveryAreas': areas,
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }
} 