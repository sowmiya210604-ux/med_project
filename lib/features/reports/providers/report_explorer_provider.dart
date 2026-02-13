import 'package:flutter/foundation.dart';
import '../models/report_category_model.dart';
import '../models/report_model.dart';

/// Provider for managing Report Explorer state and comparison logic
class ReportExplorerProvider extends ChangeNotifier {
  // Category selection state
  ReportCategory? _selectedCategory;
  dynamic _selectedSubCategory; // Can be LabSubCategory or ImagingSubCategory
  
  // Comparison state
  bool _isComparisonMode = false;
  final List<String> _selectedReportIdsForComparison = [];
  List<ComparisonResult>? _comparisonResults;

  // Data state
  List<DetailedReportData> _currentReports = [];
  bool _isLoading = false;

  // Getters
  ReportCategory? get selectedCategory => _selectedCategory;
  dynamic get selectedSubCategory => _selectedSubCategory;
  bool get isComparisonMode => _isComparisonMode;
  List<String> get selectedReportIdsForComparison => _selectedReportIdsForComparison;
  List<ComparisonResult>? get comparisonResults => _comparisonResults;
  List<DetailedReportData> get currentReports => _currentReports;
  bool get isLoading => _isLoading;

  /// Check if comparison can be generated (exactly 2 reports selected)
  bool get canGenerateComparison => _selectedReportIdsForComparison.length == 2;

  /// Select a main category
  void selectCategory(ReportCategory? category) {
    if (_selectedCategory == category) {
      // Toggle off if already selected
      _selectedCategory = null;
      _selectedSubCategory = null;
    } else {
      _selectedCategory = category;
      _selectedSubCategory = null;
    }
    
    // Reset comparison mode when changing category
    _resetComparisonState();
    notifyListeners();
  }

  /// Select a subcategory
  void selectSubCategory(dynamic subCategory) {
    if (_selectedSubCategory == subCategory) {
      // Toggle off if already selected
      _selectedSubCategory = null;
      _currentReports = [];
    } else {
      _selectedSubCategory = subCategory;
    }
    
    // Reset comparison mode when changing subcategory
    _resetComparisonState();
    notifyListeners();
  }

  /// Toggle comparison mode
  void toggleComparisonMode() {
    _isComparisonMode = !_isComparisonMode;
    
    if (!_isComparisonMode) {
      // Clear selections when exiting comparison mode
      _selectedReportIdsForComparison.clear();
      _comparisonResults = null;
    }
    
    notifyListeners();
  }

  /// Toggle report selection for comparison
  void toggleReportSelection(String reportId) {
    if (_selectedReportIdsForComparison.contains(reportId)) {
      _selectedReportIdsForComparison.remove(reportId);
    } else {
      // Only allow 2 reports to be selected
      if (_selectedReportIdsForComparison.length < 2) {
        _selectedReportIdsForComparison.add(reportId);
      }
    }
    
    notifyListeners();
  }

  /// Check if a report is selected for comparison
  bool isReportSelectedForComparison(String reportId) {
    return _selectedReportIdsForComparison.contains(reportId);
  }

  /// Load reports for the selected subcategory
  Future<void> loadReportsForSubCategory(
    List<MedicalReport> allReports,
    List<TestResult> allTestResults,
  ) async {
    if (_selectedSubCategory == null) {
      _currentReports = [];
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Get the subcategory name
      String subCategoryName = '';
      List<String> expectedParameters = [];

      if (_selectedSubCategory is LabSubCategory) {
        final labSubCat = _selectedSubCategory as LabSubCategory;
        subCategoryName = labSubCat.displayName;
        expectedParameters = labSubCat.defaultParameters;
      } else if (_selectedSubCategory is ImagingSubCategory) {
        final imagingSubCat = _selectedSubCategory as ImagingSubCategory;
        subCategoryName = imagingSubCat.displayName;
        expectedParameters = imagingSubCat.defaultParameters;
      }

      // Filter reports matching the subcategory
      final matchingReports = allReports.where((report) {
        // Match by test name or test type
        final testNameLower = report.testName.toLowerCase();
        final testTypeLower = report.testType.toLowerCase();
        final subCategoryLower = subCategoryName.toLowerCase();

        return testNameLower.contains(subCategoryLower.toLowerCase()) ||
            testTypeLower.contains(subCategoryLower.toLowerCase()) ||
            _isTestTypeMatch(report.testType, _selectedSubCategory);
      }).toList();

      // Sort by date (newest first)
      matchingReports.sort((a, b) => b.reportDate.compareTo(a.reportDate));

      // Convert to DetailedReportData
      _currentReports = matchingReports.map((report) {
        // Get test results for this report
        final reportTestResults = allTestResults
            .where((result) => result.reportId == report.id)
            .toList();

        // Build parameter map
        final Map<String, ParameterValue> parameters = {};

        if (reportTestResults.isNotEmpty) {
          // Use actual test results
          for (var result in reportTestResults) {
            parameters[result.parameterName] = ParameterValue(
              parameterName: result.parameterName,
              value: result.value,
              unit: result.unit,
              normalMin: result.normalMin,
              normalMax: result.normalMax,
              status: result.status.name,
            );
          }
        } else if (report.testResults != null && report.testResults!.isNotEmpty) {
          // Try to parse from testResults JSON
          report.testResults!.forEach((key, value) {
            if (value is Map<String, dynamic>) {
              parameters[key] = ParameterValue(
                parameterName: key,
                value: value['value'] ?? value['result'] ?? '',
                unit: value['unit']?.toString() ?? '',
                normalMin: value['normalMin']?.toDouble(),
                normalMax: value['normalMax']?.toDouble(),
                status: value['status']?.toString(),
              );
            } else {
              parameters[key] = ParameterValue(
                parameterName: key,
                value: value,
                unit: '',
              );
            }
          });
        }

        // Add placeholder parameters if none exist
        if (parameters.isEmpty) {
          for (var param in expectedParameters) {
            parameters[param] = ParameterValue(
              parameterName: param,
              value: 'N/A',
              unit: '',
            );
          }
        }

        return DetailedReportData(
          reportId: report.id,
          reportDate: report.reportDate,
          parameters: parameters,
          summary: report.extractedText ?? 'No summary available',
        );
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error loading reports for subcategory: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if test type matches the selected subcategory
  bool _isTestTypeMatch(String testType, dynamic subCategory) {
    final testTypeLower = testType.toLowerCase();

    if (subCategory is LabSubCategory) {
      switch (subCategory) {
        case LabSubCategory.cbc:
          return testTypeLower.contains('cbc') || 
                 testTypeLower.contains('complete blood') ||
                 testTypeLower.contains('blood count');
        case LabSubCategory.bloodSugar:
          return testTypeLower.contains('glucose') ||
                 testTypeLower.contains('sugar') ||
                 testTypeLower.contains('hba1c') ||
                 testTypeLower.contains('diabetes') ||
                 testTypeLower.contains('diabetic');
        case LabSubCategory.lipidProfile:
          return testTypeLower.contains('lipid') ||
                 testTypeLower.contains('cholesterol');
        case LabSubCategory.liverFunction:
          return testTypeLower.contains('lft') ||
                 testTypeLower.contains('liver');
        case LabSubCategory.kidneyFunction:
          return testTypeLower.contains('kft') ||
                 testTypeLower.contains('rft') ||
                 testTypeLower.contains('kidney') ||
                 testTypeLower.contains('renal');
        case LabSubCategory.thyroidProfile:
          return testTypeLower.contains('thyroid') ||
                 testTypeLower.contains('tsh') ||
                 testTypeLower.contains('t3') ||
                 testTypeLower.contains('t4');
        case LabSubCategory.urineAnalysis:
          return testTypeLower.contains('urine');
        case LabSubCategory.electrolytes:
          return testTypeLower.contains('electrolyte');
        case LabSubCategory.vitaminTests:
          return testTypeLower.contains('vitamin');
        case LabSubCategory.hormoneTests:
          return testTypeLower.contains('hormone');
        case LabSubCategory.infectionMarkers:
          return testTypeLower.contains('crp') ||
                 testTypeLower.contains('esr') ||
                 testTypeLower.contains('infection');
      }
    } else if (subCategory is ImagingSubCategory) {
      switch (subCategory) {
        case ImagingSubCategory.xray:
          return testTypeLower.contains('x-ray') || testTypeLower.contains('xray');
        case ImagingSubCategory.ctScan:
          return testTypeLower.contains('ct') || testTypeLower.contains('computed tomography');
        case ImagingSubCategory.mri:
          return testTypeLower.contains('mri') || testTypeLower.contains('magnetic resonance');
        case ImagingSubCategory.ultrasound:
          return testTypeLower.contains('ultrasound') || testTypeLower.contains('sonography');
        case ImagingSubCategory.petScan:
          return testTypeLower.contains('pet');
        case ImagingSubCategory.mammogram:
          return testTypeLower.contains('mammogram');
        case ImagingSubCategory.ecgEcho:
          return testTypeLower.contains('ecg') || 
                 testTypeLower.contains('echo') ||
                 testTypeLower.contains('electrocardiogram');
        case ImagingSubCategory.endoscopy:
          return testTypeLower.contains('endoscopy') ||
                 testTypeLower.contains('colonoscopy');
      }
    }

    return false;
  }

  /// Generate comparison between two selected reports
  Future<void> generateComparison() async {
    if (!canGenerateComparison) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Get the two selected reports
      final report1 = _currentReports.firstWhere(
        (r) => r.reportId == _selectedReportIdsForComparison[0],
      );
      final report2 = _currentReports.firstWhere(
        (r) => r.reportId == _selectedReportIdsForComparison[1],
      );

      // Determine which is older (baseline)
      final olderReport = report1.reportDate.isBefore(report2.reportDate) ? report1 : report2;
      final newerReport = report1.reportDate.isBefore(report2.reportDate) ? report2 : report1;

      // Get all unique parameters
      final allParameters = <String>{
        ...olderReport.parameters.keys,
        ...newerReport.parameters.keys,
      };

      // Generate comparison results
      _comparisonResults = allParameters.map((paramName) {
        final oldParam = olderReport.parameters[paramName];
        final newParam = newerReport.parameters[paramName];

        // Handle missing data
        if (oldParam == null || newParam == null) {
          return ComparisonResult(
            parameterName: paramName,
            oldValue: oldParam?.value ?? 'N/A',
            newValue: newParam?.value ?? 'N/A',
            unit: oldParam?.unit ?? newParam?.unit ?? '',
            status: ComparisonStatus.noData,
            description: 'Data not available',
          );
        }

        // Compare values
        final comparisonStatus = _compareValues(oldParam, newParam);
        final description = _generateComparisonDescription(
          paramName,
          oldParam,
          newParam,
          comparisonStatus,
        );

        return ComparisonResult(
          parameterName: paramName,
          oldValue: oldParam.value,
          newValue: newParam.value,
          unit: oldParam.unit,
          status: comparisonStatus,
          description: description,
        );
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error generating comparison: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Compare two parameter values
  ComparisonStatus _compareValues(ParameterValue oldParam, ParameterValue newParam) {
    // If either value is not numeric, can't compare
    if (!oldParam.isNumeric || !newParam.isNumeric) {
      return ComparisonStatus.stable;
    }

    final oldValue = oldParam.numericValue!;
    final newValue = newParam.numericValue!;

    // Calculate percentage change
    final percentChange = ((newValue - oldValue) / oldValue * 100).abs();

    // If change is less than 5%, consider it stable
    if (percentChange < 5) {
      return ComparisonStatus.stable;
    }

    // Check if we have normal range information
    if (oldParam.normalMin != null && oldParam.normalMax != null) {
      final normalMin = oldParam.normalMin!;
      final normalMax = oldParam.normalMax!;

      // Was old value abnormal?
      final oldAbnormal = oldValue < normalMin || oldValue > normalMax;
      final newAbnormal = newValue < normalMin || newValue > normalMax;

      // Improved: was abnormal, now normal or closer to normal
      if (oldAbnormal && !newAbnormal) {
        return ComparisonStatus.improved;
      }

      // Worsened: was normal, now abnormal or further from normal
      if (!oldAbnormal && newAbnormal) {
        return ComparisonStatus.worsened;
      }

      // Both abnormal - check if getting closer to normal
      if (oldAbnormal && newAbnormal) {
        final oldDistance = oldValue < normalMin 
            ? (normalMin - oldValue)
            : (oldValue - normalMax);
        final newDistance = newValue < normalMin
            ? (normalMin - newValue)
            : (newValue - normalMax);

        if (newDistance < oldDistance) {
          return ComparisonStatus.improved;
        } else if (newDistance > oldDistance) {
          return ComparisonStatus.worsened;
        }
      }
    }

    // Simple increase/decrease
    if (newValue > oldValue) {
      return ComparisonStatus.increased;
    } else if (newValue < oldValue) {
      return ComparisonStatus.decreased;
    }

    return ComparisonStatus.stable;
  }

  /// Generate a human-readable comparison description
  String _generateComparisonDescription(
    String paramName,
    ParameterValue oldParam,
    ParameterValue newParam,
    ComparisonStatus status,
  ) {
    if (status == ComparisonStatus.noData) {
      return 'Data not available for comparison';
    }

    if (status == ComparisonStatus.stable) {
      return 'No significant change';
    }

    if (!oldParam.isNumeric || !newParam.isNumeric) {
      return 'Values changed';
    }

    final oldValue = oldParam.numericValue!;
    final newValue = newParam.numericValue!;
    final change = (newValue - oldValue).abs();
    final percentChange = (change / oldValue * 100).toStringAsFixed(1);

    String direction = newValue > oldValue ? 'increased' : 'decreased';

    switch (status) {
      case ComparisonStatus.improved:
        return 'Improved - $direction by $percentChange%';
      case ComparisonStatus.worsened:
        return 'Worsened - $direction by $percentChange%';
      case ComparisonStatus.increased:
        return 'Increased by $percentChange%';
      case ComparisonStatus.decreased:
        return 'Decreased by $percentChange%';
      default:
        return 'No significant change';
    }
  }

  /// Reset comparison state
  void _resetComparisonState() {
    _isComparisonMode = false;
    _selectedReportIdsForComparison.clear();
    _comparisonResults = null;
  }

  /// Clear all selections
  void clearSelection() {
    _selectedCategory = null;
    _selectedSubCategory = null;
    _currentReports = [];
    _resetComparisonState();
    notifyListeners();
  }
}
