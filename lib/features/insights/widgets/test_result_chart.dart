import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../reports/models/report_model.dart';

class TestResultChart extends StatelessWidget {
  final List<TestResult> results;

  const TestResultChart({
    super.key,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    // Sort results by date and filter to only numeric values
    final sortedResults = List<TestResult>.from(results)
      ..sort((a, b) => a.testDate.compareTo(b.testDate));
    
    // Filter to only numeric values for chart display
    final numericResults = sortedResults.where((r) => r.value is num).toList();
    
    // If no numeric results, don't show chart
    if (numericResults.isEmpty) {
      return const Center(
        child: Text('No numeric data available for chart'),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return const FlLine(
              color: Color(0xFFE5E7EB),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 &&
                    value.toInt() < numericResults.length) {
                  final result = numericResults[value.toInt()];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${result.testDate.day}/${result.testDate.month}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            left: BorderSide(color: Color(0xFFE5E7EB)),
            bottom: BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
        minX: 0,
        maxX: (numericResults.length - 1).toDouble(),
        minY: _getMinY(numericResults),
        maxY: _getMaxY(numericResults),
        lineBarsData: [
          LineChartBarData(
            spots: numericResults.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                (entry.value.value as num).toDouble(),
              );
            }).toList(),
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final result = numericResults[index];
                return FlDotCirclePainter(
                  radius: 6,
                  color: _getStatusColor(result.status),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.2),
                  AppColors.primary.withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Normal range lines
          if (numericResults.first.normalMin != null)
            LineChartBarData(
              spots: [
                FlSpot(0, numericResults.first.normalMin!),
                FlSpot(
                  (numericResults.length - 1).toDouble(),
                  numericResults.first.normalMin!,
                ),
              ],
              isCurved: false,
              color: AppColors.success.withOpacity(0.5),
              barWidth: 1,
              dashArray: [5, 5],
              dotData: const FlDotData(show: false),
            ),
          if (numericResults.first.normalMax != null)
            LineChartBarData(
              spots: [
                FlSpot(0, numericResults.first.normalMax!),
                FlSpot(
                  (numericResults.length - 1).toDouble(),
                  numericResults.first.normalMax!,
                ),
              ],
              isCurved: false,
              color: AppColors.success.withOpacity(0.5),
              barWidth: 1,
              dashArray: [5, 5],
              dotData: const FlDotData(show: false),
            ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: AppColors.primary,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final result = numericResults[spot.x.toInt()];
                return LineTooltipItem(
                  '${result.value} ${result.unit}\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text:
                          '${result.testDate.day}/${result.testDate.month}/${result.testDate.year}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  double _getMinY(List<TestResult> results) {
    double min = results.map((r) => (r.value as num).toDouble()).reduce((a, b) => a < b ? a : b);

    // Include normal range in calculation
    if (results.first.normalMin != null) {
      min = min < results.first.normalMin! ? min : results.first.normalMin!;
    }

    return (min * 0.9).floorToDouble();
  }

  double _getMaxY(List<TestResult> results) {
    double max = results.map((r) => (r.value as num).toDouble()).reduce((a, b) => a > b ? a : b);

    // Include normal range in calculation
    if (results.first.normalMax != null) {
      max = max > results.first.normalMax! ? max : results.first.normalMax!;
    }

    return (max * 1.1).ceilToDouble();
  }

  Color _getStatusColor(TestStatus status) {
    switch (status) {
      case TestStatus.normal:
        return AppColors.normalStatus;
      case TestStatus.high:
        return AppColors.highStatus;
      case TestStatus.low:
        return AppColors.lowStatus;
    }
  }
}
