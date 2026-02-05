import 'package:flutter/foundation.dart';
import '../models/report_model.dart';
import '../../../core/services/health_analysis_service.dart';
import '../../../core/services/http_service.dart';
import '../../../core/config/api_config.dart';
import '../../../core/utils/storage_helper.dart';

class ReportProvider extends ChangeNotifier {
  List<MedicalReport> _reports = [];
  List<TestResult> _testResults = [];
  List<String> _healthConditions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MedicalReport> get reports => _reports;
  List<TestResult> get testResults => _testResults;
  List<String> get healthConditions => _healthConditions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch all reports
  Future<void> fetchReports() async {
    _isLoading = true;
    _errorMessage = null; // Clear previous errors
    notifyListeners();

    try {
      // Call backend API to fetch reports
      final response = await HttpService.get(
        ApiConfig.reportUrl,
        requiresAuth: true,
      );

      // Parse reports from response
      if (response['reports'] != null) {
        final reportsList = response['reports'] as List;
        _reports =
            reportsList.map((json) => MedicalReport.fromJson(json)).toList();

        // Extract all test results from reports
        _testResults.clear();
        for (var report in reportsList) {
          if (report['testResults'] != null && report['testResults'] is List) {
            final testResultsData = report['testResults'] as List;
            for (var testResult in testResultsData) {
              _testResults.add(TestResult.fromJson(testResult));
            }
          }
        }
      } else {
        // Empty response is valid - no reports yet
        _reports = [];
        _testResults = [];
      }

      // Analyze health conditions from reports
      _analyzeHealthConditions();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Failed to fetch reports: $e');
      _errorMessage = 'Failed to fetch reports: $e';
      _isLoading = false;
      notifyListeners();
      rethrow; // Re-throw to allow UI to handle
    }
  }

  // Upload new report
  Future<bool> uploadReport({
    required String testType,
    required String testName,
    required DateTime reportDate,
    String? imagePath,
    String? extractedText,
    Map<String, dynamic>? testResults,
  }) async {
    _isLoading = true;
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

      // Extract test data from extracted text
      final analyzedTestResults = _extractTestDataFromText(extractedText ?? '');

      // Merge with provided test results
      final allTestResults = <Map<String, dynamic>>[];
      if (testResults != null) {
        allTestResults.add(testResults);
      }
      allTestResults.addAll(analyzedTestResults);

      // Call backend API to upload report
      final response = await HttpService.post(
        ApiConfig.reportUrl,
        {
          'testType': testType,
          'reportDate': reportDate.toIso8601String(),
          'ocrText': extractedText,
          'testResults': allTestResults,
        },
        requiresAuth: true,
      );

      // Get the created report from response
      if (response['report'] != null) {
        final reportData = response['report'];
        final newReport = MedicalReport.fromJson(reportData);
        _reports.insert(0, newReport);

        // Add test results from backend response
        if (reportData['testResults'] != null) {
          final testResultsList = reportData['testResults'] as List;
          for (var testResult in testResultsList) {
            _testResults.add(TestResult.fromJson(testResult));
          }
        }
      }

      // Re-analyze health conditions
      _analyzeHealthConditions();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to upload report: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Extract test data from OCR text
  List<Map<String, dynamic>> _extractTestDataFromText(String text) {
    final List<Map<String, dynamic>> results = [];
    final lines = text.split('\n');

    // Common test parameter patterns
    final patterns = [
      RegExp(r'(Hemoglobin|Hb|HGB)\s*:?\s*([\d.]+)\s*(g/dL|mg/dL)?',
          caseSensitive: false),
      RegExp(r'(Glucose|Blood Sugar|Sugar)\s*:?\s*([\d.]+)\s*(mg/dL)?',
          caseSensitive: false),
      RegExp(r'(Cholesterol|CHOL)\s*:?\s*([\d.]+)\s*(mg/dL)?',
          caseSensitive: false),
      RegExp(r'(RBC|Red Blood Cell)\s*:?\s*([\d.]+)\s*(million/µL)?',
          caseSensitive: false),
      RegExp(r'(WBC|White Blood Cell)\s*:?\s*([\d.]+)\s*(cells/µL)?',
          caseSensitive: false),
      RegExp(r'(Platelets|PLT)\s*:?\s*([\d.]+)\s*(thousands/µL)?',
          caseSensitive: false),
      RegExp(r'(Creatinine|CREAT)\s*:?\s*([\d.]+)\s*(mg/dL)?',
          caseSensitive: false),
      RegExp(r'(Urea|BUN)\s*:?\s*([\d.]+)\s*(mg/dL)?', caseSensitive: false),
    ];

    for (var line in lines) {
      for (var pattern in patterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final parameterName = match.group(1) ?? '';
          final value = match.group(2) ?? '';
          final unit = match.group(3) ?? '';

          // Determine status based on value and parameter
          final status =
              _determineStatus(parameterName, double.tryParse(value) ?? 0);

          final normalRanges = _getNormalRange(parameterName);

          results.add({
            'testName': parameterName,
            'testCategory':
                parameterName, // Use parameter name as category for now
            'testSubCategory': parameterName,
            'parameterName': parameterName,
            'value': value,
            'unit': unit,
            'status': status,
            'referenceRange': _getReferenceRange(parameterName),
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

    if (param.contains('hemoglobin') ||
        param.contains('hb') ||
        param.contains('hgb')) {
      return value < 12 ? 'LOW' : (value > 16 ? 'HIGH' : 'NORMAL');
    } else if (param.contains('glucose') || param.contains('sugar')) {
      return value < 70 ? 'LOW' : (value > 100 ? 'HIGH' : 'NORMAL');
    } else if (param.contains('cholesterol')) {
      return value > 200 ? 'HIGH' : 'NORMAL';
    } else if (param.contains('rbc')) {
      return value < 4.5 ? 'LOW' : (value > 5.5 ? 'HIGH' : 'NORMAL');
    } else if (param.contains('wbc')) {
      return value < 4000 ? 'LOW' : (value > 11000 ? 'HIGH' : 'NORMAL');
    }

    return 'NORMAL';
  }

  String? _getReferenceRange(String parameter) {
    final param = parameter.toLowerCase();

    if (param.contains('hemoglobin') || param.contains('hb')) {
      return '12-16 g/dL';
    } else if (param.contains('glucose')) {
      return '70-100 mg/dL';
    } else if (param.contains('cholesterol')) {
      return '<200 mg/dL';
    } else if (param.contains('rbc')) {
      return '4.5-5.5 million/µL';
    } else if (param.contains('wbc')) {
      return '4000-11000 cells/µL';
    }

    return null;
  }

  Map<String, double?> _getNormalRange(String parameter) {
    final param = parameter.toLowerCase();

    if (param.contains('hemoglobin') ||
        param.contains('hb') ||
        param.contains('hgb')) {
      return {'min': 12.0, 'max': 16.0};
    } else if (param.contains('glucose') || param.contains('sugar')) {
      return {'min': 70.0, 'max': 100.0};
    } else if (param.contains('cholesterol')) {
      return {'min': null, 'max': 200.0};
    } else if (param.contains('rbc')) {
      return {'min': 4.5, 'max': 5.5};
    } else if (param.contains('wbc')) {
      return {'min': 4000.0, 'max': 11000.0};
    } else if (param.contains('platelets') || param.contains('plt')) {
      return {'min': 150.0, 'max': 400.0};
    } else if (param.contains('creatinine')) {
      return {'min': 0.6, 'max': 1.2};
    } else if (param.contains('urea') || param.contains('bun')) {
      return {'min': 7.0, 'max': 20.0};
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
