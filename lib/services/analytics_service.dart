import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getInventoryAnalytics(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('products')
        .get();

    int totalProducts = 0;
    double totalStockValue = 0;
    int lowStockCount = 0;

    Map<String, int> categoryDistribution = {};
    Map<String, double> monthlyStock = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();

      final double price = double.tryParse(data['price'].toString()) ?? 0;
      final int quantity = int.tryParse(data['quantity'].toString()) ?? 0;
      final int minStock = int.tryParse(data['minStock']?.toString() ?? '5') ?? 5;
      final String category = data['category'] ?? 'Inconnu';

      totalProducts += 1;
      totalStockValue += price * quantity;

      if (quantity <= minStock) {
        lowStockCount += 1;
      }

      // Catégorie
      categoryDistribution[category] = (categoryDistribution[category] ?? 0) + 1;

      // Mois d'ajout (yyyy-MM)
      if (data['date'] != null) {
        final date = DateTime.tryParse(data['date']);
        if (date != null) {
          final monthKey = DateFormat('yyyy-MM').format(date);
          monthlyStock[monthKey] = (monthlyStock[monthKey] ?? 0) + quantity;
        }
      }
    }

    return {
      'totalProducts': totalProducts,
      'totalStockValue': totalStockValue,
      'lowStockCount': lowStockCount,
      'categoryDistribution': categoryDistribution,
      'monthlyStock': monthlyStock,
    };
  }
}
