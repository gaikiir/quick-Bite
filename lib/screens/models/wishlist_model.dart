import 'dart:convert';

class WishlistModel {
  final String wishlistId;
  final String productId;
  final String productName;
  final String productImage;
  final double productPrice;
  final DateTime addedAt;
  final String? category;
  final bool isAvailable;
  final String userId;

  WishlistModel({
    required this.wishlistId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.productPrice,
    required this.addedAt,
    this.category,
    this.isAvailable = true,
    required this.userId,
  });

  // Convert WishlistModel to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'wishlistId': wishlistId,
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'productPrice': productPrice,
      'addedAt': addedAt.millisecondsSinceEpoch,
      'category': category,
      'isAvailable': isAvailable,
      'userId': userId,
    };
  }

  // Create WishlistModel from Map (database retrieval)
  factory WishlistModel.fromMap(Map<String, dynamic> map) {
    // Handle addedAt conversion safely
    DateTime parseAddedAt(dynamic value) {
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      } else {
        return DateTime.now();
      }
    }

    return WishlistModel(
      wishlistId: map['wishlistId']?.toString() ?? '',
      productId: map['productId']?.toString() ?? '',
      productName: map['productName']?.toString() ?? '',
      productImage: map['productImage']?.toString() ?? '',
      productPrice: (map['productPrice'] ?? 0.0).toDouble(),
      addedAt: parseAddedAt(map['addedAt']),
      category: map['category']?.toString(),
      isAvailable: map['isAvailable'] ?? true,
      userId: map['userId']?.toString() ?? '',
    );
  }

  // Create WishlistModel from JSON
  factory WishlistModel.fromJson(String source) =>
      WishlistModel.fromMap(json.decode(source));

  // Convert WishlistModel to JSON
  String toJson() => json.encode(toMap());

  // Create a copy of WishlistModel with updated fields
  WishlistModel copyWith({
    String? wishlistId,
    String? productId,
    String? productName,
    String? productImage,
    double? productPrice,
    DateTime? addedAt,
    String? category,
    bool? isAvailable,
    String? userId,
  }) {
    return WishlistModel(
      wishlistId: wishlistId ?? this.wishlistId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      productPrice: productPrice ?? this.productPrice,
      addedAt: addedAt ?? this.addedAt,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      userId: userId ?? this.userId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WishlistModel &&
        other.wishlistId == wishlistId &&
        other.productId == productId;
  }

  @override
  int get hashCode {
    return wishlistId.hashCode ^ productId.hashCode;
  }

  @override
  String toString() {
    return 'WishlistModel(wishlistId: $wishlistId, productId: $productId, productName: $productName, price: \$$productPrice)';
  }
}
