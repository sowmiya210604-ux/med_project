import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../reports/providers/report_provider.dart';
import '../../reports/models/report_model.dart';
import '../widgets/test_result_chart.dart';
import 'test_history_screen.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  String _selectedParameter = 'Hemoglobin';
  final List<String> _availableParameters = [
    'Hemoglobin',
    'Total Cholesterol',
    'Fasting Glucose',
    'WBC',
    'Platelets',
  ];

  @override
  void initState() {
    super.initState();
    // Fetch reports when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().fetchReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Health Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showParameterSelector();
            },
          ),
        ],
      ),
      body: Consumer<ReportProvider>(
        builder: (context, reportProvider, _) {
          final testResults = reportProvider.testResults;

          if (testResults.isEmpty) {
            return _buildEmptyState();
          }

          // Filter results by selected parameter
          final filteredResults =
              reportProvider.getTestResultsByParameter(_selectedParameter);

          if (filteredResults.isEmpty) {
            return _buildNoDataForParameter();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Parameter Selector
                _buildParameterChips(),
                const SizedBox(height: 24),

                // Latest Result Card
                _buildLatestResultCard(filteredResults.last),
                const SizedBox(height: 24),

                // Trend Chart
                _buildTrendChart(filteredResults),
                const SizedBox(height: 24),

                // View History Button
                _buildViewHistoryButton(filteredResults),
                const SizedBox(height: 24),

                // All Parameters Overview
                _buildAllParametersOverview(reportProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildParameterChips() {
    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _availableParameters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final parameter = _availableParameters[index];
          final isSelected = parameter == _selectedParameter;

          return FilterChip(
            label: Text(parameter),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedParameter = parameter;
              });
            },
            backgroundColor: Colors.white,
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            side: BorderSide(
              color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLatestResultCard(TestResult latestResult) {
    final statusColor = _getStatusColor(latestResult.status);
    final statusText = _getStatusText(latestResult.status);

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
                'Latest Result',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${latestResult.value}',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  latestResult.unit,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Tested on ${_formatDate(latestResult.testDate)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          if (latestResult.normalMin != null &&
              latestResult.normalMax != null) ...[
            const SizedBox(height: 12),
            Text(
              'Normal Range: ${latestResult.normalMin} - ${latestResult.normalMax} ${latestResult.unit}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendChart(List<TestResult> results) {
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
          Text(
            'Trend Over Time',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: TestResultChart(results: results),
          ),
        ],
      ),
    );
  }

  Widget _buildViewHistoryButton(List<TestResult> results) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TestHistoryScreen(
              parameterName: _selectedParameter,
              results: results,
            ),
          ),
        );
      },
      icon: const Icon(Icons.history),
      label: const Text('View Detailed History'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }

  Widget _buildAllParametersOverview(ReportProvider reportProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Parameters',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _availableParameters.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final parameter = _availableParameters[index];
            final results = reportProvider.getTestResultsByParameter(parameter);

            if (results.isEmpty) {
              return const SizedBox.shrink();
            }

            final latestResult = results.last;
            return _buildParameterCard(parameter, latestResult);
          },
        ),
      ],
    );
  }

  Widget _buildParameterCard(String parameter, TestResult latestResult) {
    final statusColor = _getStatusColor(latestResult.status);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedParameter = parameter;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    parameter,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${latestResult.value} ${latestResult.unit}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              _getStatusIcon(latestResult.status),
              color: statusColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.insights,
                size: 80,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Insights Available',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Upload medical reports to see health insights and trends',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataForParameter() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bar_chart,
              size: 80,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 24),
            Text(
              'No Data Available',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'No test results found for $_selectedParameter',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showParameterSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Parameter',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              itemCount: _availableParameters.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final parameter = _availableParameters[index];
                return ListTile(
                  title: Text(parameter),
                  trailing: _selectedParameter == parameter
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedParameter = parameter;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
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

  String _getStatusText(TestStatus status) {
    switch (status) {
      case TestStatus.normal:
        return 'NORMAL';
      case TestStatus.high:
        return 'HIGH';
      case TestStatus.low:
        return 'LOW';
    }
  }

  IconData _getStatusIcon(TestStatus status) {
    switch (status) {
      case TestStatus.normal:
        return Icons.check_circle;
      case TestStatus.high:
        return Icons.arrow_upward;
      case TestStatus.low:
        return Icons.arrow_downward;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
