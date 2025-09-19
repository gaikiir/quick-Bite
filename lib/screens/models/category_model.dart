class CategoryModel {
  final String categoryId;
  final String categoryName;
  final String categoryDescription;
  final String categoryImage;
  final bool isAvailable;
  final DateTime createdAt;

  CategoryModel({
    required this.categoryId,
    required this.categoryName,
    required this.categoryDescription,
    required this.categoryImage,
    required this.isAvailable,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    // Validate required fields
    if (json['categoryId'] == null || json['categoryId'].toString().isEmpty) {
      throw FormatException(
        'Category document missing required field: categoryId',
      );
    }
    if (json['categoryName'] == null ||
        json['categoryName'].toString().isEmpty) {
      throw FormatException(
        'Category document missing required field: categoryName',
      );
    }

    DateTime? parsedDate;
    try {
      if (json['createdAt'] != null) {
        final dateStr = json['createdAt'].toString();
        parsedDate = DateTime.parse(dateStr);
      }
    } catch (e) {
      // If date parsing fails, use current time
      parsedDate = DateTime.now();
    }

    return CategoryModel(
      categoryId: json['categoryId']?.toString() ?? '',
      categoryName: json['categoryName']?.toString() ?? '',
      categoryDescription: json['categoryDescription']?.toString() ?? '',
      categoryImage: json['categoryImage']?.toString() ?? '',
      isAvailable: json['isAvailable'] ?? true,
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'categoryId': categoryId,
    'categoryName': categoryName,
    'categoryDescription': categoryDescription,
    'categoryImage': categoryImage,
    'isAvailable': isAvailable,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CategoryModel.empty() => CategoryModel(
    categoryId: '',
    categoryName: '',
    categoryDescription: '',
    categoryImage: '',
    isAvailable: true,
  );

  CategoryModel copyWith({
    String? categoryId,
    String? categoryName,
    String? categoryDescription,
    String? categoryImage,
    bool? isAvailable,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryDescription: categoryDescription ?? this.categoryDescription,
      categoryImage: categoryImage ?? this.categoryImage,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
