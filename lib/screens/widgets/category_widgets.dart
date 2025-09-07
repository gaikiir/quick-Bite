import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_bite/screens/models/categoryModel.dart';
import 'package:quick_bite/screens/provider/category_provider.dart';

class ModernCategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const ModernCategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Category Image Container
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF667EEA).withOpacity(0.2),
                    const Color(0xFF764BA2).withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  category.categoryImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF667EEA).withOpacity(0.3),
                          const Color(0xFF764BA2).withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.fastfood_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Category Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                category.categoryName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A202C),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryGrid extends StatelessWidget {
  final bool showAll;
  final int? maxItems;
  final EdgeInsetsGeometry? padding;

  const CategoryGrid({
    super.key,
    this.showAll = true,
    this.maxItems,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        if (categoryProvider.isLoading && categoryProvider.categories.isEmpty) {
          return _buildLoadingGrid();
        }

        if (categoryProvider.error.isNotEmpty) {
          return _buildErrorWidget(categoryProvider.error);
        }

        final categories = showAll
            ? categoryProvider.availableCategories
            : categoryProvider.availableCategories.take(maxItems ?? 8).toList();

        if (categories.isEmpty) {
          return _buildEmptyWidget();
        }

        return Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return ModernCategoryCard(
                category: category,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/category-products',
                    arguments: category,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingGrid() {
    return Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 48),
          const SizedBox(height: 12),
          Text(
            'Failed to load categories',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your internet connection and try again',
            style: TextStyle(fontSize: 14, color: Colors.red[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF667EEA).withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.restaurant_menu,
              size: 48,
              color: Color(0xFF667EEA),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No categories available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Categories will appear here once they are added',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class CategoryList extends StatelessWidget {
  final bool horizontal;
  final double? height;

  const CategoryList({super.key, this.horizontal = true, this.height});

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        if (categoryProvider.isLoading && categoryProvider.categories.isEmpty) {
          return _buildLoadingList();
        }

        if (categoryProvider.error.isNotEmpty) {
          return _buildErrorWidget(categoryProvider.error);
        }

        if (categoryProvider.availableCategories.isEmpty) {
          return _buildEmptyWidget();
        }

        return SizedBox(
          height: horizontal ? (height ?? 100) : null,
          child: ListView.builder(
            scrollDirection: horizontal ? Axis.horizontal : Axis.vertical,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categoryProvider.availableCategories.length,
            itemBuilder: (context, index) {
              final category = categoryProvider.availableCategories[index];
              return Container(
                width: horizontal ? 80 : null,
                margin: horizontal
                    ? const EdgeInsets.only(right: 12)
                    : const EdgeInsets.only(bottom: 12),
                child: ModernCategoryCard(
                  category: category,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/category-products',
                      arguments: category,
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingList() {
    return SizedBox(
      height: horizontal ? (height ?? 100) : 200,
      child: ListView.builder(
        scrollDirection: horizontal ? Axis.horizontal : Axis.vertical,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: horizontal ? 80 : null,
            height: horizontal ? null : 80,
            margin: horizontal
                ? const EdgeInsets.only(right: 12)
                : const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      height: horizontal ? (height ?? 100) : 120,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red[600], size: 24),
            const SizedBox(height: 8),
            Text(
              'Error loading categories',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      height: horizontal ? (height ?? 100) : 120,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF667EEA).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu, size: 24, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'No categories',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
