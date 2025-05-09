import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getInventoryAnalytics(String userId) async {
    try {
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
        totalProducts++;

        final price = (data['price'] ?? 0).toDouble();
        final quantity = (data['quantity'] ?? 0).toDouble();
        totalStockValue += price * quantity;

        if (quantity < 5) lowStockCount++;

        final category = data['category'] ?? 'Uncategorized';
        categoryDistribution[category] = (categoryDistribution[category] ?? 0) + 1;

        if (data['expiryDate'] != null) {
          final expiry = _parseDate(data['expiryDate']);
          if (expiry != null) {
            final key = DateFormat('MMM yyyy').format(expiry);
            monthlyStock[key] = (monthlyStock[key] ?? 0) + quantity;
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
    } catch (e) {
      throw Exception('Analytics error: $e');
    }
  }

  DateTime? _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (_) {
      return null;
    }
  }
}
