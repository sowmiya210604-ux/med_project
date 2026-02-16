import 'package:flutter/foundation.dart';
import '../models/report_model.dart';
import '../../../core/services/health_analysis_service.dart';
import '../../../core/services/http_service.dart';
import '../../../core/config/api_config.dart';
import '../../../core/utils/storage_helper.dart';

// Background isolate function for heavy JSON parsing
List<MedicalReport> _parseReportsInBackground(Map<String, dynamic> response) {
  if (response['reports'] == null) return [];

  final reportsList = response['reports'] as List;
  return reportsList.map((json) => MedicalReport.fromJson(json)).toList();
}

List<TestResult> _parseTestResultsInBackground(List<dynamic> reportsData) {
  final testResults = <TestResult>[];

  for (var report in reportsData) {
    if (report['testResults'] != null && report['testResults'] is List) {
      final testResultsData = report['testResults'] as List;
      for (var testResult in testResultsData) {
        testResults.add(TestResult.fromJson(testResult));
      }
    }
  }

  return testResults;
}

class ReportProvider extends ChangeNotifier {
  List<MedicalReport> _reports = [];
  List<TestResult> _testResults = [];
  List<String> _healthConditions = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastFetchTime;
  static const _cacheDuration = Duration(minutes: 5);

  // Schema-based extraction results
  Map<String, dynamic>? _analysisResult;
  bool _requiresManualEntry = false;

  List<MedicalReport> get reports => _reports;
  List<TestResult> get testResults => _testResults;
  List<String> get healthConditions => _healthConditions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get analysisResult => _analysisResult;
  bool get requiresManualEntry => _requiresManualEntry;

  // Check if cache is still valid
  bool get _isCacheValid {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheDuration;
  }

  // Fetch all reports
  Future<void> fetchReports({bool forceRefresh = false}) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && _isCacheValid && _reports.isNotEmpty) {
      print('✅ Using cached reports data');
      return;
    }

    _isLoading = true;
    _errorMessage = null; // Clear previous errors
    notifyListeners();

    try {
      // Call backend API to fetch reports
      final response = await HttpService.get(
        ApiConfig.reportUrl,
        requiresAuth: true,
      );

      // Parse reports in background isolate to avoid blocking UI
      if (response['reports'] != null) {
        final reportsList = response['reports'] as List;

        // Use compute for heavy parsing operations
        _reports = await compute(_parseReportsInBackground, response);
        _testResults =
            await compute(_parseTestResultsInBackground, reportsList);
      } else {
        // Empty response is valid - no reports yet
        _reports = [];
        _testResults = [];
      }

      // Update cache timestamp
      _lastFetchTime = DateTime.now();

      // Analyze health conditions from reports
      _analyzeHealthConditions();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Failed to fetch reports: $e');
      _errorMessage = 'Failed to fetch reports: $e';
      _isLoading = false;
      notifyListeners();
      // Don't rethrow - error is stored in _errorMessage for UI to handle
    }
  }

  // Delete report
  Future<bool> deleteReport(String reportId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Call backend API to delete report
      await HttpService.delete(
        '${ApiConfig.reportUrl}/$reportId',
        requiresAuth: true,
      );

      // Remove report from local list
      _reports.removeWhere((report) => report.id == reportId);

      // Remove associated test results
      _testResults.removeWhere((result) => result.reportId == reportId);

      // Re-analyze health conditions
      _analyzeHealthConditions();

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      print('❌ Failed to delete report: $e');
      _errorMessage = 'Failed to delete report: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Upload new report using schema-based extraction
  Future<bool> uploadReport({
    required String testType,
    required String testName,
    required DateTime reportDate,
    String? imagePath,
    String? extractedText,
    Map<String, dynamic>? testResults,
  }) async {
    _isLoading = true;
    _analysisResult = null;
    _requiresManualEntry = false;
    notifyListeners();

    try {
      // Check if user is authenticated
      final token = await StorageHelper.getToken();
      if (token == null || token.isEmpty) {
        _errorMessage = 'Not authenticated. Please login first.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      print('🚀 Analyzing report with schema-based extraction:');
      print('   OCR Text Length: ${extractedText?.length ?? 0} chars');
      print('   Report Date: $reportDate');

      // Step 1: Call /api/extraction/analyze
      final analyzeResponse = await HttpService.post(
        '${ApiConfig.extractionUrl}/analyze',
        {
          'ocrText': extractedText ?? '',
          'reportDate': reportDate.toIso8601String(),
        },
        requiresAuth: true,
      );

      print('✅ Analysis response received');
      print('   Success: ${analyzeResponse['success']}');
      print('   Analysis Complete: ${analyzeResponse['analysisComplete']}');
      print('   Requires Manual Entry: ${analyzeResponse['requiresManualEntry']}');

      // Store analysis result
      _analysisResult = analyzeResponse;

      // Check if analysis was successful
      if (analyzeResponse['analysisComplete'] == true &&
          analyzeResponse['success'] == true) {
        // Extraction successful - preview available
        print('✅ Extraction successful!');
        print('   Report Type: ${analyzeResponse['reportType']}');
        print('   Home Category: ${analyzeResponse['homeCategory']}');
        print('   Parameters: ${analyzeResponse['totalParameters']}');
        print('   Confidence: ${analyzeResponse['confidence']}');

        // Step 2: Automatically confirm and save (or you can show preview first)
        final confirmSuccess = await confirmAndSaveReport(
          reportType: analyzeResponse['reportType'],
          reportDate: reportDate,
          parameters: analyzeResponse['parameters'] ?? [],
          extractedText: extractedText,
        );

        _isLoading = false;
        notifyListeners();
        return confirmSuccess;
      } else if (analyzeResponse['requiresManualEntry'] == true) {
        // Manual entry required
        print('⚠️ Manual entry required');
        print('   Message: ${analyzeResponse['message']}');
        _requiresManualEntry = true;
        _errorMessage = analyzeResponse['message'] ??
            'Unable to extract data. Please enter manually.';
        _isLoading = false;
        notifyListeners();
        return false;
      } else {
        // Unknown error
        _errorMessage = 'Failed to analyze report. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Error uploading report: $e');
      _errorMessage = 'Failed to upload report: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Confirm and save analyzed report
  Future<bool> confirmAndSaveReport({
    required String reportType,
    required DateTime reportDate,
    required List<dynamic> parameters,
    String? extractedText,
  }) async {
    try {
      print('💾 Confirming and saving report...');
      print('   Report Type: $reportType');
      print('   Parameters: ${parameters.length}');
      print('   OCR Text: ${extractedText != null ? 'Present (${extractedText.length} chars)' : 'Not provided'}');

      final response = await HttpService.post(
        '${ApiConfig.extractionUrl}/confirm-save',
        {
          'reportType': reportType,
          'reportDate': reportDate.toIso8601String(),
          'parameters': parameters,
          'ocrText': extractedText,
        },
        requiresAuth: true,
      );

      print('✅ Report saved successfully');

      // Get the created report from response
      if (response['report'] != null) {
        final reportData = response['report'];

        // Fetch fresh report data to get test results
        await fetchReports(forceRefresh: true);
      }

      // Re-analyze health conditions
      _analyzeHealthConditions();

      return true;
    } catch (e) {
      print('❌ Error saving report: $e');
      _errorMessage = 'Failed to save report: $e';
      return false;
    }
  }

  // Manual save for when extraction fails
  Future<bool> manualSaveReport({
    required String reportName,
    required String homeCategory,
    required DateTime reportDate,
    required List<Map<String, dynamic>> parameters,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      print('✍️ Manually saving report...');
      print('   Report Name: $reportName');
      print('   Home Category: $homeCategory');
      print('   Parameters: ${parameters.length}');

      final response = await HttpService.post(
        '${ApiConfig.extractionUrl}/manual-save',
        {
          'reportName': reportName,
          'homeCategory': homeCategory,
          'reportDate': reportDate.toIso8601String(),
          'parameters': parameters,
        },
        requiresAuth: true,
      );

      print('✅ Manual report saved successfully');

      // Fetch fresh report data
      await fetchReports(forceRefresh: true);

      // Re-analyze health conditions
      _analyzeHealthConditions();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error manually saving report: $e');
      _errorMessage = 'Failed to save manual report: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Extract test data from OCR text
  List<Map<String, dynamic>> _extractTestDataFromText(String text) {
    final List<Map<String, dynamic>> results = [];
    final lines = text.split('\n');

    print('📝 OCR Text to analyze (${lines.length} lines):');
    print('${text.substring(0, text.length > 200 ? 200 : text.length)}...');

    // First try columnar format (KKC LAB style with TEST/RESULT columns)
    final columnarResults = _extractColumnarFormat(text);
    if (columnarResults.isNotEmpty) {
      print('✅ Extracted ${columnarResults.length} results using columnar format');
      return columnarResults;
    }

    // Then try Labsmart format (for Labsmart Software PDFs)
    final labsmartResults = _extractLabsmartFormat(text);
    if (labsmartResults.isNotEmpty) {
      print('✅ Extracted ${labsmartResults.length} results using Labsmart format');
      return labsmartResults;
    }

    // Then try to extract using table-like format (parameter  value)
    // This handles OCR text where parameters and values are space-separated
    final tableResults = _extractFromTableFormat(text);
    if (tableResults.isNotEmpty) {
      print('✅ Extracted ${tableResults.length} results using table format');
      return tableResults;
    }

    // Comprehensive test parameter patterns for various lab report formats
    final patterns = [
      // Thyroid Tests - handles various formats like "T3, Total", "TSH - Ultra Sensitive", etc.
      RegExp(
          r'(?:TSH|Thyroid\s+Stimulating\s+Hormone)(?:\s*-\s*Ultra\s+Sensitive)?(?:\s*\(TSH\))?\s*[:\s]*([\d.]+)\s*(mIU/L|µIU/mL|uIU/mL|uIU/ml)?',
          caseSensitive: false),
      RegExp(
          r'(?:T3|TT3|Triiodothyronine)(?:,?\s*Total)?(?:\s*\(TT3\))?\s*[:\s]*([\d.]+)\s*(ng/dL|ng/mL|nmol/L|ng/dl|ng/ml)?',
          caseSensitive: false),
      RegExp(
          r'(?:T4|TT4|Thyroxine)(?:,?\s*Total)?(?:\s*\(TT4\))?\s*[:\s]*([\d.]+)\s*(µg/dL|µg/L|ug/dL|ug/L|pmol/L)?',
          caseSensitive: false),

      // Blood Sugar Tests - includes ABG, HbA1c with method notation
      RegExp(
          r'(?:GLUCOSE\s+FASTING|Fasting\s+Glucose|Glucose\s+Fasting|Blood\s+Sugar\s+Fasting|FBS|BSF)(?:\s*\(BSF\))?\s*[:\s]*([\d.]+)\s*(mg/dL|mg/dl)?',
          caseSensitive: false),
      RegExp(
          r'(?:AVERAGE\s+BLOOD\s+GLUCOSE|ABG)(?:\s*\(ABG\))?(?:\s+CALCULATED)?\s*[:\s]*([\d.]+)\s*(mg/dL|mg/dl)?',
          caseSensitive: false),
      RegExp(
          r'(?:HbA1c|A1C|H\.P\.L\.C|Glycated\s+Hemoglobin)(?:\s*-?\s*\(HPLC\s*-?\s*NGSP\s+Certified\))?\s*[:\s]*([\d.]+)\s*(%)?',
          caseSensitive: false),

      // Blood Count
      RegExp(
          r'(?:Hemoglobin|Haemoglobin|Hb|HGB)\s*[:\s]*([\d.]+)\s*(g/dL|g/dl|mg/dL)?',
          caseSensitive: false),
      RegExp(
          r'(?:RBC|Red\s+Blood\s+Cell(?:\s+Count)?)\s*[:\s]*([\d.]+)\s*(million/µL|million/uL|M/µL|M/uL)?',
          caseSensitive: false),
      RegExp(
          r'(?:WBC|White\s+Blood\s+Cell(?:\s+Count)?)\s*[:\s]*([\d.]+)\s*(cells/µL|cells/uL|K/µL|K/uL|thousands/µL)?',
          caseSensitive: false),
      RegExp(
          r'(?:Platelet(?:s)?(?:\s+Count)?|PLT)\s*[:\s]*([\d.]+)\s*(thousands/µL|thousands/uL|K/µL|lakhs/µL|lakh/µL)?',
          caseSensitive: false),

      // Kidney Function Tests - comprehensive patterns
      RegExp(
          r'(?:SERUM\s+CREATININE|Creatinine\s*\(Serum\)|Creatinine|CREAT)(?:\s*\([^)]+\))?\s*[:\s]*([\d.]+)\s*(mg/dL|mg/dl)?',
          caseSensitive: false),
      RegExp(
          r'(?:SERUM\s+UREA|Urea\s*\(Serum\)|Urea)(?:\s*\([^)]+\))?\s*[:\s]*([\d.]+)\s*(mg/dL|mg/dl)?',
          caseSensitive: false),
      RegExp(
          r'(?:BUN|Blood\s+Urea\s+Nitrogen)\s*[:\s]*([\d.]+)\s*(mg/dL|mg/dl)?',
          caseSensitive: false),
      RegExp(
          r'(?:SERUM\s+URIC\s+ACID|Uric\s+Acid|Urate)(?:\s*\([^)]+\))?\s*[:\s]*([\d.]+)\s*(mg/dL|mg/dl)?',
          caseSensitive: false),
      RegExp(
          r'(?:eGFR|EGFR|GFR)(?:\s+CATEGORY)?(?:\s*\([^)]+\))?\s*[:\s]*([L\s]*)?([\d.]+)\s*(ml/min(?:/1\.73m(?:\^)?2)?|mL/min(?:/1\.73m(?:\^)?2)?)?',
          caseSensitive: false),

      // Electrolytes
      RegExp(
          r'(?:SERUM\s+CALCIUM|Calcium)(?:\s*\([^)]+\))?\s*[:\s]*([\d.]+)\s*(mg/dL|mg/dl|mmol/L)?',
          caseSensitive: false),
      RegExp(
          r'(?:SERUM\s+POTASSIUM|Potassium)(?:\s*\([^)]+\))?\s*[:\s]*([\d.]+)\s*(mEq/L|mmol/L)?',
          caseSensitive: false),
      RegExp(
          r'(?:SERUM\s+SODIUM|Sodium)(?:\s*\([^)]+\))?\s*[:\s]*([\d.]+)\s*(mEq/L|mmol/L)?',
          caseSensitive: false),
      RegExp(
          r'(?:Chloride)(?:\s*\([^)]+\))?\s*[:\s]*([\d.]+)\s*(mEq/L|mmol/L)?',
          caseSensitive: false),
      RegExp(
          r'(?:Phosphorus)(?:\s*\([^)]+\))?\s*[:\s]*([\d.]+)\s*(mg/dL|mg/dl)?',
          caseSensitive: false),

      // Liver & Other Tests
      RegExp(
          r'(?:Alkaline\s+Phosphatase|ALP)(?:\s*\([^)]+\))?\s*[:\s]*([\d.]+)\s*(U/L|IU/L)?',
          caseSensitive: false),
      RegExp(r'(?:ALT|SGPT)\s*[:\s]*([\d.]+)\s*(U/L|IU/L)?',
          caseSensitive: false),
      RegExp(r'(?:AST|SGOT)\s*[:\s]*([\d.]+)\s*(U/L|IU/L)?',
          caseSensitive: false),
      RegExp(
          r'(?:Total\s+Protein)(?:\s*\([^)]+\))?\s*[:\s]*([\d.]+)\s*(g/dL|g/dl)?',
          caseSensitive: false),
      RegExp(r'(?:Albumin)(?:\s*\([^)]+\))?\s*[:\s]*([\d.]+)\s*(g/dL|g/dl)?',
          caseSensitive: false),

      // Lipid Profile
      RegExp(
          r'(?:Total\s+Cholesterol|Cholesterol|CHOL)\s*[:\s]*([\d.]+)\s*(mg/dL|mg/dl)?',
          caseSensitive: false),
      RegExp(r'(?:HDL(?:\s+Cholesterol)?)\s*[:\s]*([\d.]+)\s*(mg/dL|mg/dl)?',
          caseSensitive: false),
      RegExp(r'(?:LDL(?:\s+Cholesterol)?)\s*[:\s]*([\d.]+)\s*(mg/dL|mg/dl)?',
          caseSensitive: false),
      RegExp(r'(?:Triglycerides|TG)\s*[:\s]*([\d.]+)\s*(mg/dL|mg/dl)?',
          caseSensitive: false),
    ];

    for (var line in lines) {
      for (var pattern in patterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          // Extract parameter name from the line (simplify long names)
          var parameterName = '';
          final lowerLine = line.toLowerCase();

          if (lowerLine.contains('tsh') ||
              lowerLine.contains('thyroid stimulating')) {
            parameterName = 'TSH';
          } else if (lowerLine.contains('tt3') ||
              lowerLine.contains('triiodothyronine') ||
              lowerLine.contains('t3')) {
            parameterName = 'T3';
          } else if (lowerLine.contains('tt4') ||
              lowerLine.contains('thyroxine') ||
              lowerLine.contains('t4')) {
            parameterName = 'T4';
          } else if (lowerLine.contains('average blood glucose') ||
              lowerLine.contains('abg')) {
            parameterName = 'Average Blood Glucose';
          } else if (lowerLine.contains('glucose') ||
              lowerLine.contains('blood sugar')) {
            parameterName = 'Glucose';
          } else if (lowerLine.contains('hba1c') ||
              lowerLine.contains('a1c') ||
              lowerLine.contains('h.p.l.c')) {
            parameterName = 'HbA1c';
          } else if (lowerLine.contains('hemoglobin') ||
              lowerLine.contains('haemoglobin')) {
            parameterName = 'Hemoglobin';
          } else if (lowerLine.contains('serum creatinine') ||
              lowerLine.contains('creatinine')) {
            parameterName = 'Creatinine';
          } else if (lowerLine.contains('serum urea') ||
              (lowerLine.contains('urea') && !lowerLine.contains('bun'))) {
            parameterName = 'Urea';
          } else if (lowerLine.contains('bun') ||
              lowerLine.contains('blood urea nitrogen')) {
            parameterName = 'BUN';
          } else if (lowerLine.contains('uric acid') ||
              lowerLine.contains('urate')) {
            parameterName = 'Uric Acid';
          } else if (lowerLine.contains('egfr') || lowerLine.contains('gfr')) {
            parameterName = 'eGFR';
          } else if (lowerLine.contains('serum calcium') ||
              (lowerLine.contains('calcium') &&
                  !lowerLine.contains('phosph'))) {
            parameterName = 'Calcium';
          } else if (lowerLine.contains('serum potassium') ||
              lowerLine.contains('potassium')) {
            parameterName = 'Potassium';
          } else if (lowerLine.contains('serum sodium') ||
              lowerLine.contains('sodium')) {
            parameterName = 'Sodium';
          } else if (lowerLine.contains('chloride')) {
            parameterName = 'Chloride';
          } else if (lowerLine.contains('phosphorus') ||
              lowerLine.contains('phosphate')) {
            parameterName = 'Phosphorus';
          } else if (lowerLine.contains('alkaline phosphatase') ||
              lowerLine.contains('alp')) {
            parameterName = 'Alkaline Phosphatase';
          } else if (lowerLine.contains('total protein')) {
            parameterName = 'Total Protein';
          } else if (lowerLine.contains('albumin')) {
            parameterName = 'Albumin';
          } else if (lowerLine.contains('cholesterol') &&
              lowerLine.contains('hdl')) {
            parameterName = 'HDL Cholesterol';
          } else if (lowerLine.contains('cholesterol') &&
              lowerLine.contains('ldl')) {
            parameterName = 'LDL Cholesterol';
          } else if (lowerLine.contains('cholesterol')) {
            parameterName = 'Cholesterol';
          } else if (lowerLine.contains('triglycerides')) {
            parameterName = 'Triglycerides';
          } else if (lowerLine.contains('rbc')) {
            parameterName = 'RBC';
          } else if (lowerLine.contains('wbc')) {
            parameterName = 'WBC';
          } else if (lowerLine.contains('platelet')) {
            parameterName = 'Platelets';
          } else if (lowerLine.contains('alt') || lowerLine.contains('sgpt')) {
            parameterName = 'ALT';
          } else if (lowerLine.contains('ast') || lowerLine.contains('sgot')) {
            parameterName = 'AST';
          }

          // Handle EGFR special case where it may have "L" prefix
          var value = '';
          var unit = '';
          if (parameterName == 'eGFR' &&
              match.groupCount >= 3 &&
              match.group(1) != null &&
              match.group(1)!.contains('L')) {
            value = match.group(2) ?? '';
            unit = match.group(3) ?? '';
          } else {
            value = match.group(1) ?? '';
            unit = match.group(2) ?? '';
          }

          print('✅ Extracted: $parameterName = $value $unit');

          // Determine status based on value and parameter
          final status =
              _determineStatus(parameterName, double.tryParse(value) ?? 0);

          final normalRanges = _getNormalRange(parameterName);

          // Determine test category and subcategory
          String testCategory = 'Blood Test';
          String testSubCategory = parameterName;

          if (parameterName == 'TSH' ||
              parameterName == 'T3' ||
              parameterName == 'T4') {
            testCategory = 'Thyroid Test';
            testSubCategory = 'Thyroid';
          } else if (parameterName == 'Glucose' ||
              parameterName == 'HbA1c' ||
              parameterName == 'Average Blood Glucose') {
            testCategory = 'Blood Sugar Test';
            testSubCategory = 'Glucose';
          } else if (parameterName == 'Hemoglobin' ||
              parameterName == 'RBC' ||
              parameterName == 'WBC' ||
              parameterName == 'Platelets') {
            testCategory = 'Complete Blood Count';
            testSubCategory = 'CBC';
          } else if (parameterName == 'Cholesterol' ||
              parameterName == 'HDL Cholesterol' ||
              parameterName == 'LDL Cholesterol' ||
              parameterName == 'Triglycerides') {
            testCategory = 'Lipid Profile';
            testSubCategory = 'Lipids';
          } else if (parameterName == 'Creatinine' ||
              parameterName == 'Urea' ||
              parameterName == 'BUN' ||
              parameterName == 'Uric Acid' ||
              parameterName == 'eGFR') {
            testCategory = 'Kidney Function Test';
            testSubCategory = 'Renal';
          } else if (parameterName == 'Calcium' ||
              parameterName == 'Potassium' ||
              parameterName == 'Sodium' ||
              parameterName == 'Chloride' ||
              parameterName == 'Phosphorus') {
            testCategory = 'Electrolytes';
            testSubCategory = 'Minerals';
          } else if (parameterName == 'ALT' ||
              parameterName == 'AST' ||
              parameterName == 'Alkaline Phosphatase' ||
              parameterName == 'Total Protein' ||
              parameterName == 'Albumin') {
            testCategory = 'Liver Function Test';
            testSubCategory = 'Hepatic';
          }

          results.add({
            'testName': testCategory,
            'testCategory': testCategory,
            'testSubCategory': testSubCategory,
            'parameterName': parameterName,
            'value': value,
            'unit': unit.isNotEmpty ? unit : 'N/A',
            'status': status,
            'referenceRange': _getReferenceRange(parameterName),
            'normalMin': normalRanges['min'],
            'normalMax': normalRanges['max'],
          });
        }
      }
    }

    print('📊 Total extracted test results: ${results.length}');
    return results;
  }

  // Extract test data from columnar format (e.g., KKC LAB format)
  // Handles layouts where TEST, RESULT, UNITS, REFERENCE RANGE are in columns
  List<Map<String, dynamic>> _extractColumnarFormat(String text) {
    final results = <Map<String, dynamic>>[];
    final lines = text.split('\n');

    print('🔍 Trying columnar format extraction...');

    // Find test names and their values
    final testNames = <String>[];
    final testValues = <String>[];
    final testUnits = <String>[];
    final testReferences = <String>[];

    // Known test parameter mapping
    final testMapping = {
      'blood sugar(fasting)': 'Fasting Glucose',
      'blood sugar (fasting)': 'Fasting Glucose',
      'fasting glucose': 'Fasting Glucose',
      'blood sugar(post prandial)': 'Post Prandial Glucose',
      'blood sugar (post prandial)': 'Post Prandial Glucose',
      'post prandial': 'Post Prandial Glucose',
      'blood pressure': 'Blood Pressure',
      'bp': 'Blood Pressure',
      'pulse': 'Pulse Rate',
      'hemoglobin': 'Hemoglobin',
      'hb': 'Hemoglobin',
      'cholesterol': 'Total Cholesterol',
      'triglycerides': 'Triglycerides',
      'hdl': 'HDL Cholesterol',
      'ldl': 'LDL Cholesterol',
      'creatinine': 'Creatinine',
      'urea': 'Blood Urea',
      'uric acid': 'Uric Acid',
    };

    bool inResultSection = false;
    bool inUnitsSection = false;
    bool inReferenceSection = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim().toLowerCase();
      
      // Skip empty lines
      if (line.isEmpty) continue;

      // Detect section transitions
      if (line.contains('result') && !line.contains('test')) {
        inResultSection = true;
        inUnitsSection = false;
        inReferenceSection = false;
        continue;
      } else if (line.contains('unit')) {
        inResultSection = false;
        inUnitsSection = true;
        inReferenceSection = false;
        continue;
      } else if (line.contains('reference') || line.contains('range')) {
        inResultSection = false;
        inUnitsSection = false;
        inReferenceSection = true;
        continue;
      }

      // Extract test names (look for known test patterns)
      for (var entry in testMapping.entries) {
        if (line.contains(entry.key)) {
          testNames.add(entry.value);
          print('  Found test: ${entry.value}');
          break;
        }
      }

      // Extract numeric values when in result section
      if (inResultSection) {
        final numPattern = RegExp(r'^\d+\.?\d*$');
        if (numPattern.hasMatch(line)) {
          testValues.add(line);
          print('  Found value: $line');
        }
      }

      // Extract units
      if (inUnitsSection) {
        if (line.contains('mg/dl') || line.contains('mg/l') || 
            line.contains('mm of hg') || line.contains('per/min') ||
            line.contains('g/dl') || line.contains('%')) {
          testUnits.add(line);
          print('  Found unit: $line');
        }
      }

      // Extract reference ranges
      if (inReferenceSection) {
        final rangePattern = RegExp(r'\d+\s*-\s*\d+');
        if (rangePattern.hasMatch(line)) {
          testReferences.add(line);
          print('  Found reference: $line');
        }
      }
    }

    // Try alternative approach: look for test-value pairs by proximity
    if (testNames.isEmpty || testValues.isEmpty) {
      print('  Trying proximity-based extraction...');
      
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim().toLowerCase();
        
        // Check if line contains a known test name
        String? foundTest;
        for (var entry in testMapping.entries) {
          if (line.contains(entry.key)) {
            foundTest = entry.value;
            break;
          }
        }
        
        if (foundTest != null) {
          // Look ahead for numeric value
          for (int j = i + 1; j < lines.length && j < i + 15; j++) {
            final nextLine = lines[j].trim();
            final numPattern = RegExp(r'^\d+\.?\d*$');
            
            if (numPattern.hasMatch(nextLine)) {
              testNames.add(foundTest);
              testValues.add(nextLine);
              print('  Proximity match: $foundTest = $nextLine');
              
              // Look for unit
              String unit = 'N/A';
              for (int k = j + 1; k < lines.length && k < j + 10; k++) {
                final unitLine = lines[k].trim().toLowerCase();
                if (unitLine.contains('mg/dl')) {
                  unit = 'mg/dl';
                  break;
                } else if (unitLine.contains('mm of hg')) {
                  unit = 'mm Hg';
                  break;
                } else if (unitLine.contains('per/min')) {
                  unit = 'per/min';
                  break;
                }
              }
              testUnits.add(unit);
              break;
            }
          }
        }
      }
    }

    // Match test names with values and create results
    final minLength = [testNames.length, testValues.length].reduce((a, b) => a < b ? a : b);
    
    for (int i = 0; i < minLength; i++) {
      final testName = testNames[i];
      final value = testValues[i];
      final unit = i < testUnits.length ? testUnits[i] : 'N/A';
      
      results.add(_buildTestResult(testName, value, unit));
    }

    if (results.isNotEmpty) {
      print('✅ Columnar format extracted ${results.length} parameters');
    }

    return results;
  }

  // Extract test data from Labsmart Software format
  // Handles formats like: "BUN  10.27  mg/dl  7.9 - 20"
  List<Map<String, dynamic>> _extractLabsmartFormat(String text) {
    final results = <Map<String, dynamic>>[];
    final lines = text.split('\n');

    print('🔍 Trying Labsmart format extraction...');

    // Pattern for: PARAMETER_NAME  VALUE  UNIT  REFERENCE_RANGE
    final pattern = RegExp(
      r'^([A-Z][A-Za-z\s/]+?)\s{2,}([\d.]+)\s+(mg/dl|mg/dL|mmol/L|mEq/L|ml/min[^\s]*|U/L|g/dL|%)',
      caseSensitive: false,
    );

    // Pattern for: PARAMETER_NAME  L/H  VALUE  UNIT (with status indicator)
    final statusPattern = RegExp(
      r'^([A-Z][A-Za-z\s/]+?)\s+([LHN])\s+([\d.]+)\s+(mg/dl|mg/dL|mmol/L|mEq/L|ml/min[^\s]*)',
      caseSensitive: false,
    );

    // Known parameter name mappings (expanded for multiple test types)
    final knownParams = {
      // Kidney Function Tests
      'bun': 'BUN',
      'serum urea': 'Blood Urea',
      'urea': 'Blood Urea',
      'creatinine': 'Creatinine',
      'serum creatinine': 'Creatinine',
      'egfr': 'eGFR',
      'calcium': 'Calcium',
      'serum calcium': 'Calcium',
      'potassium': 'Potassium',
      'serum potassium': 'Potassium',
      'sodium': 'Sodium',
      'serum sodium': 'Sodium',
      'uric acid': 'Uric Acid',
      'serum uric acid': 'Uric Acid',
      // Lipid Profile
      'total cholesterol': 'Total Cholesterol',
      'cholesterol': 'Total Cholesterol',
      'hdl cholesterol': 'HDL Cholesterol',
      'hdl': 'HDL Cholesterol',
      'ldl cholesterol': 'LDL Cholesterol',
      'ldl': 'LDL Cholesterol',
      'triglycerides': 'Triglycerides',
      'vldl': 'VLDL',
      // Blood Sugar Tests
      'glucose': 'Glucose',
      'blood glucose': 'Glucose',
      'fasting glucose': 'Fasting Glucose',
      'hba1c': 'HbA1c',
      'glycated hemoglobin': 'HbA1c',
      // Complete Blood Count
      'hemoglobin': 'Hemoglobin',
      'haemoglobin': 'Hemoglobin',
      'hb': 'Hemoglobin',
      'rbc': 'RBC Count',
      'wbc': 'WBC Count',
      'platelet': 'Platelet Count',
      'platelets': 'Platelet Count',
      // Liver Function Tests
      'sgot': 'SGOT (AST)',
      'ast': 'SGOT (AST)',
      'sgpt': 'SGPT (ALT)',
      'alt': 'SGPT (ALT)',
      'bilirubin': 'Bilirubin',
      'total bilirubin': 'Total Bilirubin',
      // Thyroid Tests
      'tsh': 'TSH',
      't3': 'T3',
      't4': 'T4',
    };

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.length < 5) continue;

      // Try pattern with status indicator first
      var match = statusPattern.firstMatch(trimmed);
      if (match != null) {
        final rawParam = match.group(1)!.trim();
        final normalizedParam = knownParams[rawParam.toLowerCase()] ?? rawParam;
        
        // Process any known parameter or reasonable looking parameter
        if (knownParams.containsKey(rawParam.toLowerCase()) || rawParam.length > 2) {
          final value = match.group(3)!;
          final unit = match.group(4)!;
          results.add(_buildTestResult(normalizedParam, value, unit));
          continue;
        }
      }

      // Try standard pattern
      match = pattern.firstMatch(trimmed);
      if (match != null) {
        final rawParam = match.group(1)!.trim();
        final normalizedParam = knownParams[rawParam.toLowerCase()] ?? rawParam;
        
        // Process any known parameter or reasonable looking parameter
        if (knownParams.containsKey(rawParam.toLowerCase()) || rawParam.length > 2) {
          final value = match.group(2)!;
          final unit = match.group(3)!;
          results.add(_buildTestResult(normalizedParam, value, unit));
        }
      }
    }

    if (results.isNotEmpty) {
      print('✅ Labsmart format extracted ${results.length} parameters');
    }

    return results;
  }

  // Build test result for any test parameter (generic)
  Map<String, dynamic> _buildTestResult(String paramName, String value, String unit) {
    final numValue = double.tryParse(value) ?? 0.0;
    final status = _determineStatus(paramName, numValue);
    final normalRanges = _getNormalRange(paramName);
    final testCategoryInfo = _getTestCategoryForParameter(paramName);

    print('✅ Extracted: $paramName = $value $unit [$status]');

    return {
      'testName': testCategoryInfo['testName']!,
      'testCategory': testCategoryInfo['testCategory']!,
      'testSubCategory': testCategoryInfo['testSubCategory']!,
      'parameterName': paramName,
      'value': value,
      'unit': unit,
      'status': status,
      'referenceRange': _getReferenceRange(paramName),
      'normalMin': normalRanges['min'],
      'normalMax': normalRanges['max'],
    };
  }

  // Get test category information for any parameter
  Map<String, String> _getTestCategoryForParameter(String paramName) {
    final lower = paramName.toLowerCase();
    
    // Lipid Profile
    if (['cholesterol', 'hdl', 'ldl', 'triglycerides', 'vldl'].any((p) => lower.contains(p))) {
      return {
        'testName': 'Lipid Profile',
        'testCategory': 'Lipid Profile',
        'testSubCategory': 'Lipids',
      };
    }
    
    // Kidney Function Tests
    if (['bun', 'urea', 'creatinine', 'egfr', 'uric acid'].any((p) => lower.contains(p))) {
      return {
        'testName': 'Kidney Function Test (KFT/RFT)',
        'testCategory': 'Kidney Function Test (KFT/RFT)',
        'testSubCategory': 'Renal',
      };
    }
    
    // Blood Sugar Tests
    if (['glucose', 'hba1c', 'sugar'].any((p) => lower.contains(p))) {
      return {
        'testName': 'Blood Sugar Test',
        'testCategory': 'Blood Sugar Test',
        'testSubCategory': 'Glucose',
      };
    }
    
    // Liver Function Tests
    if (['sgot', 'sgpt', 'ast', 'alt', 'bilirubin', 'albumin'].any((p) => lower.contains(p))) {
      return {
        'testName': 'Liver Function Test',
        'testCategory': 'Liver Function Test',
        'testSubCategory': 'Hepatic',
      };
    }
    
    // Complete Blood Count
    if (['hemoglobin', 'hb', 'rbc', 'wbc', 'platelet'].any((p) => lower.contains(p))) {
      return {
        'testName': 'Complete Blood Count',
        'testCategory': 'Complete Blood Count',
        'testSubCategory': 'CBC',
      };
    }
    
    // Thyroid Tests
    if (['tsh', 't3', 't4', 'thyroid'].any((p) => lower.contains(p))) {
      return {
        'testName': 'Thyroid Test',
        'testCategory': 'Thyroid Test',
        'testSubCategory': 'Thyroid',
      };
    }
    
    // Default
    return {
      'testName': 'Blood Test',
      'testCategory': 'Blood Test',
      'testSubCategory': paramName,
    };
  }

  // Extract test data from table-like OCR format
  // Handles formats like: "Urea                   16.00       7.50-6.00"
  List<Map<String, dynamic>> _extractFromTableFormat(String text) {
    final List<Map<String, dynamic>> results = [];
    final lines = text.split('\n');

    // Define parameter names to look for
    final parameterPatterns = {
      'Urea':
          RegExp(r'^Urea\s+([\d.]+)', caseSensitive: false, multiLine: false),
      'Creatinine': RegExp(r'^Creatinine\s+([\d.]+)',
          caseSensitive: false, multiLine: false),
      'Uric Acid': RegExp(r'^Uric\s+Acid\s+([\d.]+)',
          caseSensitive: false, multiLine: false),
      'Calcium': RegExp(r'^Calcium\s+([\d.]+)',
          caseSensitive: false, multiLine: false),
      'Phosphorus': RegExp(r'^Phosphorus\s+([\d.]+)',
          caseSensitive: false, multiLine: false),
      'Sodium':
          RegExp(r'^Sodium\s+([\d.]+)', caseSensitive: false, multiLine: false),
      'Potassium': RegExp(r'^Potassium\s+([\d.]+)',
          caseSensitive: false, multiLine: false),
      'Chloride': RegExp(r'^Chloride\s+([\d.]+)',
          caseSensitive: false, multiLine: false),
      'Total Protein': RegExp(r'^Total\s+Protein\s+([\d.]+)',
          caseSensitive: false, multiLine: false),
      'Albumin': RegExp(r'^Albumin\s+([\d.]+)',
          caseSensitive: false, multiLine: false),
      'Alkaline Phosphatase': RegExp(r'^Alkaline\s+Phosphatase\s+([\d.]+)',
          caseSensitive: false, multiLine: false),
      'TSH': RegExp(r'^TSH\s+([\d.]+)', caseSensitive: false, multiLine: false),
      'T3': RegExp(r'^T3\s+([\d.]+)', caseSensitive: false, multiLine: false),
      'T4': RegExp(r'^T4\s+([\d.]+)', caseSensitive: false, multiLine: false),
      'Glucose': RegExp(r'^(?:Glucose|Blood\s+Sugar)\s+([\d.]+)',
          caseSensitive: false, multiLine: false),
      'HbA1c':
          RegExp(r'^HbA1c\s+([\d.]+)', caseSensitive: false, multiLine: false),
      'Hemoglobin': RegExp(r'^(?:Hemoglobin|Haemoglobin)\s+([\d.]+)',
          caseSensitive: false, multiLine: false),
      'Cholesterol': RegExp(r'^(?:Total\s+)?Cholesterol\s+([\d.]+)',
          caseSensitive: false, multiLine: false),
      'HDL': RegExp(r'^HDL\s+([\d.]+)', caseSensitive: false, multiLine: false),
      'LDL': RegExp(r'^LDL\s+([\d.]+)', caseSensitive: false, multiLine: false),
      'Triglycerides': RegExp(r'^Triglycerides\s+([\d.]+)',
          caseSensitive: false, multiLine: false),
    };

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      for (var entry in parameterPatterns.entries) {
        final paramName = entry.key;
        final pattern = entry.value;
        final match = pattern.firstMatch(line);

        if (match != null) {
          final value = match.group(1)!;
          print('✅ Table format extracted: $paramName = $value');

          // Determine test category
          String testCategory = 'Blood Test';
          String testSubCategory = paramName;
          String unit = 'mg/dL'; // Default unit

          if (['Urea', 'Creatinine', 'Uric Acid'].contains(paramName)) {
            testCategory = 'Kidney Function Test';
            testSubCategory = 'Renal';
            unit = 'mg/dL';
          } else if ([
            'Calcium',
            'Phosphorus',
            'Sodium',
            'Potassium',
            'Chloride'
          ].contains(paramName)) {
            testCategory = 'Electrolytes';
            testSubCategory = 'Minerals';
            unit = paramName == 'Calcium' || paramName == 'Phosphorus'
                ? 'mg/dL'
                : 'mEq/L';
          } else if (['Total Protein', 'Albumin', 'Alkaline Phosphatase']
              .contains(paramName)) {
            testCategory = 'Liver Function Test';
            testSubCategory = 'Hepatic';
            unit = paramName == 'Alkaline Phosphatase' ? 'U/L' : 'g/dL';
          } else if (['TSH', 'T3', 'T4'].contains(paramName)) {
            testCategory = 'Thyroid Test';
            testSubCategory = 'Thyroid';
            unit = paramName == 'TSH' ? 'µIU/mL' : 'ng/dL';
          } else if (['Glucose', 'HbA1c'].contains(paramName)) {
            testCategory = 'Blood Sugar Test';
            testSubCategory = 'Glucose';
            unit = paramName == 'HbA1c' ? '%' : 'mg/dL';
          } else if (paramName == 'Hemoglobin') {
            testCategory = 'Complete Blood Count';
            testSubCategory = 'CBC';
            unit = 'g/dL';
          } else if (['Cholesterol', 'HDL', 'LDL', 'Triglycerides']
              .contains(paramName)) {
            testCategory = 'Lipid Profile';
            testSubCategory = 'Lipids';
            unit = 'mg/dL';
          }

          final numValue = double.tryParse(value) ?? 0.0;
          final status = _determineStatus(paramName, numValue);
          final normalRanges = _getNormalRange(paramName);

          results.add({
            'testName': testCategory,
            'testCategory': testCategory,
            'testSubCategory': testSubCategory,
            'parameterName': paramName,
            'value': value,
            'unit': unit,
            'status': status,
            'referenceRange': _getReferenceRange(paramName),
            'normalMin': normalRanges['min'],
            'normalMax': normalRanges['max'],
          });
        }
      }
    }

    return results;
  }

  String _determineStatus(String parameter, double value) {
    final param = parameter.toLowerCase();

    // Thyroid Tests
    if (param.contains('tsh')) {
      return value < 0.5 ? 'LOW' : (value > 5.0 ? 'HIGH' : 'NORMAL');
    } else if (param.contains('t3')) {
      return value < 80 ? 'LOW' : (value > 200 ? 'HIGH' : 'NORMAL');
    } else if (param.contains('t4')) {
      return value < 5.0 ? 'LOW' : (value > 12.0 ? 'HIGH' : 'NORMAL');
    }
    // Blood Count
    else if (param.contains('hemoglobin') ||
        param.contains('hb') ||
        param.contains('hgb')) {
      return value < 12 ? 'LOW' : (value > 16 ? 'HIGH' : 'NORMAL');
    } else if (param.contains('rbc')) {
      return value < 4.5 ? 'LOW' : (value > 5.5 ? 'HIGH' : 'NORMAL');
    } else if (param.contains('wbc')) {
      return value < 4000 ? 'LOW' : (value > 11000 ? 'HIGH' : 'NORMAL');
    } else if (param.contains('platelet')) {
      return value < 150000 ? 'LOW' : (value > 400000 ? 'HIGH' : 'NORMAL');
    }
    // Blood Sugar
    else if (param.contains('glucose') ||
        param.contains('sugar') ||
        param.contains('fbs')) {
      return value < 70 ? 'LOW' : (value > 100 ? 'HIGH' : 'NORMAL');
    } else if (param.contains('hba1c') || param.contains('a1c')) {
      return value > 5.6 ? 'HIGH' : 'NORMAL';
    }
    // Lipids
    else if (param.contains('cholesterol') &&
        !param.contains('hdl') &&
        !param.contains('ldl')) {
      return value > 200 ? 'HIGH' : 'NORMAL';
    } else if (param.contains('hdl')) {
      return value < 40 ? 'LOW' : 'NORMAL';
    } else if (param.contains('ldl')) {
      return value > 100 ? 'HIGH' : 'NORMAL';
    } else if (param.contains('triglyceride')) {
      return value > 150 ? 'HIGH' : 'NORMAL';
    }
    // Blood Sugar - ABG
    else if (param.contains('average') && param.contains('glucose')) {
      return value < 90 ? 'LOW' : (value > 130 ? 'HIGH' : 'NORMAL');
    }
    // Kidney Function
    else if (param.contains('creatinine')) {
      return value < 0.6 ? 'LOW' : (value > 1.3 ? 'HIGH' : 'NORMAL');
    } else if (param.contains('urea') && !param.contains('bun')) {
      return value < 16 ? 'LOW' : (value > 48 ? 'HIGH' : 'NORMAL');
    } else if (param.contains('bun')) {
      return value < 7 ? 'LOW' : (value > 20 ? 'HIGH' : 'NORMAL');
    } else if (param.contains('uric')) {
      return value < 3.5 ? 'LOW' : (value > 7.2 ? 'HIGH' : 'NORMAL');
    } else if (param.contains('gfr') || param.contains('egfr')) {
      return value < 60 ? 'LOW' : 'NORMAL';
    }
    // Electrolytes
    else if (param.contains('calcium')) {
      return value < 8.5 ? 'LOW' : (value > 10.5 ? 'HIGH' : 'NORMAL');
    } else if (param.contains('potassium')) {
      return value < 3.5 ? 'LOW' : (value > 5.0 ? 'HIGH' : 'NORMAL');
    } else if (param.contains('sodium')) {
      return value < 135 ? 'LOW' : (value > 145 ? 'HIGH' : 'NORMAL');
    } else if (param.contains('chloride')) {
      return value < 96 ? 'LOW' : (value > 106 ? 'HIGH' : 'NORMAL');
    } else if (param.contains('phosphorus')) {
      return value < 2.5 ? 'LOW' : (value > 4.5 ? 'HIGH' : 'NORMAL');
    }
    // Liver Function & Proteins
    else if (param.contains('alt') || param.contains('sgpt')) {
      return value > 40 ? 'HIGH' : 'NORMAL';
    } else if (param.contains('ast') || param.contains('sgot')) {
      return value > 40 ? 'HIGH' : 'NORMAL';
    } else if (param.contains('alkaline') || param.contains('alp')) {
      return value < 30 ? 'LOW' : (value > 120 ? 'HIGH' : 'NORMAL');
    } else if (param.contains('total protein')) {
      return value < 6.0 ? 'LOW' : (value > 8.3 ? 'HIGH' : 'NORMAL');
    } else if (param.contains('albumin')) {
      return value < 3.5 ? 'LOW' : (value > 5.5 ? 'HIGH' : 'NORMAL');
    }

    return 'NORMAL';
  }

  String? _getReferenceRange(String parameter) {
    final param = parameter.toLowerCase();

    // Thyroid
    if (param.contains('tsh')) {
      return '0.5-5.0 mIU/L';
    } else if (param.contains('t3')) {
      return '80-200 ng/dL';
    } else if (param.contains('t4')) {
      return '5.0-12.0 µg/dL';
    }
    // Blood Count
    else if (param.contains('hemoglobin') || param.contains('hb')) {
      return '12-16 g/dL';
    } else if (param.contains('rbc')) {
      return '4.5-5.5 million/µL';
    } else if (param.contains('wbc')) {
      return '4000-11000 cells/µL';
    } else if (param.contains('platelet')) {
      return '150000-400000 /µL';
    }
    // Blood Sugar
    else if (param.contains('glucose')) {
      return '70-100 mg/dL';
    } else if (param.contains('hba1c')) {
      return '4.0-5.6 %';
    }
    // Lipids
    else if (param.contains('cholesterol') &&
        !param.contains('hdl') &&
        !param.contains('ldl')) {
      return '<200 mg/dL';
    } else if (param.contains('hdl')) {
      return '>40 mg/dL';
    } else if (param.contains('ldl')) {
      return '<100 mg/dL';
    } else if (param.contains('triglyceride')) {
      return '<150 mg/dL';
    }
    // ABG
    else if (param.contains('average') && param.contains('glucose')) {
      return '90-130 mg/dL';
    }
    // Kidney
    else if (param.contains('creatinine')) {
      return '0.6-1.3 mg/dL';
    } else if (param.contains('urea') && !param.contains('bun')) {
      return '16-48 mg/dL';
    } else if (param.contains('bun')) {
      return '7-20 mg/dL';
    } else if (param.contains('uric')) {
      return '3.5-7.2 mg/dL';
    } else if (param.contains('gfr') || param.contains('egfr')) {
      return '>60 mL/min/1.73m²';
    }
    // Electrolytes
    else if (param.contains('calcium')) {
      return '8.5-10.5 mg/dL';
    } else if (param.contains('potassium')) {
      return '3.5-5.0 mEq/L';
    } else if (param.contains('sodium')) {
      return '135-145 mEq/L';
    } else if (param.contains('chloride')) {
      return '96-106 mEq/L';
    } else if (param.contains('phosphorus')) {
      return '2.5-4.5 mg/dL';
    }
    // Liver & Proteins
    else if (param.contains('alt') || param.contains('sgpt')) {
      return '<40 U/L';
    } else if (param.contains('ast') || param.contains('sgot')) {
      return '<40 U/L';
    } else if (param.contains('alkaline') || param.contains('alp')) {
      return '30-120 U/L';
    } else if (param.contains('total protein')) {
      return '6.0-8.3 g/dL';
    } else if (param.contains('albumin')) {
      return '3.5-5.5 g/dL';
    }

    return null;
  }

  Map<String, double?> _getNormalRange(String parameter) {
    final param = parameter.toLowerCase();

    // Thyroid
    if (param.contains('tsh')) {
      return {'min': 0.5, 'max': 5.0};
    } else if (param.contains('t3')) {
      return {'min': 80.0, 'max': 200.0};
    } else if (param.contains('t4')) {
      return {'min': 5.0, 'max': 12.0};
    }
    // Blood Count
    else if (param.contains('hemoglobin') ||
        param.contains('hb') ||
        param.contains('hgb')) {
      return {'min': 12.0, 'max': 16.0};
    } else if (param.contains('rbc')) {
      return {'min': 4.5, 'max': 5.5};
    } else if (param.contains('wbc')) {
      return {'min': 4000.0, 'max': 11000.0};
    } else if (param.contains('platelets') || param.contains('plt')) {
      return {'min': 150000.0, 'max': 400000.0};
    }
    // Blood Sugar
    else if (param.contains('average') && param.contains('glucose')) {
      return {'min': 90.0, 'max': 130.0};
    } else if (param.contains('glucose') || param.contains('sugar')) {
      return {'min': 70.0, 'max': 100.0};
    } else if (param.contains('hba1c')) {
      return {'min': 4.0, 'max': 5.6};
    }
    // Kidney Function
    else if (param.contains('creatinine')) {
      return {'min': 0.6, 'max': 1.3};
    } else if (param.contains('urea') && !param.contains('bun')) {
      return {'min': 16.0, 'max': 48.0};
    } else if (param.contains('bun')) {
      return {'min': 7.0, 'max': 20.0};
    } else if (param.contains('uric')) {
      return {'min': 3.5, 'max': 7.2};
    } else if (param.contains('gfr') || param.contains('egfr')) {
      return {'min': 60.0, 'max': null};
    }
    // Electrolytes
    else if (param.contains('calcium')) {
      return {'min': 8.5, 'max': 10.5};
    } else if (param.contains('potassium')) {
      return {'min': 3.5, 'max': 5.0};
    } else if (param.contains('sodium')) {
      return {'min': 135.0, 'max': 145.0};
    } else if (param.contains('chloride')) {
      return {'min': 96.0, 'max': 106.0};
    } else if (param.contains('phosphorus')) {
      return {'min': 2.5, 'max': 4.5};
    }
    // Liver & Proteins
    else if (param.contains('alkaline') || param.contains('alp')) {
      return {'min': 30.0, 'max': 120.0};
    } else if (param.contains('total protein')) {
      return {'min': 6.0, 'max': 8.3};
    } else if (param.contains('albumin')) {
      return {'min': 3.5, 'max': 5.5};
    } else if (param.contains('alt') || param.contains('sgpt')) {
      return {'min': null, 'max': 40.0};
    } else if (param.contains('ast') || param.contains('sgot')) {
      return {'min': null, 'max': 40.0};
    }
    // Lipids
    else if (param.contains('cholesterol')) {
      return {'min': null, 'max': 200.0};
    } else if (param.contains('hdl')) {
      return {'min': 40.0, 'max': null};
    } else if (param.contains('ldl')) {
      return {'min': null, 'max': 100.0};
    } else if (param.contains('triglyceride')) {
      return {'min': null, 'max': 150.0};
    }
    // Kidney
    else if (param.contains('creatinine')) {
      return {'min': 0.6, 'max': 1.2};
    } else if (param.contains('urea') || param.contains('bun')) {
      return {'min': 7.0, 'max': 20.0};
    }
    // Liver
    else if (param.contains('alt') || param.contains('sgpt')) {
      return {'min': null, 'max': 40.0};
    } else if (param.contains('ast') || param.contains('sgot')) {
      return {'min': null, 'max': 40.0};
    }

    return {'min': null, 'max': null};
  }

  // Get reports by test type
  List<MedicalReport> getReportsByTestType(String testType) {
    return _reports.where((report) => report.testType == testType).toList();
  }

  // Get recent reports
  List<MedicalReport> getRecentReports({int limit = 5}) {
    return _reports.take(limit).toList();
  }

  // Get test results for a specific test
  List<TestResult> getTestResultsByName(String testName) {
    return _testResults.where((result) => result.testName == testName).toList();
  }

  // Get test results by parameter
  List<TestResult> getTestResultsByParameter(String parameterName) {
    return _testResults
        .where((result) => result.parameterName == parameterName)
        .toList()
      ..sort((a, b) => a.testDate.compareTo(b.testDate));
  }

  // Analyze health conditions from all reports
  void _analyzeHealthConditions() {
    final extractedTexts = _reports
        .where((report) => report.extractedText != null)
        .map((report) => report.extractedText!)
        .toList();

    _healthConditions = HealthAnalysisService.analyzeReports(extractedTexts);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Mock data generation
  List<MedicalReport> _generateMockReports() {
    return [
      MedicalReport(
        id: '1',
        userId: '1',
        testType: 'cbc',
        testName: 'Complete Blood Count',
        reportDate: DateTime.now().subtract(const Duration(days: 7)),
        uploadedAt: DateTime.now().subtract(const Duration(days: 7)),
        labName: 'City Lab',
        doctorName: 'Dr. Sarah Johnson',
        extractedText:
            'Complete Blood Count Report\nHemoglobin: 11.5 g/dL (Low)\nNormal Range: 12-16 g/dL\nDiagnosis: Anemia - Iron deficiency suspected\nRecommendation: Iron supplementation advised',
      ),
      MedicalReport(
        id: '2',
        userId: '1',
        testType: 'lipid',
        testName: 'Lipid Profile',
        reportDate: DateTime.now().subtract(const Duration(days: 30)),
        uploadedAt: DateTime.now().subtract(const Duration(days: 30)),
        labName: 'HealthCare Labs',
        doctorName: 'Dr. Michael Chen',
        extractedText:
            'Lipid Profile Analysis\nTotal Cholesterol: 245 mg/dL (High)\nLDL Cholesterol: 165 mg/dL (Elevated)\nHDL Cholesterol: 38 mg/dL (Low)\nDiagnosis: Hyperlipidemia - High Cholesterol\nRecommendation: Dietary modifications and statin therapy',
      ),
      MedicalReport(
        id: '3',
        userId: '1',
        testType: 'glucose',
        testName: 'Blood Glucose',
        reportDate: DateTime.now().subtract(const Duration(days: 60)),
        uploadedAt: DateTime.now().subtract(const Duration(days: 60)),
        labName: 'City Lab',
        extractedText:
            'Fasting Blood Glucose Test\nGlucose Level: 145 mg/dL (High)\nHbA1c: 7.2% (Elevated)\nDiagnosis: Diabetes Mellitus Type 2\nBlood Pressure: 145/95 mmHg (Hypertension)\nRecommendation: Diabetes management and BP control required',
      ),
    ];
  }

  List<TestResult> _generateMockTestResults() {
    final now = DateTime.now();
    return [
      // Hemoglobin results over time
      TestResult(
        id: '1',
        reportId: '1',
        testName: 'Complete Blood Count',
        parameterName: 'Hemoglobin',
        value: 14.5,
        unit: 'g/dL',
        normalMin: 13.0,
        normalMax: 17.0,
        status: TestStatus.normal,
        testDate: now.subtract(const Duration(days: 7)),
      ),
      TestResult(
        id: '2',
        reportId: '2',
        testName: 'Complete Blood Count',
        parameterName: 'Hemoglobin',
        value: 13.8,
        unit: 'g/dL',
        normalMin: 13.0,
        normalMax: 17.0,
        status: TestStatus.normal,
        testDate: now.subtract(const Duration(days: 37)),
      ),
      TestResult(
        id: '3',
        reportId: '3',
        testName: 'Complete Blood Count',
        parameterName: 'Hemoglobin',
        value: 14.2,
        unit: 'g/dL',
        normalMin: 13.0,
        normalMax: 17.0,
        status: TestStatus.normal,
        testDate: now.subtract(const Duration(days: 67)),
      ),
      // Cholesterol results
      TestResult(
        id: '4',
        reportId: '1',
        testName: 'Lipid Profile',
        parameterName: 'Total Cholesterol',
        value: 195,
        unit: 'mg/dL',
        normalMin: 0,
        normalMax: 200,
        status: TestStatus.normal,
        testDate: now.subtract(const Duration(days: 30)),
      ),
      TestResult(
        id: '5',
        reportId: '2',
        testName: 'Lipid Profile',
        parameterName: 'Total Cholesterol',
        value: 215,
        unit: 'mg/dL',
        normalMin: 0,
        normalMax: 200,
        status: TestStatus.high,
        testDate: now.subtract(const Duration(days: 120)),
      ),
      // Glucose results
      TestResult(
        id: '6',
        reportId: '1',
        testName: 'Blood Glucose',
        parameterName: 'Fasting',
        value: 98,
        unit: 'mg/dL',
        normalMin: 70,
        normalMax: 100,
        status: TestStatus.normal,
        testDate: now.subtract(const Duration(days: 60)),
      ),
      TestResult(
        id: '7',
        reportId: '2',
        testName: 'Blood Glucose',
        parameterName: 'Fasting',
        value: 105,
        unit: 'mg/dL',
        normalMin: 70,
        normalMax: 100,
        status: TestStatus.high,
        testDate: now.subtract(const Duration(days: 150)),
      ),
    ];
  }

  TestStatus _parseTestStatus(String status) {
    switch (status.toUpperCase()) {
      case 'HIGH':
        return TestStatus.high;
      case 'LOW':
        return TestStatus.low;
      default:
        return TestStatus.normal;
    }
  }
}
