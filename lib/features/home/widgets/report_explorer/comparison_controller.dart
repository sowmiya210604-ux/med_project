import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Comparison controller widget with buttons for compare mode
class ComparisonController extends StatelessWidget {
  final bool isComparisonMode;
  final int selectedCount;
  final bool canGenerate;
  final VoidCallback onToggleComparisonMode;
  final VoidCallback onGenerateComparison;
  final VoidCallback? onClearComparison;

  const ComparisonController({
    super.key,
    required this.isComparisonMode,
    required this.selectedCount,
    required this.canGenerate,
    required this.onToggleComparisonMode,
    required this.onGenerateComparison,
    this.onClearComparison,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isComparisonMode ? AppColors.primary : const Color(0xFFE5E7EB),
          width: isComparisonMode ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Row(
            children: [
              Icon(
                Icons.compare_arrows,
                color: isComparisonMode ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Compare Reports',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isComparisonMode ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Instructions or status
          _buildStatusMessage(),

          const SizedBox(height: 16),

          // Buttons
          Row(
            children: [
              // Toggle comparison mode button
              Expanded(
                child: _buildButton(
                  label: isComparisonMode ? 'Cancel' : 'Start Comparing',
                  icon: isComparisonMode ? Icons.close : Icons.compare,
                  onPressed: onToggleComparisonMode,
                  isPrimary: !isComparisonMode,
                  isOutline: isComparisonMode,
                ),
              ),

              if (isComparisonMode && canGenerate) ...[
                const SizedBox(width: 12),
                // Generate comparison button
                Expanded(
                  child: _buildButton(
                    label: 'Generate',
                    icon: Icons.analytics,
                    onPressed: onGenerateComparison,
                    isPrimary: true,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Build status message
  Widget _buildStatusMessage() {
    String message;
    Color color;
    IconData icon;

    if (!isComparisonMode) {
      message = 'Select two reports to compare side by side';
      color = AppColors.textSecondary;
      icon = Icons.info_outline;
    } else if (selectedCount == 0) {
      message = 'Select 2 reports from the table above';
      color = Colors.orange;
      icon = Icons.touch_app;
    } else if (selectedCount == 1) {
      message = 'Select 1 more report to compare';
      color = Colors.blue;
      icon = Icons.check_circle_outline;
    } else if (selectedCount == 2) {
      message = 'Ready! Click Generate to see comparison';
      color = Colors.green;
      icon = Icons.check_circle;
    } else {
      message = 'Maximum 2 reports can be selected';
      color = Colors.red;
      icon = Icons.error_outline;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a button
  Widget _buildButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool isPrimary = false,
    bool isOutline = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: isPrimary
            ? Colors.white
            : (isOutline ? AppColors.primary : AppColors.textPrimary),
        backgroundColor: isPrimary
            ? AppColors.primary
            : (isOutline ? Colors.white : AppColors.background),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isOutline
              ? const BorderSide(color: AppColors.primary, width: 2)
              : BorderSide.none,
        ),
        elevation: isPrimary ? 2 : 0,
      ),
    );
  }
}
