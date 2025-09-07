import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:provider/provider.dart';
import 'package:quick_bite/screens/models/categoryModel.dart';
import 'package:quick_bite/screens/models/product_model.dart';
import 'package:quick_bite/screens/provider/category_provider.dart';

class CategoryProductsScreen extends StatefulWidget {
  static const routeName = '/category-products';
  final CategoryModel category;

  const CategoryProductsScreen({super.key, required this.category});

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen>
    with TickerProviderStateMixin {
  String _sortBy = 'name';
  bool _isGridView = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late CategoryProvider _categoryProvider;

  @override
  void initState() {
    super.initState();
    _categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _fetchProductsForCategory();
  }

  @override
  void dispose() {
    // Stop listening to category stream when leaving this screen
    _categoryProvider.clearCategoryProducts();
    _animationController.dispose();
    super.dispose();
  }

  void _fetchProductsForCategory() {
    if (!mounted) return;

    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );
    // Always subscribe for live updates
    categoryProvider.fetchProductsForCategory(widget.category.categoryName);
  }

  void _refreshProducts() {
    if (!mounted) return;

    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );
    categoryProvider.refreshProductsForCategory(widget.category.categoryName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshProducts();
        },
        color: const Color(0xFF667EEA),
        child: CustomScrollView(
          slivers: [
            // Modern App Bar
            _buildSliverAppBar(),

            // Content
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Category Header
                    _buildCategoryHeader(),

                    // Filter and Sort Bar
                    _buildFilterSortBar(),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Products Grid/List
            _buildProductsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A202C)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              _isGridView ? Icons.list_rounded : Icons.grid_view_rounded,
              color: const Color(0xFF1A202C),
            ),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
        ),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF667EEA).withOpacity(0.9),
              const Color(0xFF764BA2).withOpacity(0.9),
            ],
          ),
        ),
        child: FlexibleSpaceBar(
          centerTitle: true,
          title: Text(
            widget.category.categoryName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          // Category Image
          Container(
            width: 60,
            height: 60,
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
                widget.category.categoryImage,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.fastfood_rounded,
                  color: Color(0xFF667EEA),
                  size: 32,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Category Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.category.categoryName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A202C),
                  ),
                ),
                const SizedBox(height: 4),
                if (widget.category.description != null)
                  Text(
                    widget.category.description!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                Consumer<CategoryProvider>(
                  builder: (context, provider, child) {
                    return Row(
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${provider.categoryProducts.length} items available',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSortBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Sort Dropdown
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _sortBy,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'name',
                      child: Text('Sort by Name'),
                    ),
                    DropdownMenuItem(
                      value: 'price_low',
                      child: Text('Price: Low to High'),
                    ),
                    DropdownMenuItem(
                      value: 'price_high',
                      child: Text('Price: High to Low'),
                    ),
                    DropdownMenuItem(
                      value: 'newest',
                      child: Text('Newest First'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _sortBy = value);
                    }
                  },
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Filter Button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF667EEA).withOpacity(0.1),
                  const Color(0xFF764BA2).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF667EEA).withOpacity(0.3),
              ),
            ),
            child: const Icon(
              IconlyLight.filter,
              color: Color(0xFF667EEA),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        if (categoryProvider.isLoadingProducts) {
          return SliverToBoxAdapter(child: _buildLoadingView());
        }

        if (categoryProvider.productsError.isNotEmpty) {
          return SliverToBoxAdapter(
            child: _buildErrorView(categoryProvider.productsError),
          );
        }

        final products = _getSortedProducts(categoryProvider.categoryProducts);

        if (products.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmptyView());
        }

        return _isGridView
            ? _buildGridView(products)
            : _buildListView(products);
      },
    );
  }

  Widget _buildGridView(List<ProductModel> products) {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final product = products[index];
          return _buildProductCard(product);
        }, childCount: products.length),
      ),
    );
  }

  Widget _buildListView(List<ProductModel> products) {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final product = products[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: _buildProductListTile(product),
          );
        }, childCount: products.length),
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/product-details', arguments: product);
      },
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF667EEA).withOpacity(0.1),
                      const Color(0xFF764BA2).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child: Image.network(
                          product.productImage,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.fastfood_rounded,
                                size: 48,
                                color: Color(0xFF667EEA),
                              ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.favorite_border,
                          size: 16,
                          color: Color(0xFF667EEA),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Product Info
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A202C),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.productDescription,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${product.productPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF667EEA),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductListTile(ProductModel product) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/product-details', arguments: product);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF667EEA).withOpacity(0.1),
                    const Color(0xFF764BA2).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  product.productImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.fastfood_rounded,
                    color: Color(0xFF667EEA),
                    size: 32,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A202C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.productDescription,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${product.productPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF667EEA),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Add',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading delicious items...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF667EEA),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 48),
          const SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(fontSize: 14, color: Colors.red[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchProductsForCategory,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF667EEA).withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Color(0xFF667EEA),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No items found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We couldn\'t find any items in this category yet.\nCheck back later for delicious options!',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Browse Other Categories'),
          ),
        ],
      ),
    );
  }

  List<ProductModel> _getSortedProducts(List<ProductModel> products) {
    final sortedProducts = List<ProductModel>.from(products);

    switch (_sortBy) {
      case 'name':
        sortedProducts.sort((a, b) => a.productName.compareTo(b.productName));
        break;
      case 'price_low':
        sortedProducts.sort((a, b) => a.productPrice.compareTo(b.productPrice));
        break;
      case 'price_high':
        sortedProducts.sort((a, b) => b.productPrice.compareTo(a.productPrice));
        break;
      case 'newest':
        sortedProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return sortedProducts;
  }
}
