class WishlistModel {
  final String wishlistId;
  final String productId;
  final String productName;
  final String productImage;
  final double productPrice;
  final DateTime addedAt;
  final String? category;
  final bool isAvailable;

  WishlistModel({
    required this.wishlistId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.productPrice,
    required this.addedAt,
    this.category,
    this.isAvailable = true,
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
    };
  }

  // Create WishlistModel from Map (database retrieval)
  factory WishlistModel.fromMap(Map<String, dynamic> map) {
    return WishlistModel(
      wishlistId: map['wishlistId'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImage: map['productImage'] ?? '',
      productPrice: (map['productPrice'] ?? 0.0).toDouble(),
      addedAt: DateTime.fromMillisecondsSinceEpoch(map['addedAt'] ?? 0),
      category: map['category'],
      isAvailable: map['isAvailable'] ?? true,
    );
  }

  // Create WishlistModel from JSON
  factory WishlistModel.fromJson(Map<String, dynamic> json) {
    return WishlistModel(
      wishlistId: json['wishlistId'] ?? '',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      productImage: json['productImage'] ?? '',
      productPrice: (json['productPrice'] ?? 0.0).toDouble(),
      addedAt: DateTime.parse(
        json['addedAt'] ?? DateTime.now().toIso8601String(),
      ),
      category: json['category'],
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  // Convert WishlistModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'wishlistId': wishlistId,
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'productPrice': productPrice,
      'addedAt': addedAt.toIso8601String(),
      'category': category,
      'isAvailable': isAvailable,
    };
  }

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
