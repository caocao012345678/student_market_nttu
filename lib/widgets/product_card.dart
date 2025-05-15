import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:student_market_nttu/models/product.dart';
import 'package:intl/intl.dart';
import 'package:student_market_nttu/screens/product_detail_screen.dart';
import 'package:student_market_nttu/screens/user_profile_page.dart';
import 'package:provider/provider.dart';
import 'package:student_market_nttu/services/product_service.dart';
import 'package:student_market_nttu/services/favorites_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:student_market_nttu/widgets/product_card_standard.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../utils/location_utils.dart';

/// @deprecated Use ProductCardStandard instead
/// This widget is kept for backward compatibility
class ProductCard extends StatelessWidget {
  final Product product;
  final bool showDistance;
  final Map<String, double>? userLocation;

  const ProductCard({
    Key? key,
    required this.product,
    this.showDistance = false,
    this.userLocation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Lấy thông tin khoảng cách nếu có vị trí
    double? distance;
    String distanceText = '';
    
    if (showDistance && userLocation != null) {
      final productLocation = LocationUtils.getLocationFromAddress(product.location);
      if (productLocation != null &&
          userLocation!['lat'] != null && userLocation!['lng'] != null &&
          productLocation['lat'] != null && productLocation['lng'] != null) {
        try {
          distance = LocationUtils.calculateDistance(
            userLocation!['lat']!, userLocation!['lng']!,
            productLocation['lat']!, productLocation['lng']!
          );
          
          // Định dạng khoảng cách
          if (distance < 1) {
            // Dưới 1km hiển thị theo mét
            distanceText = '${(distance * 1000).toInt()}m';
          } else {
            // Trên 1km hiển thị theo km, làm tròn 1 số thập phân
            distanceText = '${distance.toStringAsFixed(1)}km';
          }
        } catch (e) {
          print('❌ Lỗi khi tính khoảng cách trong ProductCard: $e');
        }
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ảnh sản phẩm
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 12,
                child: product.images.isNotEmpty
                    ? Image.network(
                        product.images[0],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.image_not_supported, size: 40),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.image, size: 40),
                        ),
                      ),
              ),
            ),
            
            // Thông tin sản phẩm
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Badge trạng thái
                      if (product.condition.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: product.condition == 'Mới' ? Colors.green.shade100 : Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.condition,
                            style: TextStyle(
                              fontSize: 11,
                              color: product.condition == 'Mới' ? Colors.green.shade800 : Colors.blue.shade800,
                            ),
                          ),
                        ),
                      
                      // Hiển thị khoảng cách nếu có
                      if (showDistance && distanceText.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 12,
                                color: Colors.amber.shade800,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                distanceText,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Tiêu đề sản phẩm
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Giá sản phẩm
                  Text(
                    '${product.price.toStringAsFixed(0)} VNĐ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Vị trí
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.location != null 
                              ? (product.location!['address'] as String? ?? 'Không xác định')
                              : 'Không xác định',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 