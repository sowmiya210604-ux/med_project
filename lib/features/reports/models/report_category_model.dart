/// Enums and models for Report Explorer feature
library;

enum ReportCategory {
  lab,
  imaging,
}

enum LabSubCategory {
  cbc,
  bloodSugar,
  lipidProfile,
  liverFunction,
  kidneyFunction,
  thyroidProfile,
  urineAnalysis,
  electrolytes,
  vitaminTests,
  hormoneTests,
  infectionMarkers,
}

enum ImagingSubCategory {
  xray,
  ctScan,
  mri,
  ultrasound,
  petScan,
  mammogram,
  ecgEcho,
  endoscopy,
}

class CategoryInfo {
  final String name;
  final String icon;
  final ReportCategory category;

  const CategoryInfo({
    required this.name,
    required this.icon,
    required this.category,
  });
}

class SubCategoryInfo {
  final String id;
  final String name;
  final String description;
  final List<String> defaultParameters;

  const SubCategoryInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.defaultParameters,
  });
}

/// Extension methods for enums
extension ReportCategoryExtension on ReportCategory {
  String get displayName {
    switch (this) {
      case ReportCategory.lab:
        return 'Lab Reports';
      case ReportCategory.imaging:
        return 'Imaging Reports';
    }
  }

  String get icon {
    switch (this) {
      case ReportCategory.lab:
        return '🧪';
      case ReportCategory.imaging:
        return '🩻';
    }
  }
}

extension LabSubCategoryExtension on LabSubCategory {
  String get displayName {
    switch (this) {
      case LabSubCategory.cbc:
        return 'Complete Blood Count (CBC)';
      case LabSubCategory.bloodSugar:
        return 'Blood Sugar (Glucose Tests)';
      case LabSubCategory.lipidProfile:
        return 'Lipid Profile';
      case LabSubCategory.liverFunction:
        return 'Liver Function Test (LFT)';
      case LabSubCategory.kidneyFunction:
        return 'Kidney Function Test (KFT/RFT)';
      case LabSubCategory.thyroidProfile:
        return 'Thyroid Profile';
      case LabSubCategory.urineAnalysis:
        return 'Urine Analysis';
      case LabSubCategory.electrolytes:
        return 'Electrolytes';
      case LabSubCategory.vitaminTests:
        return 'Vitamin Tests';
      case LabSubCategory.hormoneTests:
        return 'Hormone Tests';
      case LabSubCategory.infectionMarkers:
        return 'Infection Markers';
    }
  }

  String get id {
    return name;
  }

  List<String> get defaultParameters {
    switch (this) {
      case LabSubCategory.cbc:
        return ['Hemoglobin', 'RBC Count', 'WBC Count', 'Platelet Count', 'Hematocrit', 'MCV', 'MCH', 'MCHC'];
      case LabSubCategory.bloodSugar:
        return ['Fasting Blood Sugar', 'Post Prandial', 'HbA1c', 'Random Blood Sugar'];
      case LabSubCategory.lipidProfile:
        return ['Total Cholesterol', 'HDL', 'LDL', 'Triglycerides', 'VLDL', 'Cholesterol/HDL Ratio'];
      case LabSubCategory.liverFunction:
        return ['SGOT (AST)', 'SGPT (ALT)', 'Bilirubin Total', 'Bilirubin Direct', 'Alkaline Phosphatase', 'Total Protein', 'Albumin', 'Globulin'];
      case LabSubCategory.kidneyFunction:
        return ['Creatinine', 'Blood Urea', 'BUN', 'Uric Acid', 'Sodium', 'Potassium', 'Calcium'];
      case LabSubCategory.thyroidProfile:
        return ['TSH', 'T3', 'T4', 'Free T3', 'Free T4'];
      case LabSubCategory.urineAnalysis:
        return ['pH', 'Specific Gravity', 'Protein', 'Glucose', 'Ketones', 'Blood', 'Leukocytes', 'Nitrites'];
      case LabSubCategory.electrolytes:
        return ['Sodium', 'Potassium', 'Chloride', 'Bicarbonate', 'Calcium', 'Magnesium'];
      case LabSubCategory.vitaminTests:
        return ['Vitamin D', 'Vitamin B12', 'Folate', 'Vitamin A', 'Vitamin E'];
      case LabSubCategory.hormoneTests:
        return ['Testosterone', 'Estrogen', 'Progesterone', 'Cortisol', 'Insulin'];
      case LabSubCategory.infectionMarkers:
        return ['CRP', 'ESR', 'Procalcitonin', 'White Blood Cell Count'];
    }
  }
}

extension ImagingSubCategoryExtension on ImagingSubCategory {
  String get displayName {
    switch (this) {
      case ImagingSubCategory.xray:
        return 'X-Ray';
      case ImagingSubCategory.ctScan:
        return 'CT Scan';
      case ImagingSubCategory.mri:
        return 'MRI';
      case ImagingSubCategory.ultrasound:
        return 'Ultrasound';
      case ImagingSubCategory.petScan:
        return 'PET Scan';
      case ImagingSubCategory.mammogram:
        return 'Mammogram';
      case ImagingSubCategory.ecgEcho:
        return 'ECG / ECHO';
      case ImagingSubCategory.endoscopy:
        return 'Endoscopy / Colonoscopy';
    }
  }

  String get id {
    return name;
  }

  List<String> get defaultParameters {
    // For imaging reports, parameters represent key findings
    switch (this) {
      case ImagingSubCategory.xray:
        return ['Findings', 'Abnormalities', 'Impression', 'Radiologist Notes'];
      case ImagingSubCategory.ctScan:
        return ['Findings', 'Contrast Used', 'Measurements', 'Impression', 'Radiologist Notes'];
      case ImagingSubCategory.mri:
        return ['Findings', 'Sequence', 'Contrast Used', 'Measurements', 'Impression'];
      case ImagingSubCategory.ultrasound:
        return ['Findings', 'Measurements', 'Impression', 'Recommendations'];
      case ImagingSubCategory.petScan:
        return ['SUV Max', 'Findings', 'Metabolic Activity', 'Impression'];
      case ImagingSubCategory.mammogram:
        return ['BIRADS Score', 'Findings', 'Density', 'Impression'];
      case ImagingSubCategory.ecgEcho:
        return ['Heart Rate', 'Rhythm', 'EF%', 'Findings', 'Interpretation'];
      case ImagingSubCategory.endoscopy:
        return ['Findings', 'Biopsy Taken', 'Impression', 'Recommendations'];
    }
  }
}

/// Model for representing a detailed report with parameter data
class DetailedReportData {
  final String reportId;
  final DateTime reportDate;
  final Map<String, ParameterValue> parameters;
  final String summary;

  DetailedReportData({
    required this.reportId,
    required this.reportDate,
    required this.parameters,
    required this.summary,
  });
}

/// Model for a parameter value with metadata
class ParameterValue {
  final String parameterName;
  final dynamic value;
  final String unit;
  final double? normalMin;
  final double? normalMax;
  final String? status;

  ParameterValue({
    required this.parameterName,
    required this.value,
    required this.unit,
    this.normalMin,
    this.normalMax,
    this.status,
  });

  /// Check if value is numeric
  bool get isNumeric => value is num || (value is String && double.tryParse(value) != null);

  /// Get numeric value
  double? get numericValue {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// Model for comparison result
class ComparisonResult {
  final String parameterName;
  final dynamic oldValue;
  final dynamic newValue;
  final String unit;
  final ComparisonStatus status;
  final String description;

  ComparisonResult({
    required this.parameterName,
    required this.oldValue,
    required this.newValue,
    required this.unit,
    required this.status,
    required this.description,
  });
}

enum ComparisonStatus {
  improved,
  worsened,
  increased,
  decreased,
  stable,
  noData,
}

extension ComparisonStatusExtension on ComparisonStatus {
  String get displayName {
    switch (this) {
      case ComparisonStatus.improved:
        return '⬆ Improved';
      case ComparisonStatus.worsened:
        return '⬇ Worsened';
      case ComparisonStatus.increased:
        return '↗ Increased';
      case ComparisonStatus.decreased:
        return '↘ Decreased';
      case ComparisonStatus.stable:
        return '→ Stable';
      case ComparisonStatus.noData:
        return '— No Data';
    }
  }

  String get icon {
    switch (this) {
      case ComparisonStatus.improved:
        return '⬆';
      case ComparisonStatus.worsened:
        return '⬇';
      case ComparisonStatus.increased:
        return '↗';
      case ComparisonStatus.decreased:
        return '↘';
      case ComparisonStatus.stable:
        return '→';
      case ComparisonStatus.noData:
        return '—';
    }
  }
}
