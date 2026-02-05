import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../reports/models/report_model.dart';

class TestHistoryScreen extends StatefulWidget {
  final String parameterName;
  final List<TestResult> results;

  const TestHistoryScreen({
    super.key,
    required this.parameterName,
    required this.results,
  });

  @override
  State<TestHistoryScreen> createState() => _TestHistoryScreenState();
}

class _TestHistoryScreenState extends State<TestHistoryScreen> {
  String _selectedMonth = 'All';
  String _selectedYear = 'All';

  List<String> _availableYears = [];
  List<String> _availableMonths = [];

  @override
  void initState() {
    super.initState();
    _extractAvailableDates();
  }

  void _extractAvailableDates() {
    final years = widget.results
        .map((r) => r.testDate.year.toString())
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    _availableYears = ['All', ...years];
    _availableMonths = [
      'All',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
  }

  List<TestResult> _getFilteredResults() {
    return widget.results.where((result) {
      final matchesYear = _selectedYear == 'All' ||
          result.testDate.year.toString() == _selectedYear;

      final matchesMonth = _selectedMonth == 'All' ||
          DateFormat('MMMM').format(result.testDate) == _selectedMonth;

      return matchesYear && matchesMonth;
    }).toList()
      ..sort((a, b) => b.testDate.compareTo(a.testDate));
  }

  @override
  Widget build(BuildContext context) {
    final filteredResults = _getFilteredResults();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.parameterName} History'),
      ),
      body: Column(
        children: [
          // Filters
          _buildFilters(),

          // Results Table
          Expanded(
            child: filteredResults.isEmpty
                ? _buildEmptyState()
                : _buildResultsTable(filteredResults),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        children: [
          // Year Filter
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedYear,
              decoration: const InputDecoration(
                labelText: 'Year',
                prefixIcon: Icon(Icons.calendar_today),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: _availableYears.map((year) {
                return DropdownMenuItem(
                  value: year,
                  child: Text(year),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedYear = value!;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          // Month Filter
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedMonth,
              decoration: const InputDecoration(
                labelText: 'Month',
                prefixIcon: Icon(Icons.event),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: _availableMonths.map((month) {
                return DropdownMenuItem(
                  value: month,
                  child: Text(month),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMonth = value!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsTable(List<TestResult> results) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${results.length} ${results.length == 1 ? 'Result' : 'Results'} Found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Date',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Value',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Status',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                // Table Rows
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: results.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return _buildResultRow(results[index]);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(TestResult result) {
    final statusColor = _getStatusColor(result.status);
    final statusText = _getStatusText(result.status);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(result.testDate),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('hh:mm a').format(result.testDate),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              '${result.value} ${result.unit}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
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
            const Icon(
              Icons.filter_list_off,
              size: 80,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 24),
            Text(
              'No Results Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
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
}
