import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'screens/addproducts_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WA Inventory',
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (ctx) => const LoginScreen(),
        '/home': (ctx)  => const HomeScreen(),
        '/add-product': (ctx) => const AddProductForm(),
      },
    );
  }
}
