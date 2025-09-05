import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:provider/provider.dart';
import 'package:quick_bite/screens/provider/cart_provider.dart';
import 'package:quick_bite/screens/provider/product_provider.dart';
import 'package:quick_bite/screens/user/cart_screen.dart';
import 'package:quick_bite/screens/user/category_screen.dart';
import 'package:quick_bite/screens/user/home_screen.dart';
import 'package:quick_bite/screens/user/products_screen.dart';

class UserRoot extends StatefulWidget {
  /// Define route for the page
  static const String routeName = '/UserRoot';
  const UserRoot({super.key});

  @override
  State<UserRoot> createState() => _UserRootState();
}

class _UserRootState extends State<UserRoot> {
  late final List<Widget> _screens;

  /// Track the currently selected index
  int _currentIndex = 0;

  /// Page controller for navigation
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const CategoryScreen(),
      const ProductsScreen(),
      const CartScreen(),
      Container(
        child: const Center(
          child: Text('Profile Screen - Coming Soon'),
        ),
      ),
    ];
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    // IMPORTANT: Dispose the controller to prevent memory leaks
    _pageController.dispose();
    super.dispose();
  }

  void _onDestinationSelected(int index) {
    // Only update if the index has changed
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
      _pageController.jumpToPage(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: _pageController,
        children: _screens,
      ),
      bottomNavigationBar: Consumer2<ProductProvider, CartProvider>(
        builder: (context, productProvider, cartProvider, child) {
          return NavigationBar(
            selectedIndex: _currentIndex,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            onDestinationSelected: _onDestinationSelected,
            destinations: _buildNavBarItems(cartProvider.cartCount),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            animationDuration: const Duration(milliseconds: 200),
          );
        },
      ),
    );
  }
}

List<NavigationDestination> _buildNavBarItems(int cartCount) {
  return [
    const NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Home',
      tooltip: 'Home',
    ),
    const NavigationDestination(
      icon: Icon(IconlyLight.category),
      selectedIcon: Icon(IconlyLight.ticketStar),
      label: 'Category',
      tooltip: 'Category',
    ),
    const NavigationDestination(
      icon: Icon(Icons.shopping_bag_outlined),
      selectedIcon: Icon(Icons.shopping_bag_outlined),
      label: 'Products',
      tooltip: 'products',
    ),
    NavigationDestination(
      icon: Badge(
        label: cartCount > 0 ? Text('$cartCount') : null,
        child: const Icon(Icons.shopping_cart),
      ),
      selectedIcon: Badge(
        label: cartCount > 0 ? Text('$cartCount') : null,
        child: const Icon(Icons.shopping_cart),
      ),
      label: 'Cart',
      tooltip: 'cart',
    ),
    const NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profile',
      tooltip: 'User Profile',
    ),
  ];
}
