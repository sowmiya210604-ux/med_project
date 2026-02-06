/// Report Category Enum
enum ReportCategory {
  lab('Lab Reports'),
  imaging('Imaging Reports');

  final String displayName;
  const ReportCategory(this.displayName);
}

/// Lab Report Subcategories
enum LabSubCategory {
  bloodTests('Blood Tests', 'BT'),
  urineTests('Urine Tests', 'UT'),
  liverFunction('Liver Function Tests', 'LFT'),
  kidneyRenal('Kidney / Renal Tests', 'KFT'),
  thyroid('Thyroid Tests', 'THY'),
  cardiac('Heart / Cardiac Tests', 'CAR'),
  hormone('Hormone Tests', 'HOR'),
  diabetes('Diabetes Tests', 'DIA'),
  vitaminDeficiency('Vitamin & Deficiency Tests', 'VIT'),
  infectionImmunity('Infection & Immunity Tests', 'INF'),
  cancerMarkers('Cancer Markers', 'CAN');

  final String displayName;
  final String id;
  const LabSubCategory(this.displayName, this.id);
}

/// Imaging Report Subcategories
enum ImagingSubCategory {
  xray('X-Ray', 'XR'),
  ctScan('CT Scan', 'CT'),
  mri('MRI', 'MRI'),
  ultrasound('Ultrasound', 'USG'),
  ecgEcho('ECG / ECHO', 'ECG'),
  mammography('Mammography', 'MAM'),
  petScan('PET Scan', 'PET');

  final String displayName;
  final String id;
  const ImagingSubCategory(this.displayName, this.id);
}

/// Enhanced Report Model with Auto-Classification
class EnhancedReport {
  final String id;
  final String userId;
  final String? centerId;
  final String testType;
  final DateTime reportDate;
  final String category;
  final String? subcategory;
  final String? filePath;
  final String? fileName;
  final String? ocrText;
  final DateTime createdAt;
  final DateTime updatedAt;
  final LabCenter? labCenter;
  final List<TestResult> testResults;
  final List<HealthSummary> healthSummaries;

  EnhancedReport({
    required this.id,
    required this.userId,
    this.centerId,
    required this.testType,
    required this.reportDate,
    required this.category,
    this.subcategory,
    this.filePath,
    this.fileName,
    this.ocrText,
    required this.createdAt,
    required this.updatedAt,
    this.labCenter,
    this.testResults = const [],
    this.healthSummaries = const [],
  });

  factory EnhancedReport.fromJson(Map<String, dynamic> json) {
    return EnhancedReport(
      id: json['id'] as String,
      userId: json['userId'] as String,
      centerId: json['centerId'] as String?,
      testType: json['testType'] as String,
      reportDate: DateTime.parse(json['reportDate'] as String),
      category: json['category'] as String,
      subcategory: json['subcategory'] as String?,
      filePath: json['filePath'] as String?,
      fileName: json['fileName'] as String?,
      ocrText: json['ocrText'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      labCenter: json['labCenter'] != null
          ? LabCenter.fromJson(json['labCenter'] as Map<String, dynamic>)
          : null,
      testResults: (json['testResults'] as List?)
              ?.map((e) => TestResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      healthSummaries: (json['healthSummaries'] as List?)
              ?.map((e) => HealthSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'centerId': centerId,
      'testType': testType,
      'reportDate': reportDate.toIso8601String(),
      'category': category,
      'subcategory': subcategory,
      'filePath': filePath,
      'fileName': fileName,
      'ocrText': ocrText,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'labCenter': labCenter?.toJson(),
      'testResults': testResults.map((e) => e.toJson()).toList(),
      'healthSummaries': healthSummaries.map((e) => e.toJson()).toList(),
    };
  }
}

/// Lab Center Model
class LabCenter {
  final String id;
  final String centerName;
  final String type;
  final String? location;
  final String? phoneNumber;
  final String? email;
  final DateTime createdAt;
  final DateTime updatedAt;

  LabCenter({
    required this.id,
    required this.centerName,
    required this.type,
    this.location,
    this.phoneNumber,
    this.email,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LabCenter.fromJson(Map<String, dynamic> json) {
    return LabCenter(
      id: json['id'] as String,
      centerName: json['centerName'] as String,
      type: json['type'] as String,
      location: json['location'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'centerName': centerName,
      'type': type,
      'location': location,
      'phoneNumber': phoneNumber,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Test Result Model
class TestResult {
  final String id;
  final String reportId;
  final String? parameterId;
  final String testCategory;
  final String? testSubCategory;
  final String testName;
  final String parameterName;
  final String value;
  final String? unit;
  final String status;
  final String? referenceRange;
  final double? normalMin;
  final double? normalMax;
  final DateTime testDate;
  final DateTime createdAt;

  TestResult({
    required this.id,
    required this.reportId,
    this.parameterId,
    required this.testCategory,
    this.testSubCategory,
    required this.testName,
    required this.parameterName,
    required this.value,
    this.unit,
    required this.status,
    this.referenceRange,
    this.normalMin,
    this.normalMax,
    required this.testDate,
    required this.createdAt,
  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      id: json['id'] as String,
      reportId: json['reportId'] as String,
      parameterId: json['parameterId'] as String?,
      testCategory: json['testCategory'] as String,
      testSubCategory: json['testSubCategory'] as String?,
      testName: json['testName'] as String,
      parameterName: json['parameterName'] as String,
      value: json['value'] as String,
      unit: json['unit'] as String?,
      status: json['status'] as String,
      referenceRange: json['referenceRange'] as String?,
      normalMin: json['normalMin'] as double?,
      normalMax: json['normalMax'] as double?,
      testDate: DateTime.parse(json['testDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reportId': reportId,
      'parameterId': parameterId,
      'testCategory': testCategory,
      'testSubCategory': testSubCategory,
      'testName': testName,
      'parameterName': parameterName,
      'value': value,
      'unit': unit,
      'status': status,
      'referenceRange': referenceRange,
      'normalMin': normalMin,
      'normalMax': normalMax,
      'testDate': testDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Health Summary Model
class HealthSummary {
  final String id;
  final String userId;
  final String reportId;
  final String summaryText;
  final String? insights;
  final String overallStatus;
  final int abnormalCount;
  final String riskLevel;
  final List<dynamic>? keyIssues;
  final List<dynamic>? recommendations;
  final DateTime createdAt;

  HealthSummary({
    required this.id,
    required this.userId,
    required this.reportId,
    required this.summaryText,
    this.insights,
    required this.overallStatus,
    required this.abnormalCount,
    required this.riskLevel,
    this.keyIssues,
    this.recommendations,
    required this.createdAt,
  });

  factory HealthSummary.fromJson(Map<String, dynamic> json) {
    return HealthSummary(
      id: json['id'] as String,
      userId: json['userId'] as String,
      reportId: json['reportId'] as String,
      summaryText: json['summaryText'] as String,
      insights: json['insights'] as String?,
      overallStatus: json['overallStatus'] as String,
      abnormalCount: json['abnormalCount'] as int,
      riskLevel: json['riskLevel'] as String,
      keyIssues: json['keyIssues'] != null
          ? (json['keyIssues'] is String
              ? [] // Parse JSON string if needed
              : json['keyIssues'] as List)
          : null,
      recommendations: json['recommendations'] != null
          ? (json['recommendations'] is String
              ? [] // Parse JSON string if needed
              : json['recommendations'] as List)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'reportId': reportId,
      'summaryText': summaryText,
      'insights': insights,
      'overallStatus': overallStatus,
      'abnormalCount': abnormalCount,
      'riskLevel': riskLevel,
      'keyIssues': keyIssues,
      'recommendations': recommendations,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
