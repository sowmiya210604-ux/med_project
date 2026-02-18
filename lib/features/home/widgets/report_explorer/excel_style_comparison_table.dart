import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../reports/providers/report_explorer_provider.dart';
import '../../../reports/models/report_category_model.dart';

/// Excel-Style Comparison Table Widget
/// Displays test parameters in rows and report dates in columns
class ExcelStyleComparisonTable extends StatefulWidget {
  const ExcelStyleComparisonTable({super.key});

  @override
  State<ExcelStyleComparisonTable> createState() =>
      _ExcelStyleComparisonTableState();
}

class _ExcelStyleComparisonTableState
    extends State<ExcelStyleComparisonTable> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportExplorerProvider>(
      builder: (context, provider, _) {
        final reports = provider.currentReports;

        if (reports.isEmpty) {
          return _buildEmptyState();
        }

        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTableHeader(provider),
              _buildComparisonModeToggle(provider),
              if (provider.isComparisonMode)
                _buildComparisonControls(provider),
              const Divider(height: 1),
              _buildTable(reports),
            ],
          ),
        );
      },
    );
  }

  /// Build table header
  Widget _buildTableHeader(ReportExplorerProvider provider) {
    String title = 'Report Comparison Table';
    if (provider.selectedSubCategory != null) {
      if (provider.selectedSubCategory is LabSubCategory) {
        title = (provider.selectedSubCategory as LabSubCategory).displayName;
      } else if (provider.selectedSubCategory is ImagingSubCategory) {
        title =
            (provider.selectedSubCategory as ImagingSubCategory).displayName;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.table_chart, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${provider.currentReports.length} report(s) found',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build comparison mode toggle button
  Widget _buildComparisonModeToggle(ReportExplorerProvider provider) {
    if (provider.currentReports.length < 2) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () => provider.toggleComparisonMode(),
        icon: Icon(
          provider.isComparisonMode ? Icons.close : Icons.compare_arrows,
        ),
        label: Text(
          provider.isComparisonMode
              ? 'Exit Comparison Mode'
              : 'Compare Reports',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              provider.isComparisonMode ? Colors.red : AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  /// Build comparison controls (when in comparison mode)
  Widget _buildComparisonControls(ReportExplorerProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.blue.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Select exactly 2 reports to compare',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Selected: ${provider.selectedReportIdsForComparison.length} / 2',
            style: TextStyle(
              fontSize: 13,
              color: Colors.blue.shade700,
            ),
          ),
          if (provider.canGenerateComparison) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _generateComparison(provider),
              icon: const Icon(Icons.analytics),
              label: const Text('Generate Comparison'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build the comparison table
  Widget _buildTable(List<DetailedReportData> reports) {
    return SizedBox(
      height: 400,
      child: Scrollbar(
        controller: _horizontalScrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _horizontalScrollController,
          scrollDirection: Axis.horizontal,
          child: Scrollbar(
            controller: _verticalScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _verticalScrollController,
              child: _buildTableContent(reports),
            ),
          ),
        ),
      ),
    );
  }

  /// Build table content
  Widget _buildTableContent(List<DetailedReportData> reports) {
    // Get all unique parameters across all reports
    final Set<String> allParameters = {};
    for (var report in reports) {
      allParameters.addAll(report.parameters.keys);
    }

    final parameterList = allParameters.toList()..sort();

    return Consumer<ReportExplorerProvider>(
      builder: (context, provider, _) {
        return DataTable(
          columnSpacing: 20,
          horizontalMargin: 16,
          headingRowHeight: 60,
          dataRowHeight: 50,
          border: TableBorder.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
          columns: [
            // Parameter column
            const DataColumn(
              label: SizedBox(
                width: 150,
                child: Text(
                  'Parameter',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            // Date columns (one per report)
            ...reports.map((report) => _buildDateColumn(report, provider)),
          ],
          rows: [
            // Parameter rows
            ...parameterList.map((param) => _buildParameterRow(param, reports)),
            // Summary row
            _buildSummaryRow(reports),
          ],
        );
      },
    );
  }

  /// Build date column header
  DataColumn _buildDateColumn(
      DetailedReportData report, ReportExplorerProvider provider) {
    final dateStr = DateFormat('dd MMM yyyy').format(report.reportDate);
    final isSelected =
        provider.isReportSelectedForComparison(report.reportId);

    return DataColumn(
      label: GestureDetector(
        onTap: provider.isComparisonMode
            ? () => provider.toggleReportSelection(report.reportId)
            : null,
        child: Container(
          width: 120,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade100 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: Colors.blue.shade700, width: 2)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (provider.isComparisonMode)
                Icon(
                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 18,
                  color: isSelected ? Colors.blue.shade700 : Colors.grey,
                ),
              if (provider.isComparisonMode)
                const SizedBox(height: 2),
              Flexible(
                child: Text(
                  dateStr,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: isSelected ? Colors.blue.shade900 : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build parameter row
  DataRow _buildParameterRow(String parameter, List<DetailedReportData> reports) {
    return DataRow(
      cells: [
        // Parameter name cell
        DataCell(
          SizedBox(
            width: 150,
            child: Text(
              parameter,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
        // Value cells (one per report)
        ...reports.map((report) {
          final paramValue = report.parameters[parameter];
          return _buildValueCell(paramValue);
        }),
      ],
    );
  }

  /// Build value cell
  DataCell _buildValueCell(ParameterValue? paramValue) {
    if (paramValue == null) {
      return const DataCell(
        SizedBox(
          width: 120,
          child: Center(
            child: Text(
              '-',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final status = paramValue.status ?? 'NORMAL';
    Color statusColor = Colors.grey;
    if (status == 'NORMAL') {
      statusColor = Colors.green;
    } else if (status == 'HIGH') {
      statusColor = Colors.red;
    } else if (status == 'LOW') {
      statusColor = Colors.orange;
    }

    return DataCell(
      Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${paramValue.value} ${paramValue.unit ?? ''}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: statusColor,
              ),
            ),
            if (status != 'NORMAL')
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build summary row
  DataRow _buildSummaryRow(List<DetailedReportData> reports) {
    return DataRow(
      color: WidgetStateProperty.all(Colors.grey.shade100),
      cells: [
        const DataCell(
          SizedBox(
            width: 150,
            child: Text(
              'Overall Status',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        ...reports.map((report) {
          // Only count parameters that have actual values (not empty placeholders)
          final parametersWithValues = report.parameters.values
              .where((p) {
                if (p.value == null) return false;
                final valueStr = p.value.toString();
                return valueStr.isNotEmpty && valueStr != '-';
              })
              .toList();
          
          final normalCount = parametersWithValues
              .where((p) => (p.status ?? 'normal') == 'normal')
              .length;
          final totalCount = parametersWithValues.length;
          final status = totalCount == 0 ? 'No Data' : 
                        (normalCount == totalCount ? 'Normal' : 'Attention Needed');
          final statusColor = totalCount == 0 ? Colors.grey :
                             (normalCount == totalCount ? Colors.green : Colors.orange);

          return DataCell(
            SizedBox(
              width: 120,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    status,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    '$normalCount/$totalCount normal',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.table_chart_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No reports to display',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a category to view reports',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Generate comparison between selected reports
  void _generateComparison(ReportExplorerProvider provider) async {
    final selectedIds = provider.selectedReportIdsForComparison;
    if (selectedIds.length != 2) return;

    // Get the two selected reports
    final report1 = provider.currentReports
        .firstWhere((r) => r.reportId == selectedIds[0]);
    final report2 = provider.currentReports
        .firstWhere((r) => r.reportId == selectedIds[1]);

    // Navigate to detailed comparison screen or show dialog
    _showComparisonDialog(report1, report2);
  }

  /// Show comparison dialog
  void _showComparisonDialog(
      DetailedReportData report1, DetailedReportData report2) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detailed Comparison'),
        content: SizedBox(
          width: double.maxFinite,
          child: _buildComparisonContent(report1, report2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Build comparison content
  Widget _buildComparisonContent(
      DetailedReportData report1, DetailedReportData report2) {
    final allParams = <String>{
      ...report1.parameters.keys,
      ...report2.parameters.keys,
    }.toList()
      ..sort();

    return ListView.builder(
      shrinkWrap: true,
      itemCount: allParams.length,
      itemBuilder: (context, index) {
        final param = allParams[index];
        final value1 = report1.parameters[param];
        final value2 = report2.parameters[param];

        return _buildComparisonRow(param, value1, value2, report1, report2);
      },
    );
  }

  /// Build comparison row
  Widget _buildComparisonRow(
    String parameter,
    ParameterValue? value1,
    ParameterValue? value2,
    DetailedReportData report1,
    DetailedReportData report2,
  ) {
    String change = '-';
    String trend = '';
    Color trendColor = Colors.grey;

    if (value1 != null && value2 != null) {
      final num1 = double.tryParse(value1.value.toString());
      final num2 = double.tryParse(value2.value.toString());

      if (num1 != null && num2 != null) {
        final diff = num2 - num1;
        final percentChange = ((diff / num1) * 100).abs();

        if (diff > 0) {
          trend = '↑';
          trendColor = Colors.red;
          change = '+${diff.toStringAsFixed(2)}';
        } else if (diff < 0) {
          trend = '↓';
          trendColor = Colors.green;
          change = diff.toStringAsFixed(2);
        } else {
          trend = '→';
          trendColor = Colors.blue;
          change = '0';
        }

        change += ' (${percentChange.toStringAsFixed(1)}%)';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              parameter,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Older', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        value1 != null ? '${value1.value.toString()} ${value1.unit}' : '-',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      trend,
                      style: TextStyle(
                        fontSize: 24,
                        color: trendColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      change,
                      style: TextStyle(
                        fontSize: 11,
                        color: trendColor,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Newer', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        value2 != null ? '${value2.value.toString()} ${value2.unit}' : '-',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
