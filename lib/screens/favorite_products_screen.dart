import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../services/user_service.dart';
import '../services/favorites_service.dart';
import '../widgets/product_card_standard.dart';

class FavoriteProductsScreen extends StatelessWidget {
  const FavoriteProductsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context);
    final user = userService.currentUser;
    final favoritesService = Provider.of<FavoritesService>(context);

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Vui lòng đăng nhập để xem sản phẩm yêu thích'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sản phẩm yêu thích'),
      ),
      body: FutureBuilder<List<String>>(
        future: favoritesService.getUserFavorites(),
        builder: (context, favoriteIdsSnapshot) {
          if (favoriteIdsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (favoriteIdsSnapshot.hasError) {
            return Center(
              child: Text('Lỗi: ${favoriteIdsSnapshot.error}'),
            );
          }

          final favoriteIds = favoriteIdsSnapshot.data ?? [];

          if (favoriteIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bạn chưa có sản phẩm yêu thích nào',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Khám phá sản phẩm ngay'),
                  ),
                ],
              ),
            );
          }

          return FutureBuilder<List<Product>>(
            future: _getFavoriteProducts(favoriteIds),
            builder: (context, productsSnapshot) {
              if (productsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (productsSnapshot.hasError) {
                return Center(
                  child: Text('Lỗi: ${productsSnapshot.error}'),
                );
              }

              final products = productsSnapshot.data ?? [];

              if (products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Không tìm thấy sản phẩm yêu thích nào',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return Dismissible(
                    key: Key(products[index].id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20.0),
                      color: Colors.red,
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                    ),
                    onDismissed: (direction) {
                      _removeFromFavorites(context, products[index].id);
                    },
                    child: ProductCardStandard(
                      product: products[index],
                      onFavoriteToggle: () {
                        // Refresh the screen when a favorite is toggled
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FavoriteProductsScreen(),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Product>> _getFavoriteProducts(List<String> favoriteIds) async {
    if (favoriteIds.isEmpty) return [];

    final firestore = FirebaseFirestore.instance;
    final List<Product> products = [];

    // Get products in batches to avoid large queries
    for (int i = 0; i < favoriteIds.length; i += 10) {
      final end = (i + 10 < favoriteIds.length) ? i + 10 : favoriteIds.length;
      final batch = favoriteIds.sublist(i, end);

      final snapshot = await firestore
          .collection('products')
          .where(FieldPath.documentId, whereIn: batch)
          .get();

      products.addAll(
        snapshot.docs.map((doc) => Product.fromMap(doc.data(), doc.id)).toList(),
      );
    }

    return products;
  }

  void _removeFromFavorites(BuildContext context, String productId) {
    try {
      final favoritesService = Provider.of<FavoritesService>(context, listen: false);
      favoritesService.removeFromFavorites(productId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa khỏi danh sách yêu thích'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
} 