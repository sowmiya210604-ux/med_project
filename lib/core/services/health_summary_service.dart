import '../config/api_config.dart';
import 'http_service.dart';

class HealthSummaryService {
  /// Get all health summaries for the current user
  static Future<List<Map<String, dynamic>>> getAllSummaries({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await HttpService.get(
        '${ApiConfig.healthAnalysisUrl}/summary?page=$page&limit=$limit',
        requiresAuth: true,
      );

      if (response['summaries'] != null) {
        return List<Map<String, dynamic>>.from(response['summaries']);
      }

      return [];
    } catch (e) {
      print('Error fetching health summaries: $e');
      rethrow;
    }
  }

  /// Get the latest health summary
  static Future<Map<String, dynamic>?> getLatestSummary() async {
    try {
      final response = await HttpService.get(
        '${ApiConfig.healthAnalysisUrl}/summary/latest',
        requiresAuth: true,
      );

      return response['summary'];
    } catch (e) {
      // Return null if no summary found (404 or specific error message)
      if (e.toString().contains('404') ||
          e.toString().contains('No health summary found')) {
        return null;
      }
      print('Error fetching latest health summary: $e');
      rethrow;
    }
  }

  /// Generate a new health summary
  static Future<Map<String, dynamic>> generateSummary({
    List<String>? reportIds,
  }) async {
    try {
      final response = await HttpService.post(
        '${ApiConfig.healthAnalysisUrl}/summary',
        reportIds != null ? {'reportIds': reportIds} : {},
        requiresAuth: true,
      );

      return response['summary'];
    } catch (e) {
      print('Error generating health summary: $e');
      rethrow;
    }
  }
}
