import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsDashboard extends StatelessWidget {
  final String userId;

  const AnalyticsDashboard({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1E4D6B); // Define primary color
    final backgroundColor = const Color(0xFFF5F2ED);
    final gradientColors = [primaryColor, Colors.blueAccent];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord Analytique'),
        backgroundColor: primaryColor,
      ),
      body: Container(
        color: backgroundColor,
        width: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Analytics for $userId',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Line Chart
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Trends Over Time',
                  style: TextStyle(fontSize: 18, color: primaryColor),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(show: true),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          FlSpot(0, 1),
                          FlSpot(1, 3),
                          FlSpot(2, 6),
                          FlSpot(3, 2),
                 ],
                        isCurved: true,
gradient: LinearGradient(
  colors: gradientColors,
),                        dotData: FlDotData(show: false),
                        barWidth: 4,
                        belowBarData: BarAreaData(show: true),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: Colors.blueAccent,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
