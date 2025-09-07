import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_bite/screens/provider/category_provider.dart';
import 'package:quick_bite/screens/provider/product_provider.dart';
import 'package:quick_bite/screens/user/product_details_screen.dart';
import 'package:quick_bite/screens/widgets/category_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final PageController _pageController = PageController();
  int _currentOfferIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Initialize providers after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final categoryProvider = Provider.of<CategoryProvider>(
          context,
          listen: false,
        );
        final productProvider = Provider.of<ProductProvider>(
          context,
          listen: false,
        );

        // Only initialize if not already initialized
        if (categoryProvider.categories.isEmpty) {
          categoryProvider.initCategoriesStream();
        }
        if (productProvider.products.isEmpty) {
          productProvider.initProductsStream();
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          _buildSliverAppBar(),

          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Welcome Section
                  _buildWelcomeSection(),

                  const SizedBox(height: 32),

                  // Special Offers
                  _buildSpecialOffers(),

                  const SizedBox(height: 32),

                  // Categories Section
                  _buildCategoriesSection(),

                  const SizedBox(height: 32),

                  // Popular Items
                  _buildPopularItems(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
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
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
        ),
        child: FlexibleSpaceBar(
          centerTitle: true,
          title: const Text(
            'Quick Bite',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          background: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
            ),
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Good Morning! 👋',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'What would you like to eat today?',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialOffers() {
    final offers = [
      {
        'title': 'Summer Special',
        'subtitle': '50% OFF',
        'description': 'On all beverages',
        'color': const Color(0xFFFF6B6B),
        'icon': '🍹',
      },
      {
        'title': 'Weekend Deal',
        'subtitle': '30% OFF',
        'description': 'Fast food combo',
        'color': const Color(0xFF4ECDC4),
        'icon': '🍔',
      },
      {
        'title': 'New Customer',
        'subtitle': 'FREE DELIVERY',
        'description': 'On first order',
        'color': const Color(0xFF45B7D1),
        'icon': '🚚',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Special Offers',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A202C),
                ),
              ),
              TextButton(onPressed: () {}, child: const Text('See All')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentOfferIndex = index;
              });
            },
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      offer['color'] as Color,
                      (offer['color'] as Color).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (offer['color'] as Color).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            offer['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            offer['subtitle'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            offer['description'] as String,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          offer['icon'] as String,
                          style: const TextStyle(fontSize: 40),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            offers.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentOfferIndex == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentOfferIndex == index
                    ? const Color(0xFF667EEA)
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A202C),
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/category'),
                    child: const Text('See All'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Categories Grid
        Consumer<CategoryProvider>(
          builder: (context, categoryProvider, child) {
            if (categoryProvider.isLoading &&
                categoryProvider.categories.isEmpty) {
              return _buildCategoriesShimmer();
            }

            if (categoryProvider.error.isNotEmpty) {
              return _buildErrorState(categoryProvider.error);
            }

            final categories = categoryProvider.availableCategories
                .take(8)
                .toList();

            if (categories.isEmpty) {
              return _buildEmptyCategories();
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
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
        ),
      ],
    );
  }

  Widget _buildPopularItems() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Popular Items',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A202C),
                    ),
                  ),
                  TextButton(onPressed: () {}, child: const Text('See All')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            productProvider.isLoading && productProvider.products.isEmpty
                ? SizedBox(
                    height: 240,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: 3,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 160,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                        );
                      },
                    ),
                  )
                : productProvider.error.isNotEmpty
                ? SizedBox(
                    height: 240,
                    child: Center(
                      child: Text(
                        'Error loading popular items',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ),
                  )
                : productProvider.products.isEmpty
                ? SizedBox(
                    height: 240,
                    child: Center(
                      child: Text(
                        'No popular items available',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ),
                  )
                : SizedBox(
                    height: 240,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: productProvider.products.length > 3
                          ? 3
                          : productProvider.products.length,
                      itemBuilder: (context, index) {
                        final product = productProvider.products[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              ProductDetailsScreen.routeName,
                              arguments: product,
                            );
                          },
                          child: Container(
                            width: 160,
                            margin: const EdgeInsets.only(right: 16),
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
                                Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color(
                                          0xFF667EEA,
                                        ).withOpacity(0.1),
                                        const Color(
                                          0xFF764BA2,
                                        ).withOpacity(0.1),
                                      ],
                                    ),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  child: product.productImage.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(20),
                                              ),
                                          child: Image.network(
                                            product.productImage,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return const Center(
                                                    child: Icon(
                                                      Icons.fastfood,
                                                      size: 48,
                                                      color: Color(0xFF667EEA),
                                                    ),
                                                  );
                                                },
                                          ),
                                        )
                                      : const Center(
                                          child: Icon(
                                            Icons.fastfood,
                                            size: 48,
                                            color: Color(0xFF667EEA),
                                          ),
                                        ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            size: 14,
                                            color: Colors.amber,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '4.5',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.access_time,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '15 min',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '\$${product.productPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF667EEA),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        );
      },
    );
  }

  Widget _buildCategoriesShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600], size: 48),
            const SizedBox(height: 12),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adding some sample data using the buttons above',
              style: TextStyle(fontSize: 14, color: Colors.red[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCategories() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(32),
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
                size: 48,
                color: Color(0xFF667EEA),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No categories yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A202C),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use the Firebase console or admin panel to add categories',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
