import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io' if (dart.library.html) '../../../core/utils/file_stub.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../models/report_model.dart';
import '../providers/report_provider.dart';
import '../../insights/screens/test_history_screen.dart';
import '../../../core/services/test_history_service.dart';
import '../../../core/services/http_service.dart';
import '../../../core/config/api_config.dart';
import '../widgets/test_results_table_widget.dart';

class ReportDetailScreen extends StatefulWidget {
  final MedicalReport report;

  const ReportDetailScreen({
    super.key,
    required this.report,
  });

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  List<TestResult> _testHistory = [];
  bool _isLoadingHistory = false;
  String? _historyError;

  @override
  void initState() {
    super.initState();
    _loadTestHistory();
    // Force refresh report data to get latest test results
    Future.microtask(() {
      context.read<ReportProvider>().fetchReports(forceRefresh: true);
    });
  }

  Future<void> _loadTestHistory() async {
    setState(() {
      _isLoadingHistory = true;
      _historyError = null;
    });

    try {
      print('🔍 Loading test history for report: ${widget.report.id}');

      // Fetch test history from backend API
      final historyData = await TestHistoryService.getTestHistory(
        testName: widget.report.testName,
      );

      print('📊 Received ${historyData.length} test history results');

      if (historyData.isEmpty) {
        print('⚠️ No test history data, loading current report results...');
        // Fallback: Load current report's test results
        await _loadCurrentReportResults();
        return;
      }

      // FILTER: Only show results for THIS report (not historical data from other reports)
      final currentReportData = historyData.where((data) {
        return data['reportId']?.toString() == widget.report.id;
      }).toList();

      print('📋 Filtered to ${currentReportData.length} results for current report');
      print('✅ Test history data: ${currentReportData.take(2).toList()}');

      // Convert to TestResult objects
      final testResults = currentReportData.map((data) {
        // Handle date field (backend returns 'date' for history)
        final dateStr = data['date'] ?? data['testDate'];
        
        // Parse value - preserve type (qualitative String or quantitative num)
        dynamic parsedValue;
        if (data['value'] is num) {
          parsedValue = (data['value'] as num).toDouble();
        } else if (data['value'] is String) {
          final str = data['value'] as String;
          final numValue = double.tryParse(str);
          parsedValue = numValue ?? str; // Keep as string if not numeric
        } else {
          parsedValue = 0.0;
        }
        
        return TestResult(
          id: data['id']?.toString() ?? '',
          reportId: data['reportId']?.toString() ?? widget.report.id,
          testName: data['testName'] ?? widget.report.testName,
          parameterName: data['parameterName'] ?? '',
          value: parsedValue,
          unit: data['unit'] ?? '',
          normalMin: (data['normalMin'] as num?)?.toDouble(),
          normalMax: (data['normalMax'] as num?)?.toDouble(),
          status: _parseStatus(data['status']),
          testDate: dateStr != null ? DateTime.parse(dateStr) : DateTime.now(),
        );
      }).toList();

      print('✅ Converted to ${testResults.length} TestResult objects for current report');

      setState(() {
        _testHistory = testResults;
        _isLoadingHistory = false;
      });
    } catch (e) {
      print('❌ Error loading test history: $e');
      setState(() {
        _historyError = 'Failed to load test history. Please try again.';
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _loadCurrentReportResults() async {
    try {
      print('📥 Fetching current report test results from API...');
      
      final response = await HttpService.get(
        '${ApiConfig.reportUrl}/${widget.report.id}',
        requiresAuth: true,
      );

      print('✅ Got report response: ${response.toString().substring(0, response.toString().length > 200 ? 200 : response.toString().length)}');

      if (response['report'] != null && response['report']['testResults'] != null) {
        final testResultsData = response['report']['testResults'] as List;
        
        final testResults = testResultsData.map((data) {
          // Parse value - preserve type (qualitative String or quantitative num)
          dynamic parsedValue;
          final rawValue = data['value'];
          if (rawValue is num) {
            parsedValue = rawValue.toDouble();
          } else if (rawValue is String) {
            final numValue = double.tryParse(rawValue);
            parsedValue = numValue ?? rawValue; // Keep as string if not numeric
          } else {
            parsedValue = 0.0;
          }
          
          return TestResult(
            id: data['id']?.toString() ?? '',
            reportId: widget.report.id,
            testName: data['testName'] ?? widget.report.testName,
            parameterName: data['parameterName'] ?? '',
            value: parsedValue,
            unit: data['unit'] ?? '',
            normalMin: (data['normalMin'] as num?)?.toDouble(),
            normalMax: (data['normalMax'] as num?)?.toDouble(),
            status: _parseStatus(data['status']),
            testDate: widget.report.reportDate,
          );
        }).toList();

        print('✅ Loaded ${testResults.length} test results from current report');

        setState(() {
          _testHistory = testResults;
          _isLoadingHistory = false;
        });
      } else {
        print('⚠️ No test results in response');
        setState(() {
          _testHistory = [];
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      print('❌ Error loading current report results: $e');
      setState(() {
        _historyError = 'Failed to load report data';
        _isLoadingHistory = false;
      });
    }
  }

  TestStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'HIGH':
        return TestStatus.high;
      case 'LOW':
        return TestStatus.low;
      default:
        return TestStatus.normal;
    }
  }

  Future<void> _shareReport() async {
    try {
      final report = widget.report;
      final dateStr = DateFormat('MMM dd, yyyy').format(report.reportDate);

      String shareText = '''
📋 Medical Report - ${report.testName}

📅 Date: $dateStr
🏥 Lab: ${report.labName ?? 'N/A'}

📊 Test Results:
''';

      // Get test results for this report
      final reportProvider = context.read<ReportProvider>();
      final results = reportProvider.getTestResultsByName(report.testName);

      for (var result in results) {
        final normalRange = result.normalMin != null && result.normalMax != null
            ? '${result.normalMin}-${result.normalMax}'
            : 'N/A';

        shareText +=
            '\n${result.parameterName}: ${result.value} ${result.unit}';
        shareText += '\n  Normal Range: $normalRange';
        if (result.status != TestStatus.normal) {
          shareText += ' [${result.status.name.toUpperCase()}]';
        }
        shareText += '\n';
      }

      shareText += '\n\nShared from Med Track App';

      await Share.share(
        shareText,
        subject: 'Medical Report - ${report.testName}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share report: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _downloadReport() async {
    try {
      final report = widget.report;
      final dateStr = DateFormat('yyyy-MM-dd').format(report.reportDate);
      final fileName = '${report.testName.replaceAll(' ', '_')}_$dateStr.txt';

      String reportText = '''Medical Report
===============

Test Name: ${report.testName}
Date: ${DateFormat('MMM dd, yyyy').format(report.reportDate)}
Lab: ${report.labName ?? 'N/A'}

Test Results:
-------------
''';

      // Get test results for this report
      final reportProvider = context.read<ReportProvider>();
      final results = reportProvider.getTestResultsByName(report.testName);

      for (var result in results) {
        final normalRange = result.normalMin != null && result.normalMax != null
            ? '${result.normalMin}-${result.normalMax}'
            : 'N/A';

        reportText += '\n${result.parameterName}';
        reportText += '\n  Value: ${result.value} ${result.unit}';
        reportText += '\n  Normal Range: $normalRange';
        reportText += '\n  Status: ${result.status.name.toUpperCase()}';
        reportText += '\n';
      }

      reportText += '\n\nGenerated by Med Track App';
      reportText +=
          '\nDate: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}';

      // Get downloads directory
      final directory = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';

      // Write file
      final file = File(filePath);
      await file.writeAsString(reportText) as dynamic;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report downloaded to: ${directory.path}'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download report: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteReport() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
            SizedBox(width: 12),
            Text('Delete Report?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete this report?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.error.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading indicator
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final reportProvider = context.read<ReportProvider>();
      final success = await reportProvider.deleteReport(widget.report.id);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (success) {
        // Show success message and go back
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(); // Go back to reports list
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  reportProvider.errorMessage ?? 'Failed to delete report'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete report: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareReport,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadReport,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteReport,
            tooltip: 'Delete Report',
          ),
        ],
      ),
      body: _isLoadingHistory
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading test history...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Report Header
                  _buildHeader(context),
                  const SizedBox(height: 24),

                  // Error message if history failed to load
                  if (_historyError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _historyError!,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Test Results Graph (if available)
                  if (_testHistory.isNotEmpty) ...[
                    _buildResultsGraph(context),
                    const SizedBox(height: 24),
                  ],

                  // Test Results Table (if available)
                  if (_testHistory.isNotEmpty) ...[
                    TestResultsTableWidget(testResults: _testHistory),
                    const SizedBox(height: 24),
                  ],

                  // No data message
                  if (_testHistory.isEmpty && _historyError == null) ...[
                    Container(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No test history found',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Upload more reports to see trends and history',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[500],
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.report.testName,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy')
                          .format(widget.report.reportDate),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
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
            'Report Information',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            'Test Type',
            widget.report.testName,
            Icons.medical_services,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            context,
            'Report Date',
            DateFormat('MMMM dd, yyyy').format(widget.report.reportDate),
            Icons.calendar_today,
          ),
          if (widget.report.labName != null) ...[
            const Divider(height: 24),
            _buildInfoRow(
              context,
              'Lab Name',
              widget.report.labName!,
              Icons.business,
            ),
          ],
          if (widget.report.doctorName != null) ...[
            const Divider(height: 24),
            _buildInfoRow(
              context,
              'Doctor',
              widget.report.doctorName!,
              Icons.person,
            ),
          ],
          const Divider(height: 24),
          _buildInfoRow(
            context,
            'Uploaded On',
            DateFormat('MMM dd, yyyy').format(widget.report.uploadedAt),
            Icons.upload,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsGraph(BuildContext context) {
    // Group by parameter name for multiple charts
    Map<String, List<TestResult>> groupedResults = {};
    for (var result in _testHistory) {
      if (!groupedResults.containsKey(result.parameterName)) {
        groupedResults[result.parameterName] = [];
      }
      groupedResults[result.parameterName]!.add(result);
    }

    // Get the first parameter to display (you can make this selectable)
    final firstParameter = groupedResults.keys.first;
    final allResults = groupedResults[firstParameter]!
      ..sort((a, b) => a.testDate.compareTo(b.testDate));
    
    // Filter to only numeric values for chart display
    final results = allResults.where((r) => r.value is num).toList();
    
    // If no numeric results, don't show the trend chart
    if (results.isEmpty) {
      return const SizedBox.shrink();
    }

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
                'Trend Analysis',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton.icon(
                onPressed: () {
                  final firstParameter = _testHistory.first.parameterName;
                  _navigateToFullHistory(firstParameter);
                },
                icon: const Icon(Icons.history, size: 18),
                label: const Text('View History'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            firstParameter,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: GestureDetector(
              onTap: () {
                final firstParameter = _testHistory.first.parameterName;
                _navigateToFullHistory(firstParameter);
              },
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < results.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('MMM dd')
                                    .format(results[value.toInt()].testDate),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: null,
                        reservedSize: 40,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  minX: 0,
                  maxX: (results.length - 1).toDouble(),
                  minY: _getMinY(results),
                  maxY: _getMaxY(results),
                  lineBarsData: [
                    LineChartBarData(
                      spots: results
                          .asMap()
                          .entries
                          .map((e) => FlSpot(
                                e.key.toDouble(),
                                (e.value.value as num).toDouble(),
                              ))
                          .toList(),
                      isCurved: true,
                      gradient: AppColors.primaryGradient,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final status = results[index].status;
                          Color color;
                          switch (status) {
                            case TestStatus.high:
                              color = AppColors.error;
                              break;
                            case TestStatus.low:
                              color = AppColors.warning;
                              break;
                            case TestStatus.normal:
                              color = AppColors.success;
                              break;
                          }
                          return FlDotCirclePainter(
                            radius: 4,
                            color: color,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.1),
                            AppColors.primary.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots.map((barSpot) {
                          final index = barSpot.spotIndex;
                          final result = results[index];
                          return LineTooltipItem(
                            '${result.value} ${result.unit}\n${DateFormat('MMM dd').format(result.testDate)}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Tap graph to view complete history',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsTable(BuildContext context) {
    // Get recent test results (limit to 3 most recent)
    final recentResults = _testHistory
        .where((r) => r.testDate
            .isBefore(widget.report.reportDate.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => b.testDate.compareTo(a.testDate));

    final displayResults = recentResults.take(3).toList();

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
            'Recent Test Results',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                AppColors.primary.withOpacity(0.1),
              ),
              columns: const [
                DataColumn(
                  label: Text(
                    'Date',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Parameter',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Value',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Normal Range',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
              rows: displayResults.map((result) {
                Color statusColor;
                String statusText;
                switch (result.status) {
                  case TestStatus.high:
                    statusColor = AppColors.error;
                    statusText = 'High';
                    break;
                  case TestStatus.low:
                    statusColor = AppColors.warning;
                    statusText = 'Low';
                    break;
                  case TestStatus.normal:
                    statusColor = AppColors.success;
                    statusText = 'Normal';
                    break;
                }

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        DateFormat('MMM dd, yyyy').format(result.testDate),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Text(
                        result.parameterName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${result.value} ${result.unit}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        result.normalMin != null && result.normalMax != null
                            ? '${result.normalMin}-${result.normalMax} ${result.unit}'
                            : 'N/A',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          if (recentResults.length > 3) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  final firstParameter = _testHistory.first.parameterName;
                  _navigateToFullHistory(firstParameter);
                },
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('View Full History'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToFullHistory(String parameterName) {
    final paramResults =
        _testHistory.where((r) => r.parameterName == parameterName).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestHistoryScreen(
          parameterName: parameterName,
          results: paramResults,
        ),
      ),
    );
  }

  /// Calculate minimum Y-axis value for chart with better scaling
  double _getMinY(List<TestResult> results) {
    double min = results.map((r) => (r.value as num).toDouble()).reduce((a, b) => a < b ? a : b);

    // Include normal range in calculation if available
    if (results.first.normalMin != null) {
      min = min < results.first.normalMin! ? min : results.first.normalMin!;
    }

    // Add 10% buffer below minimum, with a minimum range of 20 units
    double buffer = min * 0.1;
    if (buffer < 10) buffer = 10;
    
    return (min - buffer).floorToDouble();
  }

  /// Calculate maximum Y-axis value for chart with better scaling
  double _getMaxY(List<TestResult> results) {
    double max = results.map((r) => (r.value as num).toDouble()).reduce((a, b) => a > b ? a : b);

    // Include normal range in calculation if available
    if (results.first.normalMax != null) {
      max = max > results.first.normalMax! ? max : results.first.normalMax!;
    }

    // Add 10% buffer above maximum, with a minimum range of 20 units
    double buffer = max * 0.1;
    if (buffer < 10) buffer = 10;
    
    return (max + buffer).ceilToDouble();
  }
}
