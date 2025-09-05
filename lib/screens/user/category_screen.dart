import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'name': 'Vegetables', 'icon': '🥕', 'color': const Color(0xFF4CAF50)},
      {'name': 'Fruits', 'icon': '🍇', 'color': const Color(0xFF9C27B0)},
      {'name': 'Milk & Eggs', 'icon': '🥛', 'color': const Color(0xFF2196F3)},
      {'name': 'Drinks', 'icon': '🍊', 'color': const Color(0xFFFF9800)},
      {'name': 'Cakes', 'icon': '🧁', 'color': const Color(0xFFE91E63)},
      {'name': 'Ice-Cream', 'icon': '🍦', 'color': const Color(0xFF00BCD4)},
      {'name': 'Bakery', 'icon': '🥖', 'color': const Color(0xFFFF5722)},
      {'name': 'Snacks', 'icon': '🍿', 'color': const Color(0xFFFF5722)},
      {'name': 'Grain', 'icon': '🌾', 'color': const Color(0xFF795548)},
      {'name': 'Cheese', 'icon': '🧀', 'color': const Color(0xFFFFC107)},
      {'name': 'Oil', 'icon': '🫒', 'color': const Color(0xFF4CAF50)},
      {'name': 'Biscuit', 'icon': '🍪', 'color': const Color(0xFFFF9800)},
      {'name': 'Household', 'icon': '🧽', 'color': const Color(0xFF607D8B)},
      {'name': 'Pet Food', 'icon': '🐕', 'color': const Color(0xFF3F51B5)},
      {'name': 'Skin Care', 'icon': '🧴', 'color': const Color(0xFFE91E63)},
      {'name': 'Soap', 'icon': '🧼', 'color': const Color(0xFF00BCD4)},
      {'name': 'Coffee', 'icon': '☕', 'color': const Color(0xFF795548)},
      {'name': 'Dry Fruits', 'icon': '🥜', 'color': const Color(0xFF4CAF50)},
      {'name': 'Sugar', 'icon': '🍯', 'color': const Color(0xFFFFC107)},
      {'name': 'Garden', 'icon': '🌱', 'color': const Color(0xFF4CAF50)},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Category',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 20,
            childAspectRatio: 0.85,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return GestureDetector(
              onTap: () {
                // Handle category selection
                _onCategoryTap(context, category['name'] as String);
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: (category['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (category['color'] as Color).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        category['icon'] as String,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category['name'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _onCategoryTap(BuildContext context, String categoryName) {
    // Show snackbar or navigate to category products
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected: $categoryName'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    // TODO: Navigate to products for this category
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => CategoryProductsScreen(category: categoryName),
    //   ),
    // );
  }
}
