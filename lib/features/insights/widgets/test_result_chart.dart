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

    // Sort results by date
    final sortedResults = List<TestResult>.from(results)
      ..sort((a, b) => a.testDate.compareTo(b.testDate));

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
                    value.toInt() < sortedResults.length) {
                  final result = sortedResults[value.toInt()];
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
        maxX: (sortedResults.length - 1).toDouble(),
        minY: _getMinY(sortedResults),
        maxY: _getMaxY(sortedResults),
        lineBarsData: [
          LineChartBarData(
            spots: sortedResults.asMap().entries.map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                entry.value.value,
              );
            }).toList(),
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final result = sortedResults[index];
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
          if (sortedResults.first.normalMin != null)
            LineChartBarData(
              spots: [
                FlSpot(0, sortedResults.first.normalMin!),
                FlSpot(
                  (sortedResults.length - 1).toDouble(),
                  sortedResults.first.normalMin!,
                ),
              ],
              isCurved: false,
              color: AppColors.success.withOpacity(0.5),
              barWidth: 1,
              dashArray: [5, 5],
              dotData: const FlDotData(show: false),
            ),
          if (sortedResults.first.normalMax != null)
            LineChartBarData(
              spots: [
                FlSpot(0, sortedResults.first.normalMax!),
                FlSpot(
                  (sortedResults.length - 1).toDouble(),
                  sortedResults.first.normalMax!,
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
                final result = sortedResults[spot.x.toInt()];
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
    double min = results.map((r) => r.value).reduce((a, b) => a < b ? a : b);

    // Include normal range in calculation
    if (results.first.normalMin != null) {
      min = min < results.first.normalMin! ? min : results.first.normalMin!;
    }

    return (min * 0.9).floorToDouble();
  }

  double _getMaxY(List<TestResult> results) {
    double max = results.map((r) => r.value).reduce((a, b) => a > b ? a : b);

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
