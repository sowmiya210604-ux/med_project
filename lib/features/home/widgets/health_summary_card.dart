import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/health_summary_service.dart';

class HealthSummaryCard extends StatefulWidget {
  final List<String> healthConditions;

  const HealthSummaryCard({super.key, this.healthConditions = const []});

  @override
  State<HealthSummaryCard> createState() => _HealthSummaryCardState();
}

class _HealthSummaryCardState extends State<HealthSummaryCard> {
  Map<String, dynamic>? _latestSummary;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHealthSummary();
  }

  Future<void> _loadHealthSummary() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final summary = await HealthSummaryService.getLatestSummary();
      setState(() {
        _latestSummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Health Summary',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (!_isLoading)
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _loadHealthSummary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            Text(
              'Unable to load health summary',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            )
          else if (_latestSummary == null)
            Text(
              'No health summary available yet. Upload your medical reports to get personalized health insights.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            )
          else ...[
            // Overall Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(_latestSummary!['overallStatus'])
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getStatusColor(_latestSummary!['overallStatus']),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStatusIcon(_latestSummary!['overallStatus']),
                    size: 16,
                    color: _getStatusColor(_latestSummary!['overallStatus']),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _latestSummary!['overallStatus'],
                    style: TextStyle(
                      color: _getStatusColor(_latestSummary!['overallStatus']),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Risk Level
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 18, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Risk Level: ${_latestSummary!['riskLevel']}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Abnormal Count
            if (_latestSummary!['abnormalCount'] > 0)
              Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 18, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text(
                    '${_latestSummary!['abnormalCount']} abnormal result(s) detected',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.error,
                        ),
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // Summary Text
            Text(
              _latestSummary!['summaryText']?.split('\n').first ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'NORMAL':
        return Colors.green;
      case 'CAUTION':
        return Colors.orange;
      case 'CRITICAL':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'NORMAL':
        return Icons.check_circle;
      case 'CAUTION':
        return Icons.warning;
      case 'CRITICAL':
        return Icons.error;
      default:
        return Icons.info;
    }
  }
}
