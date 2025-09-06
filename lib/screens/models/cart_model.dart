class CartModel {
  final String cartId;
  final String productId;
  final String productName;
  final String productImage;
  final double productPrice;
  final int quantity;
  final DateTime addedAt;
  final String? selectedSize;
  final String? selectedColor;
  final String userId; // Added userId field

  CartModel({
    required this.cartId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.productPrice,
    required this.quantity,
    required this.addedAt,
    required this.userId, // Made userId required
    this.selectedSize,
    this.selectedColor,
  });

  // Calculate total price for this cart item
  double get totalPrice => productPrice * quantity;

  // Convert CartModel to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'cartId': cartId,
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'productPrice': productPrice,
      'quantity': quantity,
      'addedAt': addedAt.millisecondsSinceEpoch,
      'selectedSize': selectedSize,
      'selectedColor': selectedColor,
      'userId': userId,
    };
  }

  // Create CartModel from Map (database retrieval)
  factory CartModel.fromMap(Map<String, dynamic> map) {
    return CartModel(
      cartId: map['cartId']?.toString() ?? '',
      productId: map['productId']?.toString() ?? '',
      productName: map['productName']?.toString() ?? '',
      productImage: map['productImage']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      productPrice: (map['productPrice'] ?? 0.0).toDouble(),
      quantity: (map['quantity'] ?? 1).toInt(),
      addedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['addedAt'] ?? 0).toInt(),
      ),
      selectedSize: map['selectedSize']?.toString(),
      selectedColor: map['selectedColor']?.toString(),
    );
  }

  // Create CartModel from JSON
  factory CartModel.fromJson(Map<String, dynamic> json) {
    return CartModel(
      cartId: json['cartId']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      productImage: json['productImage']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      productPrice: (json['productPrice'] ?? 0.0).toDouble(),
      quantity: (json['quantity'] ?? 1).toInt(),
      addedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['addedAt'] ?? 0).toInt(),
      ),
      selectedSize: json['selectedSize']?.toString(),
      selectedColor: json['selectedColor']?.toString(),
    );
  }

  // Convert CartModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'cartId': cartId,
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'productPrice': productPrice,
      'quantity': quantity,
      'addedAt': addedAt.toIso8601String(),
      'selectedSize': selectedSize,
      'selectedColor': selectedColor,
      'userId': userId,
    };
  }

  // Create a copy of CartModel with updated fields
  CartModel copyWith({
    String? cartId,
    String? productId,
    String? productName,
    String? productImage,
    double? productPrice,
    int? quantity,
    DateTime? addedAt,
    String? selectedSize,
    String? selectedColor,
    String? userId,
  }) {
    return CartModel(
      cartId: cartId ?? this.cartId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      productPrice: productPrice ?? this.productPrice,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedColor: selectedColor ?? this.selectedColor,
      userId: userId ?? this.userId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartModel &&
        other.cartId == cartId &&
        other.productId == productId &&
        other.quantity == quantity &&
        other.selectedSize == selectedSize &&
        other.selectedColor == selectedColor;
  }

  @override
  int get hashCode {
    return cartId.hashCode ^
        productId.hashCode ^
        quantity.hashCode ^
        selectedSize.hashCode ^
        selectedColor.hashCode;
  }

  @override
  String toString() {
    return 'CartModel(cartId: $cartId, productId: $productId, productName: $productName, quantity: $quantity, totalPrice: $totalPrice)';
  }
}
