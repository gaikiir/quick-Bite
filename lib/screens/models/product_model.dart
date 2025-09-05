class ProductModel {
  final String productId;
  final String productName;
  final String productDescription;
  final double productPrice;
  final String productImage;
  final String productCategory;
  final int productQuantity;
  final DateTime createdAt;

  ProductModel({
    required this.productId,
    required this.productName,
    required this.productDescription,
    required this.productPrice,
    required this.productImage,
    required this.productCategory,
    required this.productQuantity,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      productDescription: json['productDescription'] ?? '',
      productPrice: (json['productPrice'] ?? 0).toDouble(),
      productImage: json['productImage'] ?? '',
      productCategory: json['productCategory'] ?? '',
      productQuantity: json['productQuantity'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'productDescription': productDescription,
    'productPrice': productPrice,
    'productImage': productImage,
    'productCategory': productCategory,
    'productQuantity': productQuantity,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ProductModel.empty() => ProductModel(
    productId: '',
    productName: '',
    productDescription: '',
    productPrice: 0.0,
    productImage: '',
    productCategory: '',
    productQuantity: 0,
  );

  ProductModel copyWith({
    String? productId,
    String? productName,
    String? productDescription,
    double? productPrice,
    String? productImage,
    String? productCategory,
    int? productQuantity,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productDescription: productDescription ?? this.productDescription,
      productPrice: productPrice ?? this.productPrice,
      productImage: productImage ?? this.productImage,
      productCategory: productCategory ?? this.productCategory,
      productQuantity: productQuantity ?? this.productQuantity,
      createdAt: createdAt,
    );
  }
}
