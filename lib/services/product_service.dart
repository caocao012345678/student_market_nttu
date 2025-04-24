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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
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
      Map<String, List<Product>> categoryProducts = {};
      
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
          
          // Initialize category in the map if not exists
          if (!categoryProducts.containsKey(product.category)) {
            categoryProducts[product.category] = [];
          }
        }
      }
      
      // 4. For each category in recently viewed products, get 2 more similar products
      List<Product> recommendations = [];
      
      // Add recently viewed products first
      recommendations.addAll(recentlyViewedProducts);
      
      // For each category, get 2 additional products
      for (var category in categoryProducts.keys) {
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
      // Get reference to the product
      final productRef = _firestore.collection('products').doc(productId);
      
      // Use transaction to safely increment the counter
      await _firestore.runTransaction((transaction) async {
        // Get product
        final productDoc = await transaction.get(productRef);
        
        if (productDoc.exists) {
          // Get current count and increment
          final int currentCount = productDoc.data()?['viewCount'] ?? 0;
          transaction.update(productRef, {'viewCount': currentCount + 1});
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
        .orderBy('title')
        .startAt([query])
        .endAt([query + '\uf8ff'])
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // Get products by category
  Stream<List<Product>> getProductsByCategory(String categoryId, {String? sortBy}) {
    Query query;
    bool needsClientSideSorting = false;
    bool priceAscending = false;
    
    if (categoryId == 'all') {
      query = _firestore
        .collection('products')
        .where('isSold', isEqualTo: false);
    } else {
      query = _firestore
        .collection('products')
        .where('category', isEqualTo: categoryId)
        .where('isSold', isEqualTo: false);
    }
    
    // Check if sorting by price (will be done client-side)
    if (sortBy == 'price_asc' || sortBy == 'price_desc') {
      needsClientSideSorting = true;
      priceAscending = sortBy == 'price_asc';
      // Default ordering for fetching data
      query = query.orderBy('createdAt', descending: true);
    } else {
      // Apply server-side sorting for non-price fields
      switch (sortBy) {
        case 'newest':
          query = query.orderBy('createdAt', descending: true);
          break;
        case 'oldest':
          query = query.orderBy('createdAt', descending: false);
          break;
        default:
          query = query.orderBy('createdAt', descending: true);
      }
    }
    
    return query
        .snapshots()
        .map((snapshot) {
          List<Product> products = snapshot.docs
              .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();
          
          // Apply client-side sorting for price if needed
          if (needsClientSideSorting) {
            products.sort((a, b) => priceAscending 
                ? a.price.compareTo(b.price) 
                : b.price.compareTo(a.price));
          }
          
          return products;
        });
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
        .orderBy('createdAt', descending: true)
        .limit(limit + 1) // Fetch one extra to account for filtering
        .snapshots()
        .map((snapshot) {
      List<Product> products = snapshot.docs
          .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((product) => product.id != excludeProductId) // Filter out the current product
          .take(limit) // Take only the number we need
          .toList();
      
      return products;
    });
  }

  // Thêm sản phẩm mới với kiểm duyệt
  Future<String> addProductWithModeration({
    required String title,
    required String description,
    required double price,
    required String category,
    required List<String> images,
    required String condition,
    required String location,
    List<String> tags = const [],
    Map<String, String> specifications = const {},
  }) async {
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      if (user == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }

      // Tạo ID mới cho sản phẩm
      final String productId = _firestore.collection('products').doc().id;
      
      // Lấy thông tin người bán từ profile
      DocumentSnapshot userSnapshot = await _firestore.collection('users').doc(user.uid).get();
      String sellerName = userSnapshot.exists ? userSnapshot.get('displayName') ?? user.displayName ?? 'Người dùng' : user.displayName ?? 'Người dùng';
      String sellerAvatar = userSnapshot.exists ? userSnapshot.get('photoURL') ?? '' : '';
      
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
        location: location,
        tags: tags,
        specifications: specifications,
        status: ProductStatus.pending_review,
      );
      
      // Lưu sản phẩm vào Firestore
      await _firestore.collection('products').doc(productId).set(newProduct.toMap());
      
      // Yêu cầu kiểm duyệt sản phẩm (thông qua Cloud Function hoặc gọi trực tiếp)
      await _requestProductModeration(productId, newProduct);
      
      return productId;
    } catch (e) {
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
    required String location,
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
  Future<void> updateProduct({
    required String productId,
    required String title,
    required String description,
    required double price,
    double? originalPrice,
    required String category,
    required List<String> images,
    required int quantity,
    required String condition,
    required String location,
    List<String> tags = const [],
    Map<String, String> specifications = const {},
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

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

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }
} 