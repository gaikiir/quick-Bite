import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_bite/screens/models/categoryModel.dart';
import 'package:quick_bite/screens/provider/category_provider.dart';

class CategoryManagementScreen extends StatefulWidget {
  static const routeName = '/category-management';

  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final _nameController = TextEditingController();
  final _imageController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _imageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddCategoryDialog(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'sample_data') {
                _initializeSampleData();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sample_data',
                child: Row(
                  children: [
                    Icon(Icons.data_object),
                    SizedBox(width: 8),
                    Text('Add Sample Data'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, categoryProvider, child) {
          if (categoryProvider.isLoading &&
              categoryProvider.categories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (categoryProvider.error.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${categoryProvider.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => categoryProvider.initCategoriesStream(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final categories = categoryProvider.categories;

          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text('No categories yet'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showAddCategoryDialog(),
                    child: const Text('Add First Category'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryCard(category);
            },
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey[200],
          backgroundImage: NetworkImage(category.categoryImage),
          onBackgroundImageError: (_, __) {},
          child: category.categoryImage.isEmpty
              ? const Icon(Icons.fastfood)
              : null,
        ),
        title: Text(
          category.categoryName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (category.description != null) Text(category.description!),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  category.isAvailable ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: category.isAvailable ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  category.isAvailable ? 'Available' : 'Unavailable',
                  style: TextStyle(
                    color: category.isAvailable ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditCategoryDialog(category);
                break;
              case 'toggle':
                _toggleCategoryAvailability(category);
                break;
              case 'delete':
                _showDeleteConfirmationDialog(category);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [Icon(Icons.edit), SizedBox(width: 8), Text('Edit')],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    category.isAvailable
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  const SizedBox(width: 8),
                  Text(category.isAvailable ? 'Disable' : 'Enable'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    _clearForm();
    _showCategoryDialog('Add Category', null);
  }

  void _showEditCategoryDialog(CategoryModel category) {
    _nameController.text = category.categoryName;
    _imageController.text = category.categoryImage;
    _descriptionController.text = category.description ?? '';
    _showCategoryDialog('Edit Category', category);
  }

  void _showCategoryDialog(String title, CategoryModel? category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a category name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _imageController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    border: OutlineInputBorder(),
                    hintText: 'https://example.com/image.jpg',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an image URL';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _saveCategory(category),
            child: Text(category == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _saveCategory(CategoryModel? existingCategory) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );

      if (existingCategory == null) {
        // Create new category
        await categoryProvider.createCategory(
          categoryName: _nameController.text.trim(),
          categoryImage: _imageController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
      } else {
        // Update existing category
        final updatedCategory = existingCategory.copyWith(
          categoryName: _nameController.text.trim(),
          categoryImage: _imageController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
        await categoryProvider.updateCategory(updatedCategory);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existingCategory == null
                  ? 'Category added successfully'
                  : 'Category updated successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _toggleCategoryAvailability(CategoryModel category) async {
    try {
      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );
      await categoryProvider.toggleCategoryAvailability(category.categoryId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${category.categoryName} ${category.isAvailable ? 'disabled' : 'enabled'}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showDeleteConfirmationDialog(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${category.categoryName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _deleteCategory(category),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(CategoryModel category) async {
    try {
      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );
      await categoryProvider.deleteCategory(category.categoryId);

      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${category.categoryName} deleted successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _initializeSampleData() async {
    try {
      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );
      await categoryProvider.initializeSampleCategories();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sample categories added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _imageController.clear();
    _descriptionController.clear();
  }
}
