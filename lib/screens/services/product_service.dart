import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uuid/uuid.dart';

import '../constants/env.dart';
import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final cloudinary = CloudinaryPublic(Env.cloudName, Env.uploadPreset);
  final uuid = Uuid();

  // Get Cloudinary image URL
  String getCloudinaryUrl(String publicId) {
    return 'https://res.cloudinary.com/${Env.cloudName}/image/upload/$publicId';
  }

  // Get Cloudinary Management URL (for admin dashboard)
  String getCloudinaryManagementUrl() {
    return 'https://cloudinary.com/console/c-${Env.cloudName}/media_library/folders/products';
  }

  // Cache for search results to improve performance
  final Map<String, List<ProductModel>> _searchCache = {};
  final Duration _cacheDuration = const Duration(minutes: 5);
  DateTime? _lastSearchTime;

  // Upload image to Cloudinary
  Future<String> uploadImageToCloudinary({
    File? imageFile,
    Uint8List? webImage,
  }) async {
    try {
      late CloudinaryResponse response;

      if (kIsWeb && webImage != null) {
        // Handle web platform
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        response = await cloudinary.uploadFile(
          CloudinaryFile.fromBytesData(
            webImage,
            identifier: 'product_$timestamp',
            folder: 'products',
          ),
        );
      } else if (imageFile != null) {
        // Handle other platforms
        response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(imageFile.path, folder: 'products'),
        );
      } else {
        throw Exception('No image provided');
      }

      return response.secureUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Create a new product
  Future<ProductModel> createProduct({
    required String name,
    required String description,
    required double price,
    required String category,
    required int quantity,
    File? imageFile,
    Uint8List? webImage,
  }) async {
    try {
      // Upload image first
      final imageUrl = await uploadImageToCloudinary(
        imageFile: imageFile,
        webImage: webImage,
      );

      // Create product model
      final product = ProductModel(
        productId: uuid.v4(),
        productName: name,
        productDescription: description,
        productPrice: price,
        productImage: imageUrl,
        productCategory: category,
        productQuantity: quantity,
      );

      // Save to Firestore
      await _firestore
          .collection('products')
          .doc(product.productId)
          .set(product.toJson());

      return product;
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  // Get all products
  Stream<List<ProductModel>> getAllProducts() {
    return _firestore
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ProductModel.fromJson(doc.data()))
              .toList();
        });
  }

  // Get products by category
  Stream<List<ProductModel>> getProductsByCategory(String category) {
    return _firestore
        .collection('products')
        .where('productCategory', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ProductModel.fromJson(doc.data()))
              .toList();
        });
  }

  // Update product
  Future<void> updateProduct(
    ProductModel product, {
    File? newImageFile,
    Uint8List? newWebImage,
  }) async {
    try {
      String imageUrl = product.productImage;

      // If new image is provided, upload it
      if (newImageFile != null || newWebImage != null) {
        imageUrl = await uploadImageToCloudinary(
          imageFile: newImageFile,
          webImage: newWebImage,
        );
      }

      final updatedProduct = ProductModel(
        productId: product.productId,
        productName: product.productName,
        productDescription: product.productDescription,
        productPrice: product.productPrice,
        productImage: imageUrl,
        productCategory: product.productCategory,
        productQuantity: product.productQuantity,
      );

      await _firestore
          .collection('products')
          .doc(product.productId)
          .update(updatedProduct.toJson());
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // Search products
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      query = query.toLowerCase();

      // Check cache first
      if (_lastSearchTime != null &&
          DateTime.now().difference(_lastSearchTime!) < _cacheDuration &&
          _searchCache.containsKey(query)) {
        return _searchCache[query]!;
      }

      // Perform Firestore query
      final snapshot = await _firestore
          .collection('products')
          .orderBy('productName')
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .get();

      final results = snapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data()))
          .where(
            (product) =>
                product.productName.toLowerCase().contains(query) ||
                product.productDescription.toLowerCase().contains(query),
          )
          .toList();

      // Update cache
      _searchCache[query] = results;
      _lastSearchTime = DateTime.now();

      return results;
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }
}
