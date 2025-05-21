import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/moderation_result.dart';
import '../services/user_service.dart';
import '../services/ntt_point_service.dart';
import '../utils/location_utils.dart' as locUtils;
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:geolocator/geolocator.dart';

class ProductService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NTTPointService? _nttPointService;
  bool _isLoading = false;
  bool _disposed = false;

  ProductService({NTTPointService? nttPointService}) : _nttPointService = nttPointService;

  bool get isLoading => _isLoading;

  // Hằng số cho loại sản phẩm đồ tặng
  static const String DONATION_CATEGORY = 'Đồ tặng';

  // Create a new product
  Future<Product> createProduct(Product product) async {
    try {
      if (!_disposed) {
        _isLoading = true;
        notifyListeners();
      }

      final docRef = await _firestore.collection('products').add(product.toMap());
      
      // Update the product with its ID
      await docRef.update({'id': docRef.id});
      
      // Xử lý NTTPoint cho sản phẩm đồ tặng
      if (product.category == DONATION_CATEGORY && _nttPointService != null) {
        await _nttPointService!.addPointsForDonationProduct(
          product.sellerId, 
          docRef.id, 
          product.title
        );
      }

      final createdProduct = product.copyWith(id: docRef.id);
      
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
      
      return createdProduct;
    } catch (e) {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
      throw e;
    }
  }

  // Get product by id
  Future<Product> getProductById(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (!doc.exists) throw Exception('Product not found');
      return Product.fromMap(doc.data()! as Map<String, dynamic>, doc.id);
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
            snapshot.docs.map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // Get all products
  Stream<List<Product>> getAllProducts() {
    return _firestore
        .collection('products')
        .where('isSold', isEqualTo: false)
        .where('status', whereNotIn: ['pending_review', 'rejected'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // Update product
  Future<void> updateProduct(Product product) async {
    try {
      if (!_disposed) {
        _isLoading = true;
        notifyListeners();
      }

      // Lấy sản phẩm cũ để kiểm tra thay đổi danh mục
      final oldProduct = await getProductById(product.id);
      
      // Cập nhật sản phẩm
      await _firestore.collection('products').doc(product.id).update(product.toMap());

      // Xử lý NTTPoint cho sản phẩm đồ tặng
      if (_nttPointService != null) {
        // Nếu sản phẩm mới là đồ tặng và sản phẩm cũ không phải
        if (product.category == DONATION_CATEGORY && oldProduct.category != DONATION_CATEGORY) {
          await _nttPointService!.addPointsForDonationProduct(
            product.sellerId, 
            product.id, 
            product.title
          );
        } 
        // Nếu sản phẩm cũ là đồ tặng và sản phẩm mới không phải
        else if (oldProduct.category == DONATION_CATEGORY && product.category != DONATION_CATEGORY) {
          await _nttPointService!.deductPointsForDonationProduct(
            product.sellerId, 
            product.id, 
            product.title
          );
        }
      }

      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
      throw e;
    }
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
      
      // Xử lý NTTPoint nếu xóa sản phẩm đồ tặng
      if (product.category == DONATION_CATEGORY && _nttPointService != null) {
        await _nttPointService!.deductPointsForDonationProduct(
          product.sellerId, 
          productId, 
          product.title
        );
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
    Query productsQuery = _firestore.collection('products')
        .where('isSold', isEqualTo: false)
        .where('status', whereNotIn: ['pending_review', 'rejected']);
    
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
            snapshot.docs.map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // Get recommended products for user
  Future<List<Product>> getRecommendedProducts({int limit = 5}) async {
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
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting recommended products: $e');
      return [];
    }
  }
  
  // Get personalized recommended products for user based on their behavior
  Future<List<Product>> getRecommendedProductsForUser(String userId, {int limit = 5}) async {
    try {
      if (userId.isEmpty) {
        // Fallback to regular recommendations if no user ID provided
        return getRecommendedProducts(limit: limit);
      }
      
      // 1. Get user data to access their preferences and history
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return getRecommendedProducts(limit: limit);
      
      // 2. Get user's recently viewed products (most important for recommendation)
      List<String> recentlyViewedIds = List<String>.from(userDoc.data()?['recentlyViewed'] ?? []);
      
      // If user has no recently viewed products, return generic recommendations
      if (recentlyViewedIds.isEmpty) {
        return getRecommendedProducts(limit: limit);
      }
      
      // 3. Get full details of recently viewed products to get their categories
      List<Product> recentlyViewedProducts = [];
      Set<String> categories = {};
      
      // Limit to last 5 viewed products
      List<String> limitedRecentIds = recentlyViewedIds.take(5).toList();
      
      // Get details of recently viewed products
      if (limitedRecentIds.isNotEmpty) {
        final recentProductsSnapshot = await _firestore
            .collection('products')
            .where(FieldPath.documentId, whereIn: limitedRecentIds)
            .get();
            
        // Convert to Product objects and extract categories
        for (var doc in recentProductsSnapshot.docs) {
          final product = Product.fromMap(doc.data(), doc.id);
          recentlyViewedProducts.add(product);
          categories.add(product.category);
          
          // Initialize category in the map if not exists
          if (!categories.contains(product.category)) {
            categories.add(product.category);
          }
        }
      }
      
      // 4. For each category in recently viewed products, get 2 more similar products
      List<Product> recommendations = [];
      
      // Add recently viewed products first
      recommendations.addAll(recentlyViewedProducts);
      
      // For each category, get 2 additional products
      for (var category in categories) {
        final excludeIds = recentlyViewedProducts
            .where((p) => p.category == category)
            .map((p) => p.id)
            .toList();
        
        final categoryRecsSnapshot = await _firestore
            .collection('products')
            .where('category', isEqualTo: category)
            .where('isSold', isEqualTo: false)
            .where(FieldPath.documentId, whereNotIn: excludeIds)
            .orderBy('createdAt', descending: true)
            .limit(2) // Get 2 more products per category
            .get();
            
        final categoryRecs = categoryRecsSnapshot.docs
            .map((doc) => Product.fromMap(doc.data(), doc.id))
            .toList();
            
        recommendations.addAll(categoryRecs);
      }
      
      // 5. If we don't have enough recommendations, add popular products
      if (recommendations.length < limit) {
        final existingIds = recommendations.map((p) => p.id).toList();
        
        final popularProductsSnapshot = await _firestore
            .collection('products')
            .where('isSold', isEqualTo: false)
            .where(FieldPath.documentId, whereNotIn: existingIds)
            .orderBy('viewCount', descending: true)
            .limit(limit - recommendations.length)
            .get();
            
        final popularProducts = popularProductsSnapshot.docs
            .map((doc) => Product.fromMap(doc.data(), doc.id))
            .toList();
            
        recommendations.addAll(popularProducts);
      }
      
      // 6. Limit to requested number
      if (recommendations.length > limit) {
        recommendations = recommendations.take(limit).toList();
      }
      
      return recommendations;
    } catch (e) {
      print('Error getting personalized recommendations: $e');
      // Fallback to regular recommendations in case of error
      return getRecommendedProducts(limit: limit);
    }
  }
  
  // Method to update the user's recently viewed products
  Future<void> addToRecentlyViewed(String userId, String productId) async {
    if (userId.isEmpty || productId.isEmpty) return;
    
    try {
      // Get the user document
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();
      
      if (userDoc.exists) {
        // Get the current recently viewed list or create empty one
        List<String> recentlyViewed = List<String>.from(userDoc.data()?['recentlyViewed'] ?? []);
        
        // Remove the product if it already exists to avoid duplicates
        recentlyViewed.remove(productId);
        
        // Add the new product at the beginning of the list
        recentlyViewed.insert(0, productId);
        
        // Keep only the most recent 20 items
        if (recentlyViewed.length > 20) {
          recentlyViewed = recentlyViewed.sublist(0, 20);
        }
        
        // Update the user document
        await userRef.update({'recentlyViewed': recentlyViewed});
      }
    } catch (e) {
      print('Error updating recently viewed: $e');
    }
  }
  
  // Method to add to search history
  Future<void> addToSearchHistory(String userId, String searchQuery) async {
    if (userId.isEmpty || searchQuery.isEmpty) return;
    
    try {
      // Get the user document
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();
      
      if (userDoc.exists) {
        // Get the current search history or create empty one
        List<String> searchHistory = List<String>.from(userDoc.data()?['searchHistory'] ?? []);
        
        // Remove the query if it already exists to avoid duplicates
        searchHistory.remove(searchQuery);
        
        // Add the new search query at the beginning
        searchHistory.insert(0, searchQuery);
        
        // Keep only the most recent 20 items
        if (searchHistory.length > 20) {
          searchHistory = searchHistory.sublist(0, 20);
        }
        
        // Update the user document
        await userRef.update({'searchHistory': searchHistory});
      }
    } catch (e) {
      print('Error updating search history: $e');
    }
  }
  
  // Method to increment product view count
  Future<void> incrementProductViewCount(String productId) async {
    if (productId.isEmpty) return;
    
    try {
      // Get product ref
      final productRef = _firestore.collection('products').doc(productId);
      
      // Use transaction to safely increment
      await _firestore.runTransaction((transaction) async {
        // Get current document
        DocumentSnapshot productDoc = await transaction.get(productRef);
        
        if (productDoc.exists) {
          // Get current view count or default to 0
          int currentViews = (productDoc.data() as Map<String, dynamic>)['viewCount'] ?? 0;
          
          // Update with incremented count
          transaction.update(productRef, {'viewCount': currentViews + 1});
        }
      });
    } catch (e) {
      print('Error incrementing view count: $e');
    }
  }

  // Search products (basic)
  Stream<List<Product>> searchProducts(String query) {
    return _firestore
        .collection('products')
        .where('isSold', isEqualTo: false)
        .where('status', whereNotIn: ['pending_review', 'rejected'])
        .orderBy('title')
        .startAt([query])
        .endAt([query + '\uf8ff'])
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // Lấy sản phẩm theo danh mục
  Stream<List<Product>> getProductsByCategory(String categoryId, {String sortBy = 'newest'}) {
    print('Đang tìm kiếm sản phẩm theo danh mục ID: $categoryId với sortBy: $sortBy');
    
    // Nếu danh mục là "all" thì không lọc theo danh mục
    if (categoryId == 'all') {
      print('Tìm kiếm tất cả danh mục');
      
      Query query = _firestore.collection('products')
          .where('isSold', isEqualTo: false)
          .where('status', whereIn: ['available', 'verified']);
      
      // Sắp xếp cho trường hợp "Tất cả"
      if (sortBy == 'newest') {
        query = query.orderBy('createdAt', descending: true);
      } else if (sortBy == 'price_asc') {
        query = query.orderBy('price', descending: false);
      } else if (sortBy == 'price_desc') {
        query = query.orderBy('price', descending: true);
      }
      
      return query.snapshots().map((snapshot) {
        final products = snapshot.docs.map((doc) {
          return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
        
        print('Tìm thấy ${products.length} sản phẩm từ tất cả danh mục');
        return products;
      });
    } else {
      // Lấy tất cả sản phẩm
      return _firestore.collection('products')
          .where('isSold', isEqualTo: false)
          .where('status', whereIn: ['available', 'verified'])
          .snapshots()
          .asyncMap((snapshot) async {
            // Tìm tên danh mục từ ID
            String categoryName = categoryId;
            try {
              final categoryDoc = await _firestore.collection('categories').doc(categoryId).get();
              if (categoryDoc.exists && categoryDoc.data() != null) {
                String? name = categoryDoc.data()!['name'];
                if (name != null && name.isNotEmpty) {
                  categoryName = name;
                }
              }
            } catch (e) {
              print('Lỗi khi tìm tên danh mục: $e');
            }
            
            // Lọc sản phẩm theo tên danh mục
            final allProducts = snapshot.docs.map((doc) => 
              Product.fromMap(doc.data() as Map<String, dynamic>, doc.id)
            ).toList();
            
            final filteredProducts = allProducts.where((product) {
              return product.category == categoryName;
            }).toList();
            
            // Sắp xếp sản phẩm
            if (sortBy == 'newest') {
              filteredProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            } else if (sortBy == 'price_asc') {
              filteredProducts.sort((a, b) => a.price.compareTo(b.price));
            } else if (sortBy == 'price_desc') {
              filteredProducts.sort((a, b) => b.price.compareTo(a.price));
            }
            
            return filteredProducts;
          });
    }
  }

  Stream<List<Product>> getRelatedProducts({
    required String category,
    required String excludeProductId,
    int limit = 10,
  }) {
    if (category.isEmpty) {
      // Trả về Stream rỗng nếu category không hợp lệ
      return Stream.value([]);
    }

    try {
      return _firestore
          .collection('products')
          .where('category', isEqualTo: category)
          .where('isSold', isEqualTo: false)
          .where('status', whereNotIn: ['pending_review', 'rejected'])
          .orderBy('createdAt', descending: true)
          .limit(limit + 1) // Fetch one extra to account for filtering
          .snapshots()
          .map((snapshot) {
        try {
          List<Product> products = [];
          
          // Kiểm tra snapshot có dữ liệu không
          if (snapshot.docs.isNotEmpty) {
            products = snapshot.docs
                .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                .where((product) => product.id != excludeProductId) // Filter out the current product
                .take(limit) // Take only the number we need
                .toList();
          }
          
          return products;
        } catch (e) {
          debugPrint('Lỗi khi xử lý dữ liệu sản phẩm liên quan: $e');
          return <Product>[];
        }
      }).handleError((error) {
        debugPrint('Lỗi Stream sản phẩm liên quan: $error');
        return <Product>[];
      });
    } catch (e) {
      debugPrint('Lỗi tạo Stream sản phẩm liên quan: $e');
      return Stream.value([]);
    }
  }

  // Thêm sản phẩm mới với kiểm duyệt
  Future<String> addProductWithModeration({
    required String title,
    required String description,
    required double price,
    required String category,
    required List<String> images,
    required String condition,
    required Map<String, dynamic>? location,
    List<String> tags = const [],
    Map<String, String> specifications = const {},
  }) async {
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      if (!_disposed) {
        _isLoading = true;
        notifyListeners();
      }

      // Tạo ID mới cho sản phẩm
      final String productId = _firestore.collection('products').doc().id;
      
      // Lấy thông tin người bán từ profile
      DocumentSnapshot userSnapshot = await _firestore.collection('users').doc(user.uid).get();
      String sellerName = userSnapshot.exists ? userSnapshot.get('displayName') ?? user.displayName ?? 'Người dùng' : user.displayName ?? 'Người dùng';
      String sellerAvatar = userSnapshot.exists ? userSnapshot.get('photoURL') ?? '' : '';
      
      // Chuyển đổi location thành Map nếu là String
      Map<String, dynamic> locationMap;
      if (location is String) {
        locationMap = {
          'address': location as String,
          'lat': 10.7326,  // Vị trí mặc định
          'lng': 106.6975, // Vị trí mặc định
        };
      } else {
        locationMap = location ?? {
          'address': 'Không xác định',
          'lat': 10.7326,
          'lng': 106.6975,
        };
      }
      
      // Tạo sản phẩm mới với trạng thái đang chờ kiểm duyệt
      final Product newProduct = Product(
        id: productId,
        title: title,
        description: description,
        price: price,
        category: category,
        images: images,
        sellerId: user.uid,
        sellerName: sellerName,
        sellerAvatar: sellerAvatar,
        createdAt: DateTime.now(),
        isSold: false,
        condition: condition,
        location: locationMap,
        tags: tags,
        specifications: specifications,
        status: ProductStatus.pending_review,
      );
      
      // Lưu sản phẩm vào Firestore
      await _firestore.collection('products').doc(productId).set(newProduct.toMap());
      
      // Xử lý NTTPoint cho sản phẩm đồ tặng
      if (category == DONATION_CATEGORY && _nttPointService != null) {
        await _nttPointService!.addPointsForDonationProduct(
          user.uid, 
          productId, 
          title
        );
      }
      
      // Yêu cầu kiểm duyệt sản phẩm (thông qua Cloud Function hoặc gọi trực tiếp)
      await _requestProductModeration(productId, newProduct);
      
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
      
      return productId;
    } catch (e) {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
      throw Exception('Lỗi khi thêm sản phẩm: $e');
    }
  }
  
  // Yêu cầu kiểm duyệt sản phẩm
  Future<void> _requestProductModeration(String productId, Product product) async {
    try {
      // Gọi Cloud Function để kiểm duyệt sản phẩm
      // Trong môi trường thực tế, bạn có thể gọi một Cloud Function để xử lý kiểm duyệt bất đồng bộ
      
      // Đối với mục đích demo, giả lập gửi yêu cầu kiểm duyệt
      await _firestore.collection('moderation_queue').doc(productId).set({
        'productId': productId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      
      // Trong môi trường thực tế, Cloud Function sẽ xử lý kiểm duyệt và cập nhật trạng thái sản phẩm
    } catch (e) {
      debugPrint('Lỗi khi yêu cầu kiểm duyệt: $e');
      // Không throw exception ở đây để không làm gián đoạn quá trình thêm sản phẩm
    }
  }
  
  // Lấy thông tin kiểm duyệt của sản phẩm
  Future<ModerationResult?> getProductModerationInfo(String productId) async {
    try {
      // Truy vấn kết quả kiểm duyệt mới nhất cho sản phẩm
      final querySnapshot = await _firestore
          .collection('moderation_results')
          .where('productId', isEqualTo: productId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      
      debugPrint('Kiểm tra thông tin kiểm duyệt cho sản phẩm ID: $productId');
      
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        debugPrint('Tìm thấy thông tin kiểm duyệt trong bảng moderation_results');
        return ModerationResult.fromMap(doc.data(), doc.id);
      } 
      
      // Nếu không tìm thấy trong moderation_results, kiểm tra trong sản phẩm
      final productDoc = await _firestore.collection('products').doc(productId).get();
      if (productDoc.exists) {
        final productData = productDoc.data();
        
        // Kiểm tra nếu moderationInfo có trong sản phẩm
        if (productData != null && productData['moderationInfo'] != null) {
          debugPrint('Sản phẩm có thông tin kiểm duyệt trong trường moderationInfo');
          
          // Tạo ModerationResult từ thông tin trong sản phẩm
          Map<String, dynamic> moderationInfo = productData['moderationInfo'];
          
          // Xác định trạng thái kiểm duyệt
          ModerationStatus status;
          if (productData['status'] == 'available') {
            status = ModerationStatus.approved;
          } else if (productData['status'] == 'rejected') {
            status = ModerationStatus.rejected;
          } else if (productData['status'] == 'pending_review') {
            status = ModerationStatus.pending;
          } else {
            status = ModerationStatus.pending;
          }
          
          // Tạo kết quả kiểm duyệt mặc định từ thông tin sản phẩm
          return ModerationResult(
            id: 'product-moderation-${productId}',
            productId: productId,
            status: status,
            createdAt: productData['createdAt'] != null 
                ? (productData['createdAt'] as Timestamp).toDate() 
                : DateTime.now(),
            imageScore: moderationInfo['imageScore'] ?? 70,
            contentScore: moderationInfo['contentScore'] ?? 70,
            complianceScore: moderationInfo['complianceScore'] ?? 70,
            totalScore: moderationInfo['totalScore'] ?? 70,
            rejectionReason: moderationInfo['rejectionReason'] ?? moderationInfo['reason'],
            issues: moderationInfo['issues'] != null 
                ? (moderationInfo['issues'] as List).map((i) => 
                    ModerationIssue(
                      type: i['type'] ?? 'content', 
                      severity: i['severity'] ?? 'medium', 
                      description: i['description'] ?? 'Không có mô tả'
                    )).toList() 
                : [],
          );
        } else {
          debugPrint('Sản phẩm không có thông tin kiểm duyệt');
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Lỗi khi lấy thông tin kiểm duyệt: $e');
      return null;
    }
  }
  
  // Cập nhật sản phẩm sau khi chỉnh sửa (với kiểm duyệt)
  Future<void> updateProductWithModeration({
    required String id,
    required String title,
    required String description,
    required double price,
    required String category,
    required List<String> images,
    required String condition,
    required Map<String, dynamic>? location,
    List<String> tags = const [],
    Map<String, String> specifications = const {},
  }) async {
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }
      
      // Kiểm tra quyền sở hữu sản phẩm
      DocumentSnapshot productSnapshot = await _firestore.collection('products').doc(id).get();
      if (!productSnapshot.exists) {
        throw Exception('Sản phẩm không tồn tại');
      }
      
      Map<String, dynamic> productData = productSnapshot.data() as Map<String, dynamic>;
      if (productData['sellerId'] != user.uid) {
        throw Exception('Không có quyền chỉnh sửa sản phẩm này');
      }
      
      // Cập nhật sản phẩm với trạng thái đang chờ kiểm duyệt lại
      Map<String, dynamic> updateData = {
        'title': title,
        'description': description,
        'price': price,
        'category': category,
        'images': images,
        'condition': condition,
        'location': location,
        'tags': tags,
        'specifications': specifications,
        'status': ProductStatus.pending_review.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await _firestore.collection('products').doc(id).update(updateData);
      
      // Yêu cầu kiểm duyệt lại
      await _requestProductModeration(id, Product.fromMap(productData, id));
    } catch (e) {
      throw Exception('Lỗi khi cập nhật sản phẩm: $e');
    }
  }

  // Lấy tất cả sản phẩm của người dùng dưới dạng List (không phải Stream)
  Future<List<Product>> getUserProductsList(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
          
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      debugPrint('Lỗi khi lấy danh sách sản phẩm: $e');
      throw Exception('Không thể lấy danh sách sản phẩm: $e');
    }
  }
  
  // Lấy toàn bộ lịch sử kiểm duyệt của một sản phẩm
  Future<List<ModerationResult>> getProductModerationHistory(String productId) async {
    try {
      List<ModerationResult> results = [];
      
      // Kiểm tra trong bảng moderation_results
      final querySnapshot = await _firestore
          .collection('moderation_results')
          .where('productId', isEqualTo: productId)
          .orderBy('createdAt', descending: true)
          .get();
      
      debugPrint('Tìm thấy ${querySnapshot.docs.length} kết quả kiểm duyệt cho sản phẩm $productId');
      
      if (querySnapshot.docs.isNotEmpty) {
        results = querySnapshot.docs
            .map((doc) => ModerationResult.fromMap(doc.data(), doc.id))
            .toList();
      }
      
      // Nếu không có kết quả trong bảng moderation_results, kiểm tra trong sản phẩm 
      if (results.isEmpty) {
        final productDoc = await _firestore.collection('products').doc(productId).get();
        if (productDoc.exists) {
          final productData = productDoc.data();
          
          // Kiểm tra nếu moderationInfo có trong sản phẩm
          if (productData != null && productData['moderationInfo'] != null) {
            debugPrint('Sản phẩm $productId có chứa thông tin kiểm duyệt (moderationInfo)');
            
            // Tạo ModerationResult từ thông tin trong sản phẩm
            Map<String, dynamic> moderationInfo = productData['moderationInfo'];
            
            // Xác định trạng thái kiểm duyệt
            ModerationStatus status;
            if (productData['status'] == 'available') {
              status = ModerationStatus.approved;
            } else if (productData['status'] == 'rejected') {
              status = ModerationStatus.rejected;
            } else if (productData['status'] == 'pending_review') {
              status = ModerationStatus.pending;
            } else {
              status = ModerationStatus.pending;
            }
            
            // Tạo kết quả kiểm duyệt mặc định từ thông tin sản phẩm
            ModerationResult defaultResult = ModerationResult(
              id: 'product-moderation-${productId}',
              productId: productId,
              status: status,
              createdAt: productData['createdAt'] != null 
                  ? (productData['createdAt'] as Timestamp).toDate() 
                  : DateTime.now(),
              imageScore: moderationInfo['imageScore'] ?? 70,
              contentScore: moderationInfo['contentScore'] ?? 70,
              complianceScore: moderationInfo['complianceScore'] ?? 70,
              totalScore: moderationInfo['totalScore'] ?? 70,
              rejectionReason: moderationInfo['rejectionReason'] ?? moderationInfo['reason'],
              issues: moderationInfo['issues'] != null 
                  ? (moderationInfo['issues'] as List).map((i) => 
                      ModerationIssue(
                        type: i['type'] ?? 'content', 
                        severity: i['severity'] ?? 'medium', 
                        description: i['description'] ?? 'Không có mô tả'
                      )).toList() 
                  : [],
            );
            
            results.add(defaultResult);
          } else {
            debugPrint('Sản phẩm $productId không có thông tin kiểm duyệt');
          }
        } else {
          debugPrint('Không tìm thấy sản phẩm với ID $productId');
        }
      }
      
      return results;
    } catch (e) {
      debugPrint('Lỗi khi lấy lịch sử kiểm duyệt: $e');
      return [];
    }
  }

  // Lấy danh sách sản phẩm chờ kiểm duyệt
  Future<List<Product>> getProductsPendingModeration() async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('moderationStatus', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting pending moderation products: $e');
      return [];
    }
  }

  // Phê duyệt sản phẩm
  Future<bool> approveProduct(String productId, Map<String, dynamic> moderationResults) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return false;
      }

      // Calculate scores based on the provided rating (1-5 scale)
      final double rating = moderationResults['score'] ?? 5.0;
      final int normalizedScore = ((rating / 5.0) * 100).round();

      // Create a moderation result document
      final moderationResult = {
        'productId': productId,
        'status': 'approved',
        'createdAt': FieldValue.serverTimestamp(),
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewerId': user.uid,
        'imageScore': normalizedScore,
        'contentScore': normalizedScore,
        'complianceScore': normalizedScore,
        'totalScore': normalizedScore,
        'comment': moderationResults['comment'] ?? '',
      };

      // Add the moderation result to the collection
      await _firestore.collection('moderation_results').add(moderationResult);

      // Update the product status
      await _firestore.collection('products').doc(productId).update({
        'moderationStatus': 'approved',
        'moderationResults': moderationResults,
        'status': 'available',
      });
      
      return true;
    } catch (e) {
      debugPrint('Error approving product: $e');
      return false;
    }
  }

  // Từ chối sản phẩm
  Future<bool> rejectProduct(String productId, Map<String, dynamic> moderationResults) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return false;
      }

      // Calculate scores based on the provided rating (1-5 scale)
      final double rating = moderationResults['score'] ?? 3.0;
      final int normalizedScore = ((rating / 5.0) * 100).round();

      // Create issues from the selected issues
      List<Map<String, dynamic>> issues = [];
      if (moderationResults['issues'] != null) {
        List<String> issueStrings = List<String>.from(moderationResults['issues']);
        issues = issueStrings.map((issue) => {
          'type': 'content',
          'severity': 'medium',
          'description': issue,
        }).toList();
      }

      // Create a moderation result document
      final moderationResult = {
        'productId': productId,
        'status': 'rejected',
        'createdAt': FieldValue.serverTimestamp(),
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewerId': user.uid,
        'imageScore': normalizedScore,
        'contentScore': normalizedScore,
        'complianceScore': normalizedScore,
        'totalScore': normalizedScore,
        'rejectionReason': moderationResults['reason'] ?? '',
        'issues': issues,
      };

      // Add the moderation result to the collection
      await _firestore.collection('moderation_results').add(moderationResult);

      // Update the product status
      await _firestore.collection('products').doc(productId).update({
        'moderationStatus': 'rejected',
        'moderationResults': moderationResults,
        'status': 'rejected',
      });
      
      return true;
    } catch (e) {
      debugPrint('Error rejecting product: $e');
      return false;
    }
  }

  // Lấy thống kê kiểm duyệt
  Future<Map<String, dynamic>> getModerationStats() async {
    try {
      final stats = {
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'total': 0,
      };
      
      // Thống kê số lượng sản phẩm theo trạng thái kiểm duyệt
      final pendingQuery = await _firestore
          .collection('products')
          .where('moderationStatus', isEqualTo: 'pending')
          .count()
          .get();
      
      final approvedQuery = await _firestore
          .collection('products')
          .where('moderationStatus', isEqualTo: 'approved')
          .count()
          .get();
      
      final rejectedQuery = await _firestore
          .collection('products')
          .where('moderationStatus', isEqualTo: 'rejected')
          .count()
          .get();
      
      final totalQuery = await _firestore
          .collection('products')
          .count()
          .get();
      
      stats['pending'] = pendingQuery.count!;
      stats['approved'] = approvedQuery.count!;
      stats['rejected'] = rejectedQuery.count!;
      stats['total'] = totalQuery.count!;
      
      return stats;
    } catch (e) {
      print('Error getting moderation stats: $e');
      return {
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'total': 0,
      };
    }
  }

  Future<List<Product>> getPendingProducts() async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('moderationStatus', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error getting pending products: $e');
      return [];
    }
  }

  Future<Map<String, int>> getModerationStatistics() async {
    try {
      // Get all products in a single query
      final snap = await _firestore.collection('products').get();
      
      int pendingCount = 0;
      int approvedCount = 0;
      int rejectedCount = 0;
      
      // Count products by moderation status
      for (var doc in snap.docs) {
        final product = Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        switch (product.moderationStatus) {
          case ModerationStatus.pending:
            pendingCount++;
            break;
          case ModerationStatus.approved:
            approvedCount++;
            break;
          case ModerationStatus.rejected:
            rejectedCount++;
            break;
        }
      }
      
      return {
        'pending': pendingCount,
        'approved': approvedCount,
        'rejected': rejectedCount,
        'total': snap.docs.length,
      };
    } catch (e) {
      print('Error getting moderation statistics: $e');
      return {
        'pending': 0,
        'approved': 0,
        'rejected': 0,
        'total': 0,
      };
    }
  }

  // Update product
  Future<void> updateProductWithFields({
    required String productId,
    required String title,
    required String description,
    required double price,
    double? originalPrice,
    required String category,
    required List<String> images,
    required int quantity,
    required String condition,
    required Map<String, dynamic>? location,
    List<String> tags = const [],
    Map<String, String> specifications = const {},
  }) async {
    try {
      if (!_disposed) {
        _isLoading = true;
        notifyListeners();
      }

      final productData = {
        'title': title,
        'description': description,
        'price': price,
        'originalPrice': originalPrice ?? 0.0,
        'category': category,
        'images': images,
        'quantity': quantity,
        'condition': condition,
        'location': location,
        'tags': tags,
        'specifications': specifications,
        'updatedAt': Timestamp.now(),
      };

      await _firestore.collection('products').doc(productId).update(productData);

      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
      throw e;
    }
  }

  // Tìm kiếm sản phẩm theo từ khóa
  Future<List<Product>> searchProductsByKeyword(String keyword) async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('isSold', isEqualTo: false)
          .where('status', whereNotIn: ['pending_review', 'rejected'])
          .orderBy('createdAt', descending: true)
          .get();
      
      final products = querySnapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      
      // Lọc sản phẩm theo từ khóa
      if (keyword.isNotEmpty) {
        final lowercaseKeyword = keyword.toLowerCase();
        return products.where((product) {
          final titleMatch = product.title.toLowerCase().contains(lowercaseKeyword);
          final descriptionMatch = product.description.toLowerCase().contains(lowercaseKeyword);
          final tagMatch = product.tags.any((tag) => tag.toLowerCase().contains(lowercaseKeyword));
          final categoryMatch = product.category.toLowerCase().contains(lowercaseKeyword);
          
          return titleMatch || descriptionMatch || tagMatch || categoryMatch;
        }).toList();
      }
      
      return products;
    } catch (e) {
      debugPrint('Lỗi khi tìm kiếm sản phẩm theo từ khóa: $e');
      throw e;
    }
  }

  /// Phương thức đề xuất sản phẩm nâng cao với vị trí và giá cả
  /// Sử dụng thuật toán lọc cộng tác kết hợp lọc theo vị trí và giá
  Future<List<Product>> getRecommendedProductsWithLocation({
    required String userId,
    required Map<String, double> userLocation,
    int limit = 10,
    bool verbose = true, // Tham số mới để kiểm soát lượng debug info
  }) async {
    try {
      
      if (userId.isEmpty) {
        // Fallback khi không có userId
        return getRecommendedProducts(limit: limit);
      }
      
      // 1. Lấy thông tin người dùng
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return getRecommendedProducts(limit: limit);
      }
      
      final userData = userDoc.data()!;
      
      // 2. Lấy danh sách sản phẩm đã xem gần đây
      List<String> recentlyViewedIds = List<String>.from(userData['recentlyViewed'] ?? []);
      
      // 3. Lấy thông tin chi tiết sản phẩm đã xem và danh mục
      List<Product> recentlyViewedProducts = [];
      Set<String> categories = {};
      Set<String> viewedSellerIds = {};
      // Thêm bản đồ theo dõi tần suất xuất hiện danh mục
      Map<String, int> categoryFrequency = {};
      
      if (recentlyViewedIds.isNotEmpty) {
        final limitedRecentIds = recentlyViewedIds.take(10).toList();
        final recentSnapshot = await _firestore
            .collection('products')
            .where(FieldPath.documentId, whereIn: limitedRecentIds)
            .get();
            
        for (final doc in recentSnapshot.docs) {
          final product = Product.fromMap(doc.data(), doc.id);
          recentlyViewedProducts.add(product);
          categories.add(product.category);
          viewedSellerIds.add(product.sellerId);
          
          // Tăng tần suất danh mục
          categoryFrequency[product.category] = (categoryFrequency[product.category] ?? 0) + 1;
        }
      }
      
      
      // 4. Lấy sở thích của người dùng (nếu có)
      List<String> preferredCategories = List<String>.from(userData['preferredCategories'] ?? []);
      categories.addAll(preferredCategories);
      
      
      // Tạo Set để theo dõi ID sản phẩm đã thêm để tránh trùng lặp
      Set<String> addedProductIds = Set<String>();
      
      // 5. Thu thập tất cả các sản phẩm tiềm năng
      List<Product> potentialRecommendations = [];
      
      // 5.1 Sản phẩm từ cùng danh mục
      if (categories.isNotEmpty) {
        // Ưu tiên các danh mục xuất hiện nhiều trong lịch sử xem
        List<String> prioritizedCategories = categories.toList()
          ..sort((a, b) => (categoryFrequency[b] ?? 0).compareTo(categoryFrequency[a] ?? 0));
        
        
        for (final category in prioritizedCategories) {
          final categorySnapshot = await _firestore
              .collection('products')
              .where('category', isEqualTo: category)
              .where('isSold', isEqualTo: false)
              .orderBy('viewCount', descending: true)
              .limit(5)
              .get();
              
          for (final doc in categorySnapshot.docs) {
            // Kiểm tra trùng lặp trước khi thêm vào
            if (!addedProductIds.contains(doc.id)) {
              potentialRecommendations.add(Product.fromMap(doc.data(), doc.id));
              addedProductIds.add(doc.id);
            }
          }
        }
      }
      
      // 5.2 Sản phẩm từ người bán quen thuộc
      if (viewedSellerIds.isNotEmpty) {
        
        final sellerSnapshot = await _firestore
            .collection('products')
            .where('sellerId', whereIn: viewedSellerIds.take(10).toList())
            .where('isSold', isEqualTo: false)
            .orderBy('createdAt', descending: true)
            .limit(10)
            .get();
            
        for (final doc in sellerSnapshot.docs) {
          // Kiểm tra trùng lặp
          if (!addedProductIds.contains(doc.id)) {
            potentialRecommendations.add(Product.fromMap(doc.data(), doc.id));
            addedProductIds.add(doc.id);
          }
        }
      }
      
      // 5.3 Sản phẩm phổ biến (để bổ sung)
      if (potentialRecommendations.length < limit * 2) {
        
        final popularSnapshot = await _firestore
            .collection('products')
            .where('isSold', isEqualTo: false)
            .orderBy('viewCount', descending: true)
            .limit(limit)
            .get();
            
        for (final doc in popularSnapshot.docs) {
          if (!addedProductIds.contains(doc.id)) {
            potentialRecommendations.add(Product.fromMap(doc.data(), doc.id));
            addedProductIds.add(doc.id);
          }
        }
      }
      
      
      // Cache kết quả tính khoảng cách để tránh tính lại nhiều lần
      Map<String, double> distanceCache = {};
      
      // 6. Tính điểm cho từng sản phẩm dựa trên nhiều yếu tố (lọc cộng tác)
      List<Map<String, dynamic>> scoredProducts = [];
      
      // Tính recency score cho danh mục - ưu tiên danh mục xem gần đây nhất
      Map<String, double> recencyScores = {};
      for (int i = 0; i < recentlyViewedProducts.length && i < 10; i++) {
        String category = recentlyViewedProducts[i].category;
        // Điểm giảm dần từ sản phẩm gần đây nhất (0.1 -> 0.01)
        double score = 0.1 - (i * 0.01);
        // Lấy điểm lớn nhất nếu danh mục xuất hiện nhiều lần
        recencyScores[category] = max(recencyScores[category] ?? 0, score);
      }
      
      for (final product in potentialRecommendations) {
        // 6.1 Điểm danh mục (ưu tiên danh mục đã xem và đánh dấu là yêu thích)
        double categoryScore = 0;
        if (categories.contains(product.category)) {
          categoryScore = 0.3;
          
          // Tăng điểm nếu là danh mục ưa thích
          if (preferredCategories.contains(product.category)) {
            categoryScore += 0.2;
          }
          
          // Thêm điểm recency cho danh mục mới xem gần đây
          categoryScore += recencyScores[product.category] ?? 0;
        }
        
        // 6.2 Điểm người bán (ưu tiên người bán quen thuộc)
        double sellerScore = 0;
        if (viewedSellerIds.contains(product.sellerId)) {
          sellerScore = 0.1;
        }
        
        // 6.3 Điểm vị trí (ưu tiên gần hơn)
        double distanceScore = 0;
        double distance = 999.0; // Giá trị mặc định cho khoảng cách không xác định
        
        // Lấy tọa độ vị trí từ địa chỉ sản phẩm - SỬ DỤNG PHƯƠNG THỨC BẤT ĐỒNG BỘ
        final productLocation = await locUtils.LocationUtils.getLocationFromAddressAsync(product.location);
        
        if (productLocation != null && 
            productLocation['lat'] != null && 
            productLocation['lng'] != null &&
            userLocation['lat'] != null && 
            userLocation['lng'] != null) {
          // Tạo khóa cache cho tính toán khoảng cách
          String cacheKey = "${userLocation['lat']}-${userLocation['lng']}-${productLocation['lat']}-${productLocation['lng']}";
          
          // Tính khoảng cách giữa người dùng và sản phẩm
          try {
            if (distanceCache.containsKey(cacheKey)) {
              distance = distanceCache[cacheKey]!;
            } else {
              distance = locUtils.LocationUtils.calculateDistance(
                userLocation['lat']!, 
                userLocation['lng']!,
                productLocation['lat']!, 
                productLocation['lng']!
              );
              distanceCache[cacheKey] = distance;
            }
            
            // Lưu khoảng cách để sau này tính toán tương đối giữa các sản phẩm
            distanceScore = distance <= 20 ? 1 : 0; // Chỉ để lưu trữ, sẽ tính lại sau
          } catch (e) {
            print('❌ Lỗi khi tính khoảng cách cho sản phẩm ${product.id}: $e');
          }
        } else {
          print('ℹ️ Không thể tính khoảng cách cho sản phẩm ${product.id}: Vị trí không đầy đủ hoặc không hợp lệ');
        }
        
        // 6.4 Điểm giá (ưu tiên sản phẩm có giá tương tự các sản phẩm đã xem)
        double priceScore = 0;
        double priceDiff = 0;
        
        if (recentlyViewedProducts.isNotEmpty) {
          // Tính giá trung bình của các sản phẩm đã xem
          double avgPrice = recentlyViewedProducts
              .map((p) => p.price)
              .reduce((a, b) => a + b) / recentlyViewedProducts.length;
              
          // Tính % chênh lệch giá
          if (avgPrice > 0) {
            priceDiff = (product.price - avgPrice).abs() / avgPrice;
          } else {
            priceDiff = product.price > 0 ? 1.0 : 0.0;
          }
          
          // Lưu trữ giá trị để tính toán sau
          priceScore = 1 - min(1, priceDiff); // Giá trị từ 0-1, càng gần giá trung bình càng cao
        }
        
        // Thêm dữ liệu vào danh sách để so sánh và chuẩn hóa sau
        scoredProducts.add({
          'product': product,
          'rawScore': categoryScore + sellerScore, // Điểm cơ bản không cần chuẩn hóa
          'category': product.category,
          'distance': distance,
          'priceDiff': priceDiff,
          // Lưu chi tiết cho việc hiển thị debug
          'details': {
            'categoryScore': categoryScore,
            'sellerScore': sellerScore,
            'distance': distance,
            'priceDiff': priceDiff * 100, // Chuyển về phần trăm
          }
        });
      }
      
      // Tính toán điểm tương đối giữa các sản phẩm
      if (scoredProducts.isNotEmpty) {
        // Tìm khoảng cách nhỏ nhất và lớn nhất
        double minDistance = 999.0;
        double maxDistance = 0.0;
        
        for (var product in scoredProducts) {
          double dist = product['distance'] as double;
          if (dist < minDistance && dist > 0) minDistance = dist;
          if (dist > maxDistance && dist < 900) maxDistance = dist;
        }
        
        // Chuẩn hóa điểm khoảng cách
        double distanceRange = maxDistance - minDistance;
        if (distanceRange > 0) {
          for (var product in scoredProducts) {
            double dist = product['distance'] as double;
            double normalizedDistance = dist < 900 ? (maxDistance - dist) / distanceRange : 0;
            
            // Điểm vị trí: 0-0.5
            double distanceScore = normalizedDistance * 0.5;
            
            // Điểm giá: 0-0.3 tùy thuộc vào sự chênh lệch
            double priceDiff = product['priceDiff'] as double;
            double priceScore = 0;
            if (priceDiff <= 0.1) {
              priceScore = 0.3; // Chênh lệch < 10%
            } else if (priceDiff <= 0.2) {
              priceScore = 0.25; // Chênh lệch < 20%
            } else if (priceDiff <= 0.3) {
              priceScore = 0.2; // Chênh lệch < 30%
            } else if (priceDiff <= 0.5) {
              priceScore = 0.15; // Chênh lệch < 50%
            } else if (priceDiff <= 0.8) {
              priceScore = 0.1; // Chênh lệch < 80%
            } else {
              priceScore = 0.05; // Chênh lệch > 80%
            }
            
            // Tổng điểm
            double totalScore = (product['rawScore'] as double) + distanceScore + priceScore;
            product['score'] = totalScore;
            
            // Cập nhật chi tiết
            Map<String, dynamic> details = product['details'] as Map<String, dynamic>;
            details['distanceScore'] = distanceScore;
            details['priceScore'] = priceScore;
            details['totalScore'] = totalScore;
          }
        } else {
          // Nếu tất cả sản phẩm đều có cùng khoảng cách, không cần chuẩn hóa
          for (var product in scoredProducts) {
            double priceDiff = product['priceDiff'] as double;
            double priceScore = 0;
            if (priceDiff <= 0.1) {
              priceScore = 0.3; // Chênh lệch < 10%
            } else if (priceDiff <= 0.2) {
              priceScore = 0.25; // Chênh lệch < 20%
            } else if (priceDiff <= 0.3) {
              priceScore = 0.2; // Chênh lệch < 30%
            } else if (priceDiff <= 0.5) {
              priceScore = 0.15; // Chênh lệch < 50%
            } else if (priceDiff <= 0.8) {
              priceScore = 0.1; // Chênh lệch < 80%
            } else {
              priceScore = 0.05; // Chênh lệch > 80%
            }
            
            product['score'] = (product['rawScore'] as double) + 0.25 + priceScore; // Mặc định 0.25 cho distanceScore
            
            // Cập nhật chi tiết
            Map<String, dynamic> details = product['details'] as Map<String, dynamic>;
            details['distanceScore'] = 0.25; // Giá trị mặc định
            details['priceScore'] = priceScore;
            details['totalScore'] = product['score'];
          }
        }
      }
      
      // 7. Sắp xếp theo điểm và trả về kết quả
      scoredProducts.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
      
      // Nếu điểm bằng nhau thì ưu tiên sản phẩm gần hơn
      final tiedThreshold = 0.05; // Ngưỡng xem là điểm gần bằng nhau
      
      for (int i = 0; i < scoredProducts.length - 1; i++) {
        for (int j = i + 1; j < scoredProducts.length; j++) {
          final scoreDiff = (scoredProducts[i]['score'] as double) - (scoredProducts[j]['score'] as double);
          
          // Nếu điểm gần bằng nhau, ưu tiên gần hơn
          if (scoreDiff.abs() < tiedThreshold) {
            final distanceI = scoredProducts[i]['distance'] as double;
            final distanceJ = scoredProducts[j]['distance'] as double;
            
            if (distanceJ < distanceI) {
              // Hoán đổi vị trí
              final temp = scoredProducts[i];
              scoredProducts[i] = scoredProducts[j];
              scoredProducts[j] = temp;
            }
          }
        }
      }
      
      // 8. Đa dạng hóa kết quả - Tránh quá nhiều sản phẩm từ cùng một danh mục
      List<Map<String, dynamic>> diversifiedResults = [];
      Map<String, int> categoryCount = {};
      
      // Thêm vào kết quả đa dạng, tối đa 3 sản phẩm/danh mục
      for (var product in scoredProducts) {
        String category = product['category'] as String;
        int currentCount = categoryCount[category] ?? 0;
        
        if (currentCount < 3) {
          diversifiedResults.add(product);
          categoryCount[category] = currentCount + 1;
          
          // Nếu đã đủ số lượng cần thiết, dừng lại
          if (diversifiedResults.length >= limit) break;
        }
      }
      
      // Nếu chưa đủ, bổ sung từ danh sách gốc
      if (diversifiedResults.length < limit) {
        for (var product in scoredProducts) {
          if (!diversifiedResults.contains(product)) {
            diversifiedResults.add(product);
            if (diversifiedResults.length >= limit) break;
          }
        }
      }
      
      for (int i = 0; i < min(5, diversifiedResults.length); i++) {
        final item = diversifiedResults[i];
        final product = item['product'] as Product;
        final score = item['score'] as double;
        final distance = item['distance'] as double;
        final details = item['details'] as Map<String, dynamic>;
      }
      
      // Trả về danh sách đề xuất có giới hạn và đã đa dạng hóa
      return diversifiedResults
          .map((item) => item['product'] as Product)
          .toList();
    } catch (e) {
      print('❌ Lỗi khi lấy đề xuất sản phẩm nâng cao: $e');
      // Fallback khi có lỗi
      return getRecommendedProducts(limit: limit);
    }
  }

  // Thêm phương thức override dispose để đánh dấu service đã bị hủy
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // Phương thức cập nhật vị trí người dùng
  Future<bool> updateUserLocation(String userId, Map<String, double> location) async {
    if (userId.isEmpty || location.isEmpty) return false;
    
    try {
      // Tham chiếu đến tài liệu người dùng
      final userRef = _firestore.collection('users').doc(userId);
      
      // Dữ liệu vị trí cần cập nhật
      final locationData = {
        'currentLocation': {
          'lat': location['lat'],
          'lng': location['lng'],
          'updatedAt': FieldValue.serverTimestamp(),
        }
      };
      
      // Cập nhật vị trí hiện tại
      await userRef.update(locationData);
      
      // Xác minh dữ liệu đã được lưu chính xác
      final verifyDoc = await userRef.get();
      if (verifyDoc.exists && verifyDoc.data()!.containsKey('currentLocation')) {
        final savedLocation = verifyDoc.data()!['currentLocation'];
        
        // Kiểm tra dữ liệu cập nhật có khớp không
        if (savedLocation['lat'] == location['lat'] && 
            savedLocation['lng'] == location['lng']) {
          print('✅ Đã cập nhật và xác minh vị trí người dùng: ${location['lat']}, ${location['lng']}');
          return true;
        } else {
          print('❌ Lỗi: Vị trí đã lưu (${savedLocation['lat']}, ${savedLocation['lng']}) ' 
              'không khớp với vị trí cần lưu (${location['lat']}, ${location['lng']})');
          return false;
        }
      }
      
      print('⚠️ Không thể xác minh vị trí đã lưu');
      return false;
    } catch (e) {
      print('❌ Lỗi khi cập nhật vị trí người dùng: $e');
      return false;
    }
  }
  
  // Phương thức lấy vị trí hiện tại của người dùng
  Future<Map<String, double>?> getUserLocation(String userId) async {
    if (userId.isEmpty) return null;
    
    try {
      // Lấy tài liệu người dùng
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists && userDoc.data()!.containsKey('currentLocation')) {
        final locationData = userDoc.data()!['currentLocation'];
        return {
          'lat': locationData['lat'],
          'lng': locationData['lng'],
        };
      }
      
      return null;
    } catch (e) {
      print('Lỗi khi lấy vị trí người dùng: $e');
      return null;
    }
  }
  
  // Method to update user's product view behavior including location
  Future<void> trackProductView(String userId, String productId, Map<String, double>? userLocation) async {
    if (userId.isEmpty || productId.isEmpty) return;
    
    try {
      // 1. Add to recently viewed
      await addToRecentlyViewed(userId, productId);
      
      // 2. Increment product view count
      await incrementProductViewCount(productId);
      
      // 3. Update user location if provided
      if (userLocation != null) {
        await updateUserLocation(userId, userLocation);
      }
      
      // 4. Track view in analytics (optional)
      await _firestore.collection('analytics').add({
        'userId': userId,
        'productId': productId,
        'action': 'view',
        'timestamp': FieldValue.serverTimestamp(),
        'location': userLocation,
      });
    } catch (e) {
      print('Lỗi khi theo dõi lượt xem sản phẩm: $e');
    }
  }
  
  // Phương thức đề xuất nâng cao sử dụng vị trí người dùng hiện tại từ Firestore
  Future<List<Product>> getRecommendedProductsWithCurrentLocation(String userId, {int limit = 10}) async {
    if (userId.isEmpty) {
      return getRecommendedProducts(limit: limit);
    }
    
    try {
      // Lấy vị trí hiện tại của người dùng từ Firestore
      Map<String, double>? userLocation = await getUserLocation(userId);
      
      // Nếu không có vị trí lưu trữ hoặc vị trí quá cũ (>30 phút), cố gắng lấy vị trí hiện tại
      bool needsLocationUpdate = userLocation == null;
      
      if (!needsLocationUpdate) {
        // Kiểm tra thời gian cập nhật vị trí
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists && userDoc.data()!.containsKey('currentLocation')) {
          final locationData = userDoc.data()!['currentLocation'];
          if (locationData.containsKey('updatedAt') && locationData['updatedAt'] != null) {
            final updateTime = (locationData['updatedAt'] as Timestamp).toDate();
            final timeDiff = DateTime.now().difference(updateTime).inMinutes;
            
            // Nếu vị trí cũ hơn 30 phút, cần cập nhật
            if (timeDiff > 30) {
              needsLocationUpdate = true;
              print('Vị trí người dùng đã cũ ($timeDiff phút), đang cố gắng cập nhật...');
            }
          }
        }
      }
      
      // Cố gắng lấy vị trí hiện tại nếu cần
      if (needsLocationUpdate) {
        try {
          // Kiểm tra quyền truy cập vị trí
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          
          // Nếu người dùng cho phép, lấy vị trí hiện tại
          if (permission != LocationPermission.denied && 
              permission != LocationPermission.deniedForever) {
            Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );
            
            userLocation = {
              'lat': position.latitude,
              'lng': position.longitude,
            };
            
            // Cập nhật vị trí người dùng trong Firestore và kiểm tra kết quả
            bool updateSuccess = await updateUserLocation(userId, userLocation);
            if (updateSuccess) {
              print('✅ Đã cập nhật vị trí hiện tại thành công: ${position.latitude}, ${position.longitude}');
              
              // Xác minh một lần nữa bằng cách đọc lại từ Firestore
              final verifiedLocation = await getUserLocation(userId);
              if (verifiedLocation != null) {
                userLocation = verifiedLocation;
              }
            } else {
              print('❌ Không thể cập nhật vị trí hiện tại vào Firestore');
            }
          }
        } catch (e) {
          print('❌ Không thể lấy vị trí hiện tại: $e');
        }
      }
      
      // Nếu không có vị trí, sử dụng phương thức đề xuất thông thường
      if (userLocation == null) {
        return getRecommendedProductsForUser(userId, limit: limit);
      }
      
      
      // Sử dụng phương thức đề xuất với vị trí
      return getRecommendedProductsWithLocation(
        userId: userId,
        userLocation: userLocation,
        limit: limit
      );
    } catch (e) {
      return getRecommendedProductsForUser(userId, limit: limit);
    }
  }

  // Phương thức lấy các sản phẩm mới nhất
  Future<List<Product>> getLatestProducts({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('isSold', isEqualTo: false)
          .where('status', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Lỗi khi lấy sản phẩm mới nhất: $e');
      return [];
    }
  }

  // Phương thức lấy các sản phẩm mới nhất (trong 7 ngày qua)
  Future<List<Product>> getNewArrivals({int limit = 10}) async {
    try {
      // Lấy thời điểm 7 ngày trước
      final DateTime sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      
      final snapshot = await _firestore
          .collection('products')
          .where('isSold', isEqualTo: false)
          .where('status', isEqualTo: 'approved')
          .where('createdAt', isGreaterThanOrEqualTo: sevenDaysAgo)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Lỗi khi lấy sản phẩm mới: $e');
      return [];
    }
  }

  // Update product with specified fields and Map for location
  Future<void> updateProductData({
    required String productId,
    required String title,
    required String description,
    required double price,
    double? originalPrice,
    required String category,
    required List<String> images,
    required int quantity,
    required String condition,
    required Map<String, dynamic>? location,
    List<String> tags = const [],
    Map<String, String> specifications = const {},
  }) async {
    try {
      if (!_disposed) {
        _isLoading = true;
        notifyListeners();
      }

      final productData = {
        'title': title,
        'description': description,
        'price': price,
        'originalPrice': originalPrice ?? 0.0,
        'category': category,
        'images': images,
        'quantity': quantity,
        'condition': condition,
        'location': location,
        'tags': tags,
        'specifications': specifications,
        'updatedAt': Timestamp.now(),
      };

      await _firestore.collection('products').doc(productId).update(productData);

      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
      throw e;
    }
  }

  /// Lấy danh sách sản phẩm theo trạng thái
  Future<List<Product>> getProductsByStatus(String status) async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Lỗi khi lấy sản phẩm theo trạng thái $status: $e');
      return [];
    }
  }
} 