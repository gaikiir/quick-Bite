import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_bite/firebase_options.dart';
import 'package:quick_bite/screens/admin/admin_root.dart';
import 'package:quick_bite/screens/admin/orders.dart';
import 'package:quick_bite/screens/admin/product_list_screen.dart';
import 'package:quick_bite/screens/admin/users_screen.dart';
import 'package:quick_bite/screens/auth/forgot_password.dart';
import 'package:quick_bite/screens/auth/login.dart';
import 'package:quick_bite/screens/auth/register.dart';
import 'package:quick_bite/screens/constants/theme_data.dart';
import 'package:quick_bite/screens/provider/product_provider.dart';
import 'package:quick_bite/screens/provider/theme_provider.dart';
import 'package:quick_bite/screens/user/cart_screen.dart';
import 'package:quick_bite/screens/user/user_root.dart';
import 'package:quick_bite/screens/user/userdarshboar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => ProductProvider()..initProductsStream(),
        ),
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
            home: const LoginScreen(),
            routes: {
              LoginScreen.routeName: (context) => const LoginScreen(),
              Register.routeName: (context) => const Register(),
              ForgotPassword.routeName: (context) => const ForgotPassword(),
              AdminRootScreen.routeName: (context) => const AdminRootScreen(),
              UserRoot.routeName: (context) => const UserRoot(),
              UsersScreen.routeName: (context) => const UsersScreen(),
              ProductListScreen.routeName: (context) =>
                  const ProductListScreen(),
              OrdersList.routeName: (context) => const OrdersList(),
              CartScreen.routeName: (context) => const CartScreen(),
              Userdarshboar.routeName: (context) => const Userdarshboar(),
            },
          );
        },
      ),
    );
  }
}
