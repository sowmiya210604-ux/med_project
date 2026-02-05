import '../config/api_config.dart';
import 'http_service.dart';

/// Service for fetching test history data from backend
class TestHistoryService {
  /// Get test history for graphs (all test results for a specific test name)
  /// Returns date-wise test results for chart visualization
  static Future<List<Map<String, dynamic>>> getTestHistory({
    required String testName,
    String? testSubCategory,
  }) async {
    try {
      final queryParams = {
        'testName': testName,
        if (testSubCategory != null) 'testSubCategory': testSubCategory,
      };

      final queryString = Uri(queryParameters: queryParams).query;
      final url = '${ApiConfig.reportUrl}/tests/history?$queryString';

      print('🌐 Fetching test history from: $url');

      final response = await HttpService.get(url, requiresAuth: true);

      print('📥 Test history response: ${response.toString().substring(0, response.toString().length > 200 ? 200 : response.toString().length)}...');

      if (response['results'] != null) {
        final results = List<Map<String, dynamic>>.from(response['results']);
        print('✅ Parsed ${results.length} results from response');
        return results;
      }
      
      print('⚠️ No results field in response');
      return [];
    } catch (e) {
      print('❌ Error in getTestHistory: $e');
      return [];
    }
  }

  /// Get recent test results (limited number for table display)
  /// Default limit is 3 results
  static Future<List<Map<String, dynamic>>> getRecentTests({
    required String testName,
    int limit = 3,
  }) async {
    final queryParams = {
      'testName': testName,
      'limit': limit.toString(),
    };

    final queryString = Uri(queryParameters: queryParams).query;
    final url = '${ApiConfig.reportUrl}/tests/recent?$queryString';

    final response = await HttpService.get(url, requiresAuth: true);

    if (response['results'] != null) {
      return List<Map<String, dynamic>>.from(response['results']);
    }
    return [];
  }

  /// Get full test history (all results for history screen)
  /// Returns all test results sorted by date (latest first)
  static Future<Map<String, dynamic>> getFullTestHistory({
    required String testName,
    String? testSubCategory,
  }) async {
    final queryParams = {
      'testName': testName,
      if (testSubCategory != null) 'testSubCategory': testSubCategory,
    };

    final queryString = Uri(queryParameters: queryParams).query;
    final url = '${ApiConfig.reportUrl}/tests/full-history?$queryString';

    final response = await HttpService.get(url, requiresAuth: true);

    return {
      'testName': response['testName'],
      'testSubCategory': response['testSubCategory'],
      'totalResults': response['totalResults'] ?? 0,
      'results': List<Map<String, dynamic>>.from(response['results'] ?? []),
    };
  }
}
