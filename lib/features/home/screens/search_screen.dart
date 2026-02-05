import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../reports/screens/test_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _expandedCategory;

  // Test categories and sub-categories data
  final Map<String, List<String>> _testCategories = {
    'Blood Tests': [
      'Complete Blood Count (CBC)',
      'Hemoglobin (Hb)',
      'ESR',
      'Blood Group & Rh Factor',
      'Fasting Blood Sugar (FBS)',
      'Post-Prandial Blood Sugar (PPBS)',
      'Random Blood Sugar (RBS)',
      'HbA1c',
      'Total Cholesterol',
      'HDL',
      'LDL',
      'Triglycerides',
      'Lipid Profile',
    ],
    'Urine Tests': [
      'Urine Routine Examination',
      'Urine Sugar',
      'Urine Ketone',
      'Urine Culture',
      'Micro-albumin Test',
    ],
    'Heart (Cardiac) Tests': [
      'ECG',
      'Echocardiogram (ECHO)',
      'Treadmill Test (TMT)',
      'Troponin Test',
    ],
    'Lung / Respiratory Tests': [
      'Chest X-Ray',
      'Pulmonary Function Test (PFT)',
      'CT Scan (Chest)',
      'Sputum Test',
    ],
    'Brain & Nervous System Tests': [
      'MRI Brain',
      'CT Scan Brain',
      'EEG',
      'Lumbar Puncture (CSF test)',
    ],
    'Thyroid Tests': [
      'TSH',
      'T3',
      'T4',
      'Thyroid Profile',
    ],
    'Liver Function Tests (LFT)': [
      'SGOT (AST)',
      'SGPT (ALT)',
      'Bilirubin',
      'Alkaline Phosphatase',
      'Liver Function Test (Full Panel)',
    ],
    'Kidney / Renal Tests': [
      'Blood Urea',
      'Serum Creatinine',
      'Uric Acid',
      'Electrolytes',
      'Kidney Function Test (KFT)',
    ],
    'Bone & Vitamin Tests': [
      'Vitamin D',
      'Vitamin B12',
      'Calcium',
      'Bone Density Test (DEXA)',
    ],
    'Infection & Immunity Tests': [
      'CRP',
      'Widal',
      'Dengue',
      'Malaria',
      'COVID-19',
      'HIV',
      'Hepatitis B & C',
    ],
    'Cancer-Related Tests': [
      'Biopsy',
      'Tumor Marker Tests',
      'Pap Smear',
      'Mammography',
      'PSA Test',
    ],
    'Hormone Tests': [
      'Insulin Test',
      'Cortisol Test',
      'Estrogen / Testosterone',
      'Prolactin Test',
    ],
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter tests based on search query
  Map<String, List<String>> _getFilteredTests() {
    if (_searchQuery.isEmpty) {
      return _testCategories;
    }

    Map<String, List<String>> filtered = {};
    _testCategories.forEach((category, tests) {
      final matchingTests = tests
          .where((test) =>
              test.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              category.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();

      if (matchingTests.isNotEmpty) {
        filtered[category] = matchingTests;
      }
    });
    return filtered;
  }

  void _onTestTap(String testName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestDetailScreen(testName: testName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTests = _getFilteredTests();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Search Tests'),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),

          // Test Categories List
          Expanded(
            child: filteredTests.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTests.length,
                    itemBuilder: (context, index) {
                      final category = filteredTests.keys.elementAt(index);
                      final tests = filteredTests[category]!;
                      return _buildCategoryCard(category, tests);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search for tests...',
            prefixIcon:
                const Icon(Icons.search, color: AppColors.textSecondary),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon:
                        const Icon(Icons.clear, color: AppColors.textSecondary),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String category, List<String> tests) {
    final isExpanded = _expandedCategory == category;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      elevation: 0,
      child: Column(
        children: [
          // Category Header
          InkWell(
            onTap: () {
              setState(() {
                _expandedCategory = isExpanded ? null : category;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Category Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getCategoryIcon(category),
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Category Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${tests.length} tests',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  // Expand Icon
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Sub-categories (Tests)
          if (isExpanded)
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: tests.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) {
                  final test = tests[index];
                  return _buildTestTile(test);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTestTile(String testName) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      title: Text(
        testName,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.textSecondary,
      ),
      onTap: () => _onTestTap(testName),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No tests found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Blood Tests':
        return Icons.bloodtype;
      case 'Urine Tests':
        return Icons.water_drop;
      case 'Heart (Cardiac) Tests':
        return Icons.favorite;
      case 'Lung / Respiratory Tests':
        return Icons.air;
      case 'Brain & Nervous System Tests':
        return Icons.psychology;
      case 'Thyroid Tests':
        return Icons.medication;
      case 'Liver Function Tests (LFT)':
        return Icons.science;
      case 'Kidney / Renal Tests':
        return Icons.health_and_safety;
      case 'Bone & Vitamin Tests':
        return Icons.fitness_center;
      case 'Infection & Immunity Tests':
        return Icons.shield;
      case 'Cancer-Related Tests':
        return Icons.biotech;
      case 'Hormone Tests':
        return Icons.monitor_heart;
      default:
        return Icons.medical_services;
    }
  }
}
