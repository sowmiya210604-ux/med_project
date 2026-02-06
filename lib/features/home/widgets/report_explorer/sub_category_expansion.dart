import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../reports/models/report_category_model.dart';

/// Expandable subcategory widget with smooth animation
class SubCategoryExpansion extends StatelessWidget {
  final dynamic subCategory; // LabSubCategory or ImagingSubCategory
  final bool isSelected;
  final VoidCallback onTap;

  const SubCategoryExpansion({
    super.key,
    required this.subCategory,
    required this.isSelected,
    required this.onTap,
  });

  String get displayName {
    if (subCategory is LabSubCategory) {
      return (subCategory as LabSubCategory).displayName;
    } else if (subCategory is ImagingSubCategory) {
      return (subCategory as ImagingSubCategory).displayName;
    }
    return '';
  }

  IconData get icon {
    if (subCategory is LabSubCategory) {
      final lab = subCategory as LabSubCategory;
      switch (lab) {
        case LabSubCategory.cbc:
          return Icons.water_drop_outlined;
        case LabSubCategory.bloodSugar:
          return Icons.trending_up;
        case LabSubCategory.lipidProfile:
          return Icons.favorite_border;
        case LabSubCategory.liverFunction:
          return Icons.opacity;
        case LabSubCategory.kidneyFunction:
          return Icons.filter_alt_outlined;
        case LabSubCategory.thyroidProfile:
          return Icons.psychology_outlined;
        case LabSubCategory.urineAnalysis:
          return Icons.science_outlined;
        case LabSubCategory.electrolytes:
          return Icons.electric_bolt_outlined;
        case LabSubCategory.vitaminTests:
          return Icons.local_pharmacy_outlined;
        case LabSubCategory.hormoneTests:
          return Icons.healing_outlined;
        case LabSubCategory.infectionMarkers:
          return Icons.coronavirus_outlined;
      }
    } else if (subCategory is ImagingSubCategory) {
      final imaging = subCategory as ImagingSubCategory;
      switch (imaging) {
        case ImagingSubCategory.xray:
          return Icons.spatial_audio_off_outlined;
        case ImagingSubCategory.ctScan:
          return Icons.circle_outlined;
        case ImagingSubCategory.mri:
          return Icons.account_tree_outlined;
        case ImagingSubCategory.ultrasound:
          return Icons.waves_outlined;
        case ImagingSubCategory.petScan:
          return Icons.visibility_outlined;
        case ImagingSubCategory.mammogram:
          return Icons.monitor_heart_outlined;
        case ImagingSubCategory.ecgEcho:
          return Icons.monitor_heart;
        case ImagingSubCategory.endoscopy:
          return Icons.camera_outlined;
      }
    }
    return Icons.label_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? AppColors.primary
                    : const Color(0xFFE5E7EB),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppColors.primary.withOpacity(0.2)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                // Text
                Expanded(
                  child: Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ),
                // Checkmark or arrow
                Icon(
                  isSelected ? Icons.check_circle : Icons.arrow_forward_ios,
                  size: isSelected ? 20 : 16,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
