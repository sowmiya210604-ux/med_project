import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../models/report_model.dart';

class TestResultsTableWidget extends StatelessWidget {
  final List<TestResult> testResults;

  const TestResultsTableWidget({
    super.key,
    required this.testResults,
  });

  @override
  Widget build(BuildContext context) {
    if (testResults.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group test results by date and parameter
    final Map<String, Map<String, TestResult>> dataByDate = {};
    final Set<String> allParameters = {};

    // First pass: collect all parameters and organize by date
    for (var result in testResults) {
      final dateKey = DateFormat('yyyy-MM-dd').format(result.testDate);
      allParameters.add(result.parameterName);

      if (!dataByDate.containsKey(dateKey)) {
        dataByDate[dateKey] = {};
      }
      dataByDate[dateKey]![result.parameterName] = result;
    }

    // Sort dates (most recent first)
    final sortedDates = dataByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    // Sort parameters alphabetically
    final sortedParameters = allParameters.toList()..sort();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Test Results Overview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Chip(
                label: Text('${sortedDates.length} tests'),
                backgroundColor: AppColors.primary.withOpacity(0.1),
                labelStyle: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                AppColors.primary.withOpacity(0.1),
              ),
              headingRowHeight: 60,
              dataRowMinHeight: 50,
              dataRowMaxHeight: 60,
              columnSpacing: 24,
              columns: [
                const DataColumn(
                  label: Text(
                    'Date',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
                ...sortedParameters.map((param) => DataColumn(
                      label: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            param,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 12,
                            ),
                          ),
                          if (dataByDate.values.first[param] != null)
                            Text(
                              dataByDate.values.first[param]!.unit,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                        ],
                      ),
                    )),
              ],
              rows: sortedDates.map((dateKey) {
                final dateData = dataByDate[dateKey]!;
                final date = DateTime.parse(dateKey);

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        DateFormat('MMM dd\nyyyy').format(date),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ...sortedParameters.map((param) {
                      final result = dateData[param];
                      if (result == null) {
                        return const DataCell(
                          Center(
                            child: Text(
                              '-',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }

                      Color statusColor;
                      switch (result.status) {
                        case TestStatus.high:
                          statusColor = AppColors.error;
                          break;
                        case TestStatus.low:
                          statusColor = AppColors.warning;
                          break;
                        case TestStatus.normal:
                          statusColor = AppColors.success;
                          break;
                      }

                      return DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: result.status != TestStatus.normal
                                ? statusColor.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: result.status != TestStatus.normal
                                ? Border.all(
                                    color: statusColor.withOpacity(0.3))
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                result.value.toString(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: result.status != TestStatus.normal
                                      ? statusColor
                                      : Colors.black87,
                                ),
                              ),
                              if (result.normalMin != null &&
                                  result.normalMax != null)
                                Text(
                                  '(${result.normalMin}-${result.normalMax})',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildLegend('Normal', AppColors.success),
              const SizedBox(width: 16),
              _buildLegend('High', AppColors.error),
              const SizedBox(width: 16),
              _buildLegend('Low', AppColors.warning),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
