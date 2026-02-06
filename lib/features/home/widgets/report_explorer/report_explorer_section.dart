import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../reports/models/report_category_model.dart';
import '../../../reports/providers/report_provider.dart';
import '../../../reports/providers/report_explorer_provider.dart';
import 'expandable_category_card.dart';
import 'excel_style_comparison_table.dart';

/// Main Report Explorer Section Widget
class ReportExplorerSection extends StatefulWidget {
  const ReportExplorerSection({super.key});

  @override
  State<ReportExplorerSection> createState() => _ReportExplorerSectionState();
}

class _ReportExplorerSectionState extends State<ReportExplorerSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        _buildSectionHeader(),
        const SizedBox(height: 16),

        // Category Buttons
        _buildCategoryButtons(),
        const SizedBox(height: 16),

        // Report Table (when subcategory is selected)
        _buildReportTable(),
      ],
    );
  }

  /// Build section header
  Widget _buildSectionHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Report Explorer',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Filter, view, and compare your medical reports',
          style: TextStyle(
            fontSize: 13,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Build category buttons
  Widget _buildCategoryButtons() {
    return Consumer<ReportExplorerProvider>(
      builder: (context, explorerProvider, _) {
        return Column(
          children: [
            // Lab Reports Card
            ExpandableCategoryCard(
              title: 'Lab Reports',
              leadingIcon: Icons.science,
              iconColor: const Color(0xFF3B82F6),
              subcategories: LabSubCategory.values
                  .map((subCat) => SubCategoryItem(
                        id: subCat.id,
                        name: subCat.displayName,
                      ))
                  .toList(),
              onSubcategoryTap: (id, name) async {
                // Find the matching subcategory enum
                final subCat = LabSubCategory.values.firstWhere(
                  (e) => e.id == id,
                );

                // Select category and subcategory
                explorerProvider.selectCategory(ReportCategory.lab);
                explorerProvider.selectSubCategory(subCat);

                // Load reports
                final reportProvider = context.read<ReportProvider>();
                await explorerProvider.loadReportsForSubCategory(
                  reportProvider.reports,
                  reportProvider.testResults,
                );
              },
            ),
            const SizedBox(height: 16),

            // Imaging Reports Card
            ExpandableCategoryCard(
              title: 'Imaging Reports',
              leadingIcon: Icons.medical_services,
              iconColor: const Color(0xFF8B5CF6),
              subcategories: ImagingSubCategory.values
                  .map((subCat) => SubCategoryItem(
                        id: subCat.id,
                        name: subCat.displayName,
                      ))
                  .toList(),
              onSubcategoryTap: (id, name) async {
                // Find the matching subcategory enum
                final subCat = ImagingSubCategory.values.firstWhere(
                  (e) => e.id == id,
                );

                // Select category and subcategory
                explorerProvider.selectCategory(ReportCategory.imaging);
                explorerProvider.selectSubCategory(subCat);

                // Load reports
                final reportProvider = context.read<ReportProvider>();
                await explorerProvider.loadReportsForSubCategory(
                  reportProvider.reports,
                  reportProvider.testResults,
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// Build report table section
  Widget _buildReportTable() {
    return Consumer<ReportExplorerProvider>(
      builder: (context, explorerProvider, _) {
        if (explorerProvider.selectedSubCategory == null) {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Excel-Style Comparison Table
              if (explorerProvider.isLoading)
                _buildLoadingState()
              else
                const ExcelStyleComparisonTable(),
            ],
          ),
        );
      },
    );
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: 16),
          Text(
            'Loading reports...',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
