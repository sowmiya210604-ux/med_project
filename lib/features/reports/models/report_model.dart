enum TestStatus { normal, high, low }

class MedicalReport {
  final String id;
  final String userId;
  final String testType;
  final String testName;
  final DateTime reportDate;
  final String? imageUrl;
  final String? pdfUrl;
  final String? extractedText;
  final Map<String, dynamic>? testResults;
  final DateTime uploadedAt;
  final String? doctorName;
  final String? labName;

  MedicalReport({
    required this.id,
    required this.userId,
    required this.testType,
    required this.testName,
    required this.reportDate,
    this.imageUrl,
    this.pdfUrl,
    this.extractedText,
    this.testResults,
    required this.uploadedAt,
    this.doctorName,
    this.labName,
  });

  factory MedicalReport.fromJson(Map<String, dynamic> json) {
    return MedicalReport(
      id: json['id'].toString(),
      userId: json['userId'].toString(),
      testType: json['testType'] ?? '',
      testName: json['testName'] ?? json['testType'] ?? 'Medical Report',
      reportDate: DateTime.parse(json['reportDate'] ?? json['createdAt']),
      imageUrl: json['imageUrl'],
      pdfUrl: json['pdfUrl'],
      extractedText: json['extractedText'] ?? json['ocrText'],
      testResults: json['testResults'] is List ? null : json['testResults'],
      uploadedAt: DateTime.parse(json['uploadedAt'] ??
          json['createdAt'] ??
          DateTime.now().toIso8601String()),
      doctorName: json['doctorName'],
      labName: json['labName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'testType': testType,
      'testName': testName,
      'reportDate': reportDate.toIso8601String(),
      'imageUrl': imageUrl,
      'pdfUrl': pdfUrl,
      'extractedText': extractedText,
      'testResults': testResults,
      'uploadedAt': uploadedAt.toIso8601String(),
      'doctorName': doctorName,
      'labName': labName,
    };
  }
}

class TestResult {
  final String id;
  final String reportId;
  final String testName;
  final String parameterName;
  final dynamic value; // Can be String (qualitative) or num (quantitative)
  final String unit;
  final double? normalMin;
  final double? normalMax;
  final TestStatus status;
  final DateTime testDate;

  TestResult({
    required this.id,
    required this.reportId,
    required this.testName,
    required this.parameterName,
    required this.value,
    required this.unit,
    this.normalMin,
    this.normalMax,
    required this.status,
    required this.testDate,
  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    // Parse value - preserve type (qualitative String or quantitative num)
    dynamic parsedValue;
    if (json['value'] is num) {
      parsedValue = (json['value'] as num).toDouble();
    } else if (json['value'] is String) {
      final str = json['value'] as String;
      final numValue = double.tryParse(str);
      // If it's a valid number, convert it; otherwise keep as string
      parsedValue = numValue ?? str;
    } else {
      parsedValue = 0.0;
    }

    // Parse reference range into normalMin and normalMax
    double? normalMin;
    double? normalMax;

    if (json['normalMin'] != null && json['normalMax'] != null) {
      normalMin = (json['normalMin'] as num?)?.toDouble();
      normalMax = (json['normalMax'] as num?)?.toDouble();
    } else if (json['referenceRange'] != null &&
        json['referenceRange'] is String) {
      // Parse "70-100" or "<200" or ">10" format
      final range = json['referenceRange'] as String;
      if (range.contains('-')) {
        final parts = range.replaceAll(RegExp(r'[^0-9.-]'), '').split('-');
        if (parts.length == 2) {
          normalMin = double.tryParse(parts[0]);
          normalMax = double.tryParse(parts[1]);
        }
      } else if (range.startsWith('<')) {
        normalMax = double.tryParse(range.replaceAll(RegExp(r'[^0-9.]'), ''));
      } else if (range.startsWith('>')) {
        normalMin = double.tryParse(range.replaceAll(RegExp(r'[^0-9.]'), ''));
      }
    }

    // Parse status
    TestStatus parsedStatus = TestStatus.normal;
    if (json['status'] != null) {
      final statusStr = json['status'].toString().toLowerCase();
      if (statusStr == 'high') {
        parsedStatus = TestStatus.high;
      } else if (statusStr == 'low') {
        parsedStatus = TestStatus.low;
      }
    }

    return TestResult(
      id: json['id'].toString(),
      reportId: json['reportId'].toString(),
      testName: json['testName'] ?? '',
      parameterName: json['parameterName'] ?? '',
      value: parsedValue,
      unit: json['unit'] ?? '',
      normalMin: normalMin,
      normalMax: normalMax,
      status: parsedStatus,
      testDate: DateTime.parse(json['testDate'] ??
          json['createdAt'] ??
          DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reportId': reportId,
      'testName': testName,
      'parameterName': parameterName,
      'value': value,
      'unit': unit,
      'normalMin': normalMin,
      'normalMax': normalMax,
      'status': status.name,
      'testDate': testDate.toIso8601String(),
    };
  }
}
