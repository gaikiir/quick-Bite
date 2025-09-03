import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_bite/firebase_options.dart';
import 'package:quick_bite/screens/admin/admin_root.dart';
import 'package:quick_bite/screens/admin/admindashboard.dart';
import 'package:quick_bite/screens/admin/orders.dart';
import 'package:quick_bite/screens/auth/login.dart';
import 'package:quick_bite/screens/auth/register.dart';
import 'package:quick_bite/screens/constants/theme_data.dart';
import 'package:quick_bite/screens/provider/theme_provider.dart';
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
      providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Quick Bite',
            debugShowCheckedModeBanner: false,
            theme: Styles.themeData(
              isDarkTheme: themeProvider.isDarkTheme,
              context: context,
            ),
            initialRoute: FirebaseAuth.instance.currentUser == null
                ? LoginScreen.routeName 
                : Register.routeName, 
            routes: {
              LoginScreen.routeName: (context) => const LoginScreen(),
              Register.routeName: (context) => const Register(),
              // Add your other routes here:
              AdminRootScreen.routeName:(context)=> const AdminRootScreen(),
              Userdarshboar.routeName: (context) => const Userdarshboar(),
              AdminHomeScreen.routeName: (context) => const AdminHomeScreen(),
              OrdersList.routeName:(context)=>  const OrdersList(),
            }, 
          );
        },
      ),
    );
  }
}
