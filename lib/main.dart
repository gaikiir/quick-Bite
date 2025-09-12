// Core Flutter and Firebase imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Firebase configuration
import 'package:quick_bite/firebase_options.dart';
// Admin screens
import 'package:quick_bite/screens/admin/add_product_screen.dart';
import 'package:quick_bite/screens/admin/admin_root.dart';
import 'package:quick_bite/screens/admin/admin_setup_screen.dart';
import 'package:quick_bite/screens/admin/category_management_screen.dart';
import 'package:quick_bite/screens/admin/orders.dart';
import 'package:quick_bite/screens/admin/product_list_screen.dart';
import 'package:quick_bite/screens/admin/users_screen.dart';
// Authentication screens
import 'package:quick_bite/screens/auth/forgot_password.dart';
import 'package:quick_bite/screens/auth/login.dart';
import 'package:quick_bite/screens/auth/register.dart';
// Constants and themes
import 'package:quick_bite/screens/constants/theme_data.dart';
// Models
import 'package:quick_bite/screens/models/categoryModel.dart';
import 'package:quick_bite/screens/models/order_model.dart';
// Providers
import 'package:quick_bite/screens/provider/cart_provider.dart';
import 'package:quick_bite/screens/provider/category_provider.dart';
import 'package:quick_bite/screens/provider/order_provider.dart';
import 'package:quick_bite/screens/provider/product_provider.dart';
import 'package:quick_bite/screens/provider/theme_provider.dart';
import 'package:quick_bite/screens/provider/wishlist_provider.dart';
// User screens
import 'package:quick_bite/screens/user/cart_screen.dart';
import 'package:quick_bite/screens/user/category_products_screen.dart';
import 'package:quick_bite/screens/user/category_screen.dart';
import 'package:quick_bite/screens/user/checkout_screen.dart';
import 'package:quick_bite/screens/user/order_success_screen.dart';
import 'package:quick_bite/screens/user/payment_screen.dart';
import 'package:quick_bite/screens/user/product_details_screen.dart';
import 'package:quick_bite/screens/user/products_screen.dart';
import 'package:quick_bite/screens/user/user_root.dart';
import 'package:quick_bite/screens/user/wishlist_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Check if user is logged in
  final user = FirebaseAuth.instance.currentUser;
  debugPrint('User logged in: ${user?.uid ?? 'No user'}');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Routes configuration method
  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      // Authentication routes
      LoginScreen.routeName: (context) => const LoginScreen(),
      Register.routeName: (context) => const Register(),
      ForgotPassword.routeName: (context) => const ForgotPassword(),

      // Admin routes
      AdminRootScreen.routeName: (context) => const AdminRootScreen(),
      AdminSetupScreen.routeName: (context) => const AdminSetupScreen(),
      UsersScreen.routeName: (context) => const UsersScreen(),
      ProductListScreen.routeName: (context) => const ProductListScreen(),
      OrdersList.routeName: (context) => const OrdersList(),
      AddProductScreen.routeName: (context) => const AddProductScreen(),
      CategoryManagementScreen.routeName: (context) =>
          const CategoryManagementScreen(),

      // User routes
      UserRoot.routeName: (context) => const UserRoot(),
      CartScreen.routeName: (context) => const CartScreen(),
      ProductsScreen.routeName: (context) => const ProductsScreen(),
      WishlistScreen.routeName: (context) => const WishlistScreen(),
      '/category': (context) => const CategoryScreen(),
      '/checkout': (context) => const CheckoutScreen(),
      '/payment': (context) {
        final order = ModalRoute.of(context)?.settings.arguments as OrderModel?;
        if (order != null) {
          return PaymentScreen(order: order);
        }
        return const Scaffold(
          body: Center(child: Text('Invalid payment request')),
        );
      },
      '/order-success': (context) {
        final order = ModalRoute.of(context)?.settings.arguments as OrderModel?;
        if (order != null) {
          return OrderSuccessScreen(order: order);
        }
        return const Scaffold(
          body: Center(child: Text('Invalid order confirmation')),
        );
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => ProductProvider()..initProductsStream(),
        ),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, child) {
          return MaterialApp(
            title: 'Quick Bite',
            debugShowCheckedModeBanner: false,
            theme: Styles.themeData(
              isDarkTheme: theme.isDarkTheme,
              context: context,
            ),
            initialRoute: FirebaseAuth.instance.currentUser == null
                ? LoginScreen.routeName
                : UserRoot.routeName,
            // Route configuration
            routes: _buildRoutes(),
            onGenerateRoute: (settings) {
              // Handle product details route with arguments
              if (settings.name == ProductDetailsScreen.routeName) {
                return MaterialPageRoute(
                  builder: (context) => const ProductDetailsScreen(),
                  settings: settings,
                );
              }
              // Handle category products route with arguments
              if (settings.name == CategoryProductsScreen.routeName) {
                final category = settings.arguments as CategoryModel?;
                if (category != null) {
                  return MaterialPageRoute(
                    builder: (context) =>
                        CategoryProductsScreen(category: category),
                    settings: settings,
                  );
                }
              }

              return null;
            },
          );
        },
      ),
    );
  }
}
