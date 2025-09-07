import 'dart:convert';

class CategoryModel {
  final String categoryId;
  final String categoryName;
  final String categoryImage;
  final String? description;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryModel({
    required this.categoryId,
    required this.categoryName,
    required this.categoryImage,
    this.description,
    this.isAvailable = true,
    required this.createdAt,
    required this.updatedAt,
  });

  // Get products count for this category (helper method)
  Future<int> getProductsCount() async {
    // This will be implemented in the provider
    return 0;
  }

  // Convert CategoryModel to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryImage': categoryImage,
      'description': description,
      'isAvailable': isAvailable,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Create CategoryModel from Map (database retrieval)
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    // Handle timestamp conversion safely
    DateTime parseTimestamp(dynamic value) {
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      } else {
        return DateTime.now();
      }
    }

    return CategoryModel(
      categoryId: map['categoryId']?.toString() ?? '',
      categoryName: map['categoryName']?.toString() ?? '',
      categoryImage: map['categoryImage']?.toString() ?? '',
      description: map['description']?.toString(),
      isAvailable: map['isAvailable'] ?? true,
      createdAt: parseTimestamp(map['createdAt']),
      updatedAt: parseTimestamp(map['updatedAt']),
    );
  }

  // Create CategoryModel from JSON
  factory CategoryModel.fromJson(String source) =>
      CategoryModel.fromMap(json.decode(source));

  // Convert CategoryModel to JSON
  String toJson() => json.encode(toMap());

  // Create a copy of CategoryModel with updated fields
  CategoryModel copyWith({
    String? categoryId,
    String? categoryName,
    String? categoryImage,
    String? description,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryImage: categoryImage ?? this.categoryImage,
      description: description ?? this.description,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel && other.categoryId == categoryId;
  }

  @override
  int get hashCode => categoryId.hashCode;

  @override
  String toString() {
    return 'CategoryModel(categoryId: $categoryId, categoryName: $categoryName, isAvailable: $isAvailable)';
  }
}
