import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../reports/models/test_type_model.dart';

class TestSearchButton extends StatelessWidget {
  final TestType testType;
  final VoidCallback onTap;

  const TestSearchButton({
    super.key,
    required this.testType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconForCategory(testType.category),
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                testType.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Blood Tests':
        return Icons.bloodtype;
      case 'Hormones':
        return Icons.biotech;
      case 'Organ Function':
        return Icons.favorite;
      case 'Vitamins':
        return Icons.local_pharmacy;
      case 'Urine Tests':
        return Icons.science;
      default:
        return Icons.medical_services;
    }
  }
}
