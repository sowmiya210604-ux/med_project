import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/health_summary_service.dart';
import '../../auth/models/user_model.dart';

class HealthSummaryCard extends StatefulWidget {
  final List<String> healthConditions;
  final User? currentUser;

  const HealthSummaryCard({
    super.key,
    this.healthConditions = const [],
    this.currentUser,
  });

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
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final summary = await HealthSummaryService.getLatestSummary();
      if (!mounted) return;
      setState(() {
        _latestSummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
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
              if (!_isLoading && _latestSummary != null)
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _loadHealthSummary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // User Profile Information
          if (widget.currentUser != null) ...[
            _buildUserInfo(context),
            const Divider(height: 32),
          ],

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
            _buildEmptyState(context)
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

  Widget _buildEmptyState(BuildContext context) {
    return Text(
      'Start tracking your health journey by uploading your first report.',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
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

  Widget _buildUserInfo(BuildContext context) {
    final user = widget.currentUser!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name
        Row(
          children: [
            const Icon(Icons.person, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                user.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Age and Gender
        Row(
          children: [
            if (user.age != null) ...[
              const Icon(Icons.cake_outlined,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                '${user.age} years',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              if (user.gender != null) ...[
                const SizedBox(width: 16),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ],
            if (user.gender != null) ...[
              Icon(
                user.gender?.toLowerCase() == 'male'
                    ? Icons.male
                    : user.gender?.toLowerCase() == 'female'
                        ? Icons.female
                        : Icons.person_outline,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                user.gender!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ],
        ),

        // Medical History (Past History)
        if (user.medicalHistory != null && user.medicalHistory!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.history, size: 16, color: AppColors.warning),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Past History:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.medicalHistory!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],

        // Current Medicines
        if (user.currentMedicines != null &&
            user.currentMedicines!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.medication, size: 16, color: Colors.green),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Medicines:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.currentMedicines!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
