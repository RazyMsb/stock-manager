import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:razy_mesboub_2/services/analytics_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsDashboard extends ConsumerStatefulWidget {
  final String userId;

  const AnalyticsDashboard({super.key, required this.userId});

  @override
  ConsumerState<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends ConsumerState<AnalyticsDashboard> {
  Map<String, dynamic>? analytics;

  @override
  void initState() {
    super.initState();
    loadAnalytics();
  }

  Future<void> loadAnalytics() async {
    final result = await AnalyticsService().getInventoryAnalytics(widget.userId);
    setState(() => analytics = result);
  }

  @override
  Widget build(BuildContext context) {
    if (analytics == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("📊 Tableau de bord intelligent"),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildIndicatorsRow(),
            const SizedBox(height: 24),
            _buildCategoryPieChart(),
            const SizedBox(height: 24),
            _buildMonthlyBarChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildIndicatorCard("Total Produits", "${analytics!['totalProducts']}", Icons.inventory_2),
        _buildIndicatorCard("Valeur Totale", "${analytics!['totalStockValue'].toStringAsFixed(2)} €", Icons.euro),
        _buildIndicatorCard("Alerte Stock", "${analytics!['lowStockCount']}", Icons.warning_amber),
      ],
    );
  }

  Widget _buildIndicatorCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        color: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Colors.blueAccent),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 18, color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPieChart() {
    final Map<String, int> categoryDist = Map<String, int>.from(analytics!['categoryDistribution']);
    final total = categoryDist.values.fold(0, (sum, e) => sum + e);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Répartition des catégories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: categoryDist.entries.map((entry) {
                    final percent = (entry.value / total) * 100;
                    return PieChartSectionData(
                      value: entry.value.toDouble(),
                      color: _getColorForCategory(entry.key),
                      title: '${entry.key}\n${percent.toStringAsFixed(1)}%',
                      radius: 80,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyBarChart() {
    final Map<String, double> monthlyStock = Map<String, double>.from(analytics!['monthlyStock']);
    final months = monthlyStock.keys.toList()..sort();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Évolution du stock par mois", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  barGroups: List.generate(months.length, (i) {
                    final value = monthlyStock[months[i]]!;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(toY: value, color: Colors.blueAccent, width: 14),
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final index = value.toInt();
                          return SideTitleWidget(
                            axisSide: AxisSide.bottom,
                            child: Text(
                              months[index].substring(5),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForCategory(String category) {
    final colors = [
      Colors.blueAccent,
      Colors.orangeAccent,
      Colors.green,
      Colors.purple,
      Colors.redAccent,
      Colors.teal,
    ];
    return colors[category.hashCode % colors.length];
  }
}
