/// Master Test Definition Model for MedTrack
/// This model represents the standard reference data for all medical tests
library;

class TestDefinition {
  final String testId;
  final String categoryName;
  final String testName;
  final String parameterName;
  final String unit;
  final double? normalMinValue;
  final double? normalMaxValue;
  final RiskLevelLogic riskLevelLogic;
  final bool isQualitative;
  final GenderSpecific? genderSpecific;

  TestDefinition({
    required this.testId,
    required this.categoryName,
    required this.testName,
    required this.parameterName,
    required this.unit,
    this.normalMinValue,
    this.normalMaxValue,
    required this.riskLevelLogic,
    this.isQualitative = false,
    this.genderSpecific,
  });

  factory TestDefinition.fromJson(Map<String, dynamic> json) {
    return TestDefinition(
      testId: json['test_id'] as String,
      categoryName: json['category_name'] as String,
      testName: json['test_name'] as String,
      parameterName: json['parameter_name'] as String,
      unit: json['unit'] as String? ?? '',
      normalMinValue: json['normal_min_value'] != null
          ? (json['normal_min_value'] as num).toDouble()
          : null,
      normalMaxValue: json['normal_max_value'] != null
          ? (json['normal_max_value'] as num).toDouble()
          : null,
      riskLevelLogic: RiskLevelLogic.fromJson(
          json['risk_level_logic'] as Map<String, dynamic>),
      isQualitative: json['is_qualitative'] as bool? ?? false,
      genderSpecific: json['gender_specific'] != null
          ? GenderSpecific.fromJson(
              json['gender_specific'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'test_id': testId,
      'category_name': categoryName,
      'test_name': testName,
      'parameter_name': parameterName,
      'unit': unit,
      'normal_min_value': normalMinValue,
      'normal_max_value': normalMaxValue,
      'risk_level_logic': riskLevelLogic.toJson(),
      'is_qualitative': isQualitative,
      'gender_specific': genderSpecific?.toJson(),
    };
  }

  /// Get reference range as a string (e.g., "12.0 - 17.0 g/dL")
  String getReferenceRange() {
    if (isQualitative || normalMinValue == null || normalMaxValue == null) {
      return riskLevelLogic.normal;
    }
    return '$normalMinValue - $normalMaxValue ${unit.isNotEmpty ? unit : ""}';
  }

  /// Determine the risk status for a given test value
  /// Returns: "LOW", "NORMAL", or "HIGH"
  String getRiskStatus(double value, {String? gender}) {
    // Use gender-specific ranges if available and gender is provided
    if (gender != null && genderSpecific != null) {
      final range = gender.toLowerCase() == 'male'
          ? genderSpecific!.male
          : genderSpecific!.female;
      if (range != null) {
        if (value < range.min) return 'LOW';
        if (value > range.max) return 'HIGH';
        return 'NORMAL';
      }
    }

    // Use general ranges
    if (normalMinValue != null && value < normalMinValue!) return 'LOW';
    if (normalMaxValue != null && value > normalMaxValue!) return 'HIGH';
    return 'NORMAL';
  }

  /// Get risk status for qualitative tests (e.g., "Positive" vs "Negative")
  String getRiskStatusQualitative(String value) {
    final normalizedValue = value.trim().toLowerCase();
    final normalizedNormal = riskLevelLogic.normal.toLowerCase();
    
    if (normalizedNormal.contains(normalizedValue) || 
        normalizedValue.contains('negative') ||
        normalizedValue.contains('absent') ||
        normalizedValue.contains('normal')) {
      return 'NORMAL';
    }
    return 'HIGH';
  }
}

class RiskLevelLogic {
  final String low;
  final String normal;
  final String high;

  RiskLevelLogic({
    required this.low,
    required this.normal,
    required this.high,
  });

  factory RiskLevelLogic.fromJson(Map<String, dynamic> json) {
    return RiskLevelLogic(
      low: json['low'] as String,
      normal: json['normal'] as String,
      high: json['high'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'low': low,
      'normal': normal,
      'high': high,
    };
  }
}

class GenderSpecific {
  final TestRange? male;
  final TestRange? female;

  GenderSpecific({
    this.male,
    this.female,
  });

  factory GenderSpecific.fromJson(Map<String, dynamic> json) {
    return GenderSpecific(
      male: json['male'] != null
          ? TestRange.fromJson(json['male'] as Map<String, dynamic>)
          : null,
      female: json['female'] != null
          ? TestRange.fromJson(json['female'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'male': male?.toJson(),
      'female': female?.toJson(),
    };
  }
}

class TestRange {
  final double min;
  final double max;

  TestRange({
    required this.min,
    required this.max,
  });

  factory TestRange.fromJson(Map<String, dynamic> json) {
    return TestRange(
      min: (json['min'] as num).toDouble(),
      max: (json['max'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
    };
  }
}

/// Master Test Data Repository
class TestDefinitionRepository {
  static final Map<String, TestDefinition> _cache = {};
  static bool _initialized = false;

  /// Initialize the repository with test definitions
  static void initialize(List<TestDefinition> definitions) {
    _cache.clear();
    for (final def in definitions) {
      _cache[def.testId] = def;
    }
    _initialized = true;
  }

  /// Get test definition by test ID
  static TestDefinition? getByTestId(String testId) {
    return _cache[testId];
  }

  /// Get all tests in a category
  static List<TestDefinition> getByCategory(String categoryName) {
    return _cache.values
        .where((def) => def.categoryName == categoryName)
        .toList();
  }

  /// Get all unique categories
  static List<String> getAllCategories() {
    return _cache.values.map((def) => def.categoryName).toSet().toList()
      ..sort();
  }

  /// Find test definition by test name (fuzzy search)
  static TestDefinition? findByTestName(String testName) {
    final normalized = testName.trim().toLowerCase();
    return _cache.values.firstWhere(
      (def) =>
          def.testName.toLowerCase() == normalized ||
          def.parameterName.toLowerCase() == normalized,
      orElse: () => _cache.values.firstWhere(
        (def) =>
            def.testName.toLowerCase().contains(normalized) ||
            def.parameterName.toLowerCase().contains(normalized),
        orElse: () => throw Exception('Test definition not found: $testName'),
      ),
    );
  }

  /// Get all test definitions
  static List<TestDefinition> getAll() {
    return _cache.values.toList();
  }

  /// Check if repository is initialized
  static bool get isInitialized => _initialized;

  /// Get total count of test definitions
  static int get count => _cache.length;
}
