import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';

class ProductService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // Create a new product
  Future<void> createProduct(Product product) async {
    try {
      _isLoading = true;
      notifyListeners();

      final docRef = await _firestore.collection('products').add(product.toMap());
      
      // Update the product with its ID
      await docRef.update({'id': docRef.id});

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Get product by id
  Future<Product> getProductById(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (!doc.exists) throw Exception('Product not found');
      return Product.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw e;
    }
  }

  // Get products by seller id
  Stream<List<Product>> getUserProducts(String sellerId) {
    return _firestore
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromMap(doc.data(), doc.id)).toList());
  }

  // Get all products
  Stream<List<Product>> getAllProducts() {
    return _firestore
        .collection('products')
        .where('isSold', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromMap(doc.data(), doc.id)).toList());
  }

  // Update product status
  Future<void> updateProductStatus(String productId, bool isSold) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('products').doc(productId).update({
        'isSold': isSold,
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Get the product to delete its images
      final product = await getProductById(productId);

      // Delete images from storage
      for (final imageUrl in product.images) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (e) {
          print('Error deleting image: $e');
        }
      }

      // Delete the product document
      await _firestore.collection('products').doc(productId).delete();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Upload product images
  Future<List<String>> uploadProductImages(List<dynamic> images) async {
    try {
      _isLoading = true;
      notifyListeners();

      final List<String> imageUrls = [];

      for (final image in images) {
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final ref = _storage.ref().child('products/$fileName');
        
        UploadTask uploadTask;
        if (kIsWeb) {
          // For web
          if (image is XFile) {
            final bytes = await image.readAsBytes();
            uploadTask = ref.putData(
              bytes,
              SettableMetadata(
                contentType: 'image/${image.name.split('.').last}',
                customMetadata: {'picked-file-path': image.name},
              ),
            );
          } else {
            throw Exception('Unsupported image type for web');
          }
        } else {
          // For mobile
          if (image is File) {
            uploadTask = ref.putFile(image);
          } else {
            throw Exception('Unsupported image type for mobile');
          }
        }

        final snapshot = await uploadTask;
        final url = await snapshot.ref.getDownloadURL();
        imageUrls.add(url);
      }

      _isLoading = false;
      notifyListeners();

      return imageUrls;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Advanced search products with multiple filters
  Stream<List<Product>> searchProductsAdvanced({
    String? query,
    String? category,
    double? minPrice,
    double? maxPrice,
    String? condition,
    String? sortBy,
  }) {
    Query productsQuery = _firestore.collection('products').where('isSold', isEqualTo: false);
    
    // Apply category filter
    if (category != null && category != 'Tất cả') {
      productsQuery = productsQuery.where('category', isEqualTo: category);
    }
    
    // Apply condition filter
    if (condition != null) {
      productsQuery = productsQuery.where('condition', isEqualTo: condition);
    }
    
    // Apply sorting
    if (sortBy != null) {
      switch (sortBy) {
        case 'Mới nhất':
          productsQuery = productsQuery.orderBy('createdAt', descending: true);
          break;
        case 'Giá thấp đến cao':
          productsQuery = productsQuery.orderBy('price', descending: false);
          break;
        case 'Giá cao đến thấp':
          productsQuery = productsQuery.orderBy('price', descending: true);
          break;
        case 'Bán chạy':
          productsQuery = productsQuery.orderBy('viewCount', descending: true);
          break;
        case 'Đánh giá cao':
          productsQuery = productsQuery.orderBy('favoriteCount', descending: true);
          break;
        default:
          productsQuery = productsQuery.orderBy('createdAt', descending: true);
      }
    } else {
      productsQuery = productsQuery.orderBy('createdAt', descending: true);
    }
    
    return productsQuery.snapshots().map((snapshot) {
      List<Product> products = snapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // Apply price filter (client-side filtering since Firestore doesn't support range queries on multiple fields)
      if (minPrice != null || maxPrice != null) {
        products = products.where((product) {
          if (minPrice != null && product.price < minPrice) {
            return false;
          }
          if (maxPrice != null && product.price > maxPrice) {
            return false;
          }
          return true;
        }).toList();
      }
      
      // Apply text search (client-side filtering for more complex search)
      if (query != null && query.isNotEmpty) {
        final lowercaseQuery = query.toLowerCase();
        products = products.where((product) {
          final titleMatch = product.title.toLowerCase().contains(lowercaseQuery);
          final descriptionMatch = product.description.toLowerCase().contains(lowercaseQuery);
          final tagMatch = product.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
          final categoryMatch = product.category.toLowerCase().contains(lowercaseQuery);
          
          return titleMatch || descriptionMatch || tagMatch || categoryMatch;
        }).toList();
      }
      
      return products;
    });
  }

  // Get used items 
  Stream<List<Product>> getUsedItems() {
    return _firestore
        .collection('products')
        .where('category', isEqualTo: 'Đồ đã qua sử dụng')
        .where('isSold', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromMap(doc.data(), doc.id)).toList());
  }

  // Get recommended products for user
  Future<List<Product>> getRecommendedProducts({int limit = 10}) async {
    try {
      // This is a simple recommendation based on most viewed products
      // In a real-world scenario, this would incorporate user preferences and behavior
      final snapshot = await _firestore
          .collection('products')
          .where('isSold', isEqualTo: false)
          .orderBy('viewCount', descending: true)
          .limit(limit)
          .get();
          
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting recommended products: $e');
      return [];
    }
  }
  
  // Search products (basic)
  Stream<List<Product>> searchProducts(String query) {
    return _firestore
        .collection('products')
        .where('isSold', isEqualTo: false)
        .orderBy('title')
        .startAt([query])
        .endAt([query + '\uf8ff'])
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromMap(doc.data(), doc.id)).toList());
  }

  // Get products by category
  Stream<List<Product>> getProductsByCategory(String category) {
    if (category == 'Tất cả') {
      return getAllProducts();
    }
    
    return _firestore
        .collection('products')
        .where('category', isEqualTo: category)
        .where('isSold', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<Product>> getRelatedProducts({
    required String category,
    required String excludeProductId,
    int limit = 10,
  }) {
    return _firestore
        .collection('products')
        .where('category', isEqualTo: category)
        .where('isSold', isEqualTo: false)
        .where(FieldPath.documentId, isNotEqualTo: excludeProductId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
} 