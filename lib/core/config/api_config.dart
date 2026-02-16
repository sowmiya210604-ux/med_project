import 'dart:io' if (dart.library.html) '../utils/file_stub.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // Load from .env file, default to development
  static bool get isProduction =>
      dotenv.env['ENVIRONMENT']?.toLowerCase() == 'production';

  // Get base URL from environment or use default
  static String get _envBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000/api';

  // Automatically detect platform and use correct URL
  static String get _devBaseUrl {
    // Check for platform-specific overrides first
    if (kIsWeb && dotenv.env.containsKey('API_BASE_URL_WEB')) {
      return dotenv.env['API_BASE_URL_WEB']!;
    } else if (!kIsWeb) {
      // Only check Platform on non-web platforms
      try {
        if (Platform.isAndroid &&
            dotenv.env.containsKey('API_BASE_URL_ANDROID')) {
          return dotenv.env['API_BASE_URL_ANDROID']!;
        } else if (Platform.isIOS &&
            dotenv.env.containsKey('API_BASE_URL_IOS')) {
          return dotenv.env['API_BASE_URL_IOS']!;
        } else if (Platform.isWindows &&
            dotenv.env.containsKey('API_BASE_URL_WINDOWS')) {
          return dotenv.env['API_BASE_URL_WINDOWS']!;
        } else if (Platform.isMacOS &&
            dotenv.env.containsKey('API_BASE_URL_MACOS')) {
          return dotenv.env['API_BASE_URL_MACOS']!;
        } else if (Platform.isLinux &&
            dotenv.env.containsKey('API_BASE_URL_LINUX')) {
          return dotenv.env['API_BASE_URL_LINUX']!;
        }
      } catch (e) {
        // Platform not available, use default
      }
    }

    // Use default base URL from .env
    return _envBaseUrl;
  }

  static String get _prodBaseUrl =>
      dotenv.env['API_BASE_URL_PROD'] ?? 'https://api.medtrack.com/api';

  static String get baseUrl => isProduction ? _prodBaseUrl : _devBaseUrl;

  // All endpoints use the same base URL (monolithic architecture)
  static String get authUrl => '$baseUrl/auth';
  static String get profileUrl => '$baseUrl/auth'; // Profile is part of auth
  static String get reportUrl => '$baseUrl/reports';
  static String get extractionUrl => '$baseUrl/extraction'; // New schema-based extraction
  static String get healthAnalysisUrl => '$baseUrl/health';
  static String get historyUrl => '$baseUrl/history';
  static String get notificationUrl => '$baseUrl/notifications';

  static Duration get receiveTimeout =>
      Duration(seconds: int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30') ?? 30);

  static bool get enableLogging =>
      dotenv.env['ENABLE_API_LOGGING']?.toLowerCase() == 'true';

  static void log(String message) {
    if (enableLogging) {
      print('🌐 [API] $message');
    }
  }
}
