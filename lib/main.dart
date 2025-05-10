import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:razy_mesboub_2/models/products.dart';
import 'package:razy_mesboub_2/screens/TransactionHistory_Page.dart';
import 'package:razy_mesboub_2/screens/analytics_dashboard.dart';
import 'package:razy_mesboub_2/screens/edit_products_page.dart.dart';
import 'package:razy_mesboub_2/screens/productdetail_page%20.dart';
import 'package:razy_mesboub_2/screens/productsListe_page.dart' hide ProductDetailScreen;
import 'package:razy_mesboub_2/services/analytics_service.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'screens/addproducts_page.dart';
final analyticsService = AnalyticsService();
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
        '/home': (ctx) => const HomeScreen(),
        '/add-product': (ctx) => const AddProductForm(),
        '/product-list': (ctx) => const ItemsList(), // Add this route
        '/edit-product': (ctx) => EditProductScreen(ModalRoute.of(ctx)!.settings.arguments as Product),
        '/product-detail': (ctx) => const ProductDetailScreen(),
        '/analytics-dashboard':(ctx) => AnalyticsDashboard(userId: ModalRoute.of(ctx)!.settings.arguments as String),
          '/transaction-history': (context) => TransactionHistoryPage(), // SUPPRIMER


      },
     theme: ThemeData(
  primaryColor: const Color(0xFF1E4D6B),
  scaffoldBackgroundColor: const Color(0xFFF5F2ED),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF1E4D6B),
    extendedSizeConstraints: BoxConstraints.tightFor(height: 56, width: 56),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF1E4D6B),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
),
    );
  }
}