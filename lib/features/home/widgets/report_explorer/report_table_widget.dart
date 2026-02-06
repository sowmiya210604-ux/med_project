import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../reports/models/report_category_model.dart';

/// Spreadsheet-style report table widget with horizontal scroll
class ReportTableWidget extends StatefulWidget {
  final List<DetailedReportData> reports;
  final bool isComparisonMode;
  final List<String> selectedReportIds;
  final Function(String) onReportToggle;
  final List<ComparisonResult>? comparisonResults;

  const ReportTableWidget({
    super.key,
    required this.reports,
    required this.isComparisonMode,
    required this.selectedReportIds,
    required this.onReportToggle,
    this.comparisonResults,
  });

  @override
  State<ReportTableWidget> createState() => _ReportTableWidgetState();
}

class _ReportTableWidgetState extends State<ReportTableWidget> {
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
    if (widget.reports.isEmpty) {
      return _buildEmptyState();
    }

    // Get all unique parameters across all reports
    final allParameters = _getAllParameters();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with comparison results if available
          if (widget.comparisonResults != null)
            _buildComparisonHeader(),
          
          // Table
          _buildTable(allParameters),
        ],
      ),
    );
  }

  /// Get all unique parameters from all reports
  List<String> _getAllParameters() {
    final parametersSet = <String>{};
    for (var report in widget.reports) {
      parametersSet.addAll(report.parameters.keys);
    }
    return parametersSet.toList()..sort();
  }

  /// Build the table structure
  Widget _buildTable(List<String> parameters) {
    return Scrollbar(
      controller: _verticalScrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _verticalScrollController,
        scrollDirection: Axis.vertical,
        child: Scrollbar(
          controller: _horizontalScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: _buildTableContent(parameters),
          ),
        ),
      ),
    );
  }

  /// Build table content
  Widget _buildTableContent(List<String> parameters) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed first column (parameters)
          _buildParameterColumn(parameters),
          
          // Report columns
          ..._buildReportColumns(parameters),

          // Comparison column if available
          if (widget.comparisonResults != null)
            _buildComparisonColumn(),
        ],
      ),
    );
  }

  /// Build the parameter column (fixed first column)
  Widget _buildParameterColumn(List<String> parameters) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          right: BorderSide(color: Color(0xFFE5E7EB), width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header cell
          _buildCell(
            content: 'Parameter',
            isHeader: true,
            width: 180,
            backgroundColor: AppColors.primary,
            textColor: Colors.white,
          ),
          // Parameter cells
          ...parameters.map((param) => _buildCell(
                content: param,
                width: 180,
                isParameterCell: true,
              )),
          // Summary row
          _buildCell(
            content: 'Summary / Notes',
            width: 180,
            isParameterCell: true,
            backgroundColor: AppColors.background,
          ),
        ],
      ),
    );
  }

  /// Build report columns
  List<Widget> _buildReportColumns(List<String> parameters) {
    return widget.reports.map((report) {
      final isSelected = widget.selectedReportIds.contains(report.reportId);
      final dateStr = DateFormat('dd MMM yyyy').format(report.reportDate);

      return Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.05)
              : Colors.white,
          border: const Border(
            right: BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with date and checkbox
            _buildDateHeader(report, dateStr, isSelected),
            
            // Parameter value cells
            ...parameters.map((param) {
              final paramValue = report.parameters[param];
              return _buildValueCell(paramValue);
            }),
            
            // Summary cell
            _buildCell(
              content: _truncateSummary(report.summary),
              width: 160,
              minHeight: 80,
            ),
          ],
        ),
      );
    }).toList();
  }

  /// Build date header with optional checkbox
  Widget _buildDateHeader(DetailedReportData report, String dateStr, bool isSelected) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: isSelected ? AppColors.primaryGradient : null,
        color: isSelected ? null : AppColors.secondary,
      ),
      child: Column(
        children: [
          if (widget.isComparisonMode)
            Checkbox(
              value: isSelected,
              onChanged: (_) => widget.onReportToggle(report.reportId),
              activeColor: Colors.white,
              checkColor: AppColors.primary,
              side: BorderSide(
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          Text(
            dateStr,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build value cell for a parameter
  Widget _buildValueCell(ParameterValue? paramValue) {
    if (paramValue == null) {
      return _buildCell(
        content: 'N/A',
        width: 160,
        textColor: AppColors.textSecondary,
        isItalic: true,
      );
    }

    String displayValue = paramValue.value.toString();
    if (paramValue.unit.isNotEmpty) {
      displayValue += ' ${paramValue.unit}';
    }

    Color? backgroundColor;
    if (paramValue.status != null) {
      switch (paramValue.status!.toLowerCase()) {
        case 'high':
          backgroundColor = Colors.red.withOpacity(0.1);
          break;
        case 'low':
          backgroundColor = Colors.orange.withOpacity(0.1);
          break;
        case 'normal':
          backgroundColor = Colors.green.withOpacity(0.1);
          break;
      }
    }

    return _buildCell(
      content: displayValue,
      width: 160,
      backgroundColor: backgroundColor,
    );
  }

  /// Build comparison column
  Widget _buildComparisonColumn() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        border: const Border(
          left: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildCell(
            content: 'Comparison',
            isHeader: true,
            width: 180,
            backgroundColor: AppColors.primary,
            textColor: Colors.white,
          ),
          // Comparison result cells
          ...widget.comparisonResults!.map((result) {
            return _buildComparisonCell(result);
          }),
        ],
      ),
    );
  }

  /// Build comparison cell
  Widget _buildComparisonCell(ComparisonResult result) {
    Color textColor = AppColors.textPrimary;
    IconData? icon;

    switch (result.status) {
      case ComparisonStatus.improved:
        textColor = Colors.green.shade700;
        icon = Icons.arrow_upward;
        break;
      case ComparisonStatus.worsened:
        textColor = Colors.red.shade700;
        icon = Icons.arrow_downward;
        break;
      case ComparisonStatus.increased:
        textColor = Colors.blue.shade700;
        icon = Icons.trending_up;
        break;
      case ComparisonStatus.decreased:
        textColor = Colors.orange.shade700;
        icon = Icons.trending_down;
        break;
      case ComparisonStatus.stable:
        textColor = Colors.grey.shade700;
        icon = Icons.remove;
        break;
      case ComparisonStatus.noData:
        textColor = AppColors.textSecondary;
        break;
    }

    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        children: [
          if (icon != null)
            Icon(icon, size: 16, color: textColor),
          if (icon != null)
            const SizedBox(width: 6),
          Expanded(
            child: Text(
              result.description,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a generic cell
  Widget _buildCell({
    required String content,
    double width = 160,
    double minHeight = 48,
    bool isHeader = false,
    bool isParameterCell = false,
    bool isItalic = false,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return Container(
      width: width,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ?? (isParameterCell ? AppColors.background : Colors.white),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      child: Text(
        content,
        style: TextStyle(
          fontSize: isHeader ? 13 : 12,
          fontWeight: isHeader || isParameterCell ? FontWeight.w600 : FontWeight.w400,
          color: textColor ?? AppColors.textPrimary,
          fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
  }

  /// Build comparison header
  Widget _buildComparisonHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.1),
          ],
        ),
        border: const Border(
          bottom: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.compare_arrows, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comparison Results',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Comparing ${widget.selectedReportIds.length} reports',
                  style: const TextStyle(
                    fontSize: 12,
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

  /// Build empty state
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.insert_chart_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'No Reports Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Upload reports for this category to view them here',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Truncate summary text
  String _truncateSummary(String summary) {
    if (summary.length <= 100) return summary;
    return '${summary.substring(0, 100)}...';
  }
}
