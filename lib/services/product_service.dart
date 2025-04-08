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

  // Search products
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
    return _firestore
        .collection('products')
        .where('category', isEqualTo: category)
        .where('isSold', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromMap(doc.data(), doc.id)).toList());
  }
} 