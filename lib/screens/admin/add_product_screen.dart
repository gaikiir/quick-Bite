import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../provider/product_provider.dart';
import '../widgets/auth/cross_platform_image.dart';

class AddProductScreen extends StatefulWidget {
  final ProductModel? product;

  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();

  File? _imageFile;
  Uint8List? _webImage;
  bool _isLoading = false;
  final _categoryController = TextEditingController();

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        if (kIsWeb) {
          // Handle web platform
          final bytes = await image.readAsBytes();
          setState(() {
            _webImage = bytes;
            _imageFile = null;
          });
        } else {
          // Handle other platforms
          setState(() {
            _imageFile = File(image.path);
            _webImage = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_imageFile == null && _webImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an image')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      if (widget.product != null) {
        // Update existing product
        final updatedProduct = ProductModel(
          productId: widget.product!.productId,
          productName: _nameController.text.trim(),
          productDescription: _descriptionController.text.trim(),
          productPrice: double.parse(_priceController.text),
          productCategory: _categoryController.text.trim(),
          productQuantity: int.parse(_quantityController.text),
          productImage: widget.product!.productImage,
        );
        await provider.updateProduct(
          updatedProduct,
          newImageFile: _imageFile,
          newWebImage: _webImage,
        );
      } else {
        // Create new product
        await provider.createProduct(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text),
          category: _categoryController.text.trim(),
          quantity: int.parse(_quantityController.text),
          imageFile: _imageFile,
          webImage: _webImage,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product != null
                  ? 'Product updated successfully'
                  : 'Product created successfully',
            ),
          ),
        );
        Navigator.pop(context); // Go back to previous screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating product: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.productName;
      _descriptionController.text = widget.product!.productDescription;
      _priceController.text = widget.product!.productPrice.toString();
      _categoryController.text = widget.product!.productCategory;
      _quantityController.text = widget.product!.productQuantity.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product != null ? 'Edit Product' : 'Add New Product',
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [theme.primaryColor.withOpacity(0.05), Colors.white],
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Image Section
                    Container(
                      width: double.infinity,
                      height: 250,
                      margin: const EdgeInsets.all(16),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: InkWell(
                          onTap: _pickImage,
                          borderRadius: BorderRadius.circular(15),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: CrossPlatformImage(
                                  imageFile: _imageFile,
                                  webImage: _webImage,
                                  height: 250,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              if (_imageFile == null && _webImage == null)
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 40,
                                      color: theme.primaryColor,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Add Product Image',
                                      style: TextStyle(
                                        color: theme.primaryColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Form Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Product Details Card
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Product Details',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      controller: _nameController,
                                      label: 'Product Name',
                                      prefixIcon: Icons.fastfood,
                                      validator: (value) {
                                        if (value?.isEmpty ?? true) {
                                          return 'Please enter product name';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      controller: _descriptionController,
                                      label: 'Description',
                                      prefixIcon: Icons.description,
                                      maxLines: 3,
                                      validator: (value) {
                                        if (value?.isEmpty ?? true) {
                                          return 'Please enter description';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Pricing and Inventory Card
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pricing & Inventory',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildTextField(
                                            controller: _priceController,
                                            label: 'Price',
                                            prefixIcon: Icons.attach_money,
                                            keyboardType: TextInputType.number,
                                            validator: (value) {
                                              if (value?.isEmpty ?? true) {
                                                return 'Enter price';
                                              }
                                              if (double.tryParse(value!) ==
                                                  null) {
                                                return 'Invalid price';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildTextField(
                                            controller: _quantityController,
                                            label: 'Quantity',
                                            prefixIcon: Icons.inventory,
                                            keyboardType: TextInputType.number,
                                            validator: (value) {
                                              if (value?.isEmpty ?? true) {
                                                return 'Enter quantity';
                                              }
                                              if (int.tryParse(value!) ==
                                                  null) {
                                                return 'Invalid quantity';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      controller: _categoryController,
                                      label: 'Category',
                                      prefixIcon: Icons.category,
                                      validator: (value) {
                                        if (value?.isEmpty ?? true) {
                                          return 'Please enter category';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Submit Button
                            ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: Text(
                                widget.product != null
                                    ? 'Update Product'
                                    : 'Create Product',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    int? maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(prefixIcon),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}
