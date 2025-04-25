import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_market_nttu/models/product.dart';
import 'package:student_market_nttu/services/product_service.dart';
import 'package:student_market_nttu/screens/product_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class RelatedProductsSection extends StatelessWidget {
  final String category;
  final String excludeProductId;

  const RelatedProductsSection({
    super.key,
    required this.category,
    required this.excludeProductId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: Provider.of<ProductService>(context).getRelatedProducts(
        category: category,
        excludeProductId: excludeProductId,
        limit: 4, // Fetch 4 but only display 2
      ),
      builder: (context, snapshot) {
        // Don't show anything while loading or on error
        if (snapshot.connectionState == ConnectionState.waiting || 
            snapshot.hasError || 
            !(snapshot.hasData) || 
            snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final products = snapshot.data!;
        
        // Use a fixed height layout with absolute constraints
        return SizedBox(
          height: 160, // Strictly enforced height
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sản phẩm đề xuất',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Navigate to a screen showing all related products
                      },
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Xem thêm', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              
              // Products row (remaining height)
              Expanded(
                child: Row(
                  children: List.generate(
                    products.length > 2 ? 2 : products.length,
                    (index) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index == 0 ? 4.0 : 0.0,
                          left: index == 1 ? 4.0 : 0.0,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailScreen(
                                  product: products[index],
                                ),
                              ),
                            );
                          },
                          child: Card(
                            elevation: 2,
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product image
                                Expanded(
                                  flex: 3,
                                  child: Stack(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: CachedNetworkImage(
                                          imageUrl: products[index].images.isNotEmpty
                                              ? products[index].images.first
                                              : 'https://via.placeholder.com/150',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      if (products[index].isSold)
                                        Container(
                                          color: Colors.black.withOpacity(0.6),
                                          width: double.infinity,
                                          height: double.infinity,
                                          child: const Center(
                                            child: Text(
                                              'ĐÃ BÁN',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                
                                // Product info
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Title
                                        Text(
                                          products[index].title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        // Price
                                        Text(
                                          NumberFormat.currency(
                                            locale: 'vi_VN',
                                            symbol: 'đ',
                                            decimalDigits: 0,
                                          ).format(products[index].price),
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 