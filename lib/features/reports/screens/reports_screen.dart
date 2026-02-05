import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/filter_widget.dart';
import '../../../core/widgets/animated_card.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../providers/report_provider.dart';
import '../models/report_model.dart';
import 'upload_report_screen.dart';
import 'report_detail_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedCategory = 'All';
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedType;
  String? _selectedStatus;

  final List<String> _categories = [
    'All',
    'Blood Tests',
    'Hormones',
    'Organ Function',
    'Vitamins',
  ];

  @override
  void initState() {
    super.initState();
    // Fetch reports when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().fetchReports();
    });
  }

  final List<String> _reportTypes = [
    'All',
    'Complete Blood Count',
    'Lipid Profile',
    'Blood Glucose',
    'Thyroid Panel',
    'Liver Function',
  ];

  final List<String> _statusOptions = [
    'All',
    'Normal',
    'Abnormal',
    'Critical',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Medical Reports'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_hasActiveFilters())
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter
          _buildCategoryFilter(),

          // Reports List
          Expanded(
            child: Consumer<ReportProvider>(
              builder: (context, reportProvider, _) {
                if (reportProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                // Show error message if fetch failed
                if (reportProvider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load reports',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          reportProvider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            reportProvider.fetchReports();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final reports = reportProvider.reports;

                if (reports.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.folder_open,
                    title: 'No Reports Yet',
                    message: 'Upload your first medical report to get started',
                    actionText: 'Upload Report',
                    onAction: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UploadReportScreen(),
                        ),
                      );
                    },
                  );
                }

                // Apply filters
                final filteredReports = _applyFilters(reports);

                if (filteredReports.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.filter_list_off,
                    title: 'No Matching Reports',
                    message: 'Try adjusting your filters to see more results',
                    actionText: 'Clear Filters',
                    onAction: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                        _selectedType = null;
                        _selectedStatus = null;
                        _selectedCategory = 'All';
                      });
                    },
                  );
                }

                // Group reports by month
                final groupedReports = _groupReportsByMonth(filteredReports);

                return RefreshIndicator(
                  onRefresh: () => reportProvider.fetchReports(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: groupedReports.length,
                    itemBuilder: (context, index) {
                      final entry = groupedReports.entries.elementAt(index);
                      return _buildReportGroup(entry.key, entry.value);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UploadReportScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload Report'),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          return FilterChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedCategory = category;
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

  Map<String, List<MedicalReport>> _groupReportsByMonth(
    List<MedicalReport> reports,
  ) {
    final Map<String, List<MedicalReport>> grouped = {};

    for (final report in reports) {
      final monthYear = DateFormat('MMMM yyyy').format(report.reportDate);
      grouped.putIfAbsent(monthYear, () => []).add(report);
    }

    return grouped;
  }

  Widget _buildReportGroup(String monthYear, List<MedicalReport> reports) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
          child: Text(
            monthYear,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reports.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _buildReportCard(reports[index]);
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildReportCard(MedicalReport report) {
    return AnimatedCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportDetailScreen(report: report),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.description,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.testName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd MMM yyyy').format(report.reportDate),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  if (report.labName != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.business,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          report.labName!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Arrow
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterWidget(
        startDate: _startDate,
        endDate: _endDate,
        selectedType: _selectedType,
        selectedStatus: _selectedStatus,
        availableTypes: _reportTypes,
        availableStatuses: _statusOptions,
        onDateRangeChanged: (start, end) {
          setState(() {
            _startDate = start;
            _endDate = end;
          });
        },
        onTypeChanged: (type) {
          setState(() {
            _selectedType = type;
          });
        },
        onStatusChanged: (status) {
          setState(() {
            _selectedStatus = status;
          });
        },
        onReset: () {
          setState(() {
            _startDate = null;
            _endDate = null;
            _selectedType = null;
            _selectedStatus = null;
          });
        },
      ),
    );
  }

  bool _hasActiveFilters() {
    return _startDate != null ||
        _endDate != null ||
        (_selectedType != null && _selectedType != 'All') ||
        (_selectedStatus != null && _selectedStatus != 'All');
  }

  List<MedicalReport> _applyFilters(List<MedicalReport> reports) {
    var filtered = reports;

    // Filter by date range
    if (_startDate != null) {
      filtered = filtered
          .where((report) => report.reportDate.isAfter(_startDate!))
          .toList();
    }
    if (_endDate != null) {
      filtered = filtered
          .where((report) => report.reportDate.isBefore(_endDate!))
          .toList();
    }

    // Filter by type
    if (_selectedType != null && _selectedType != 'All') {
      filtered =
          filtered.where((report) => report.testName == _selectedType).toList();
    }

    // Filter by category
    if (_selectedCategory != 'All') {
      // You can implement category filtering based on your data structure
      // For now, it's a placeholder
      filtered = filtered
          .where((report) =>
              report.testType.contains(_selectedCategory.toLowerCase()))
          .toList();
    }

    return filtered;
  }
}
