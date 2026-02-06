import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Enhanced OCR Service for Medical Report Processing
/// Handles OCR extraction and communication with backend auto-classification
class OcrProcessingService {
  static final OcrProcessingService _instance = OcrProcessingService._internal();
  factory OcrProcessingService() => _instance;
  OcrProcessingService._internal();

  TextRecognizer? _textRecognizer;
  String? _baseUrl;

  /// Initialize the OCR service
  Future<void> initialize() async {
    if (!kIsWeb) {
      _textRecognizer = TextRecognizer();
    }
    _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://192.168.1.8:3000';
  }

  /// Extract text from image file using ML Kit OCR
  Future<String> extractTextFromImage(String imagePath) async {
    if (kIsWeb) {
      throw UnsupportedError('OCR is not supported on web platform');
    }

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer!.processImage(inputImage);
      
      return recognizedText.text;
    } catch (e) {
      debugPrint('Error extracting text from image: $e');
      rethrow;
    }
  }

  /// Upload and process report with auto-classification
  Future<Map<String, dynamic>> uploadAndProcessReport({
    required String imagePath,
    required String fileName,
  }) async {
    try {
      // Step 1: Extract text using OCR
      debugPrint('🔍 Extracting text from image...');
      final ocrText = await extractTextFromImage(imagePath);
      
      if (ocrText.isEmpty) {
        throw Exception('No text could be extracted from the image');
      }

      debugPrint('✅ Extracted ${ocrText.length} characters');

      // Step 2: Send to backend for processing
      debugPrint('📤 Sending to backend for auto-classification...');
      final result = await _sendToBackend(ocrText, imagePath, fileName);
      
      return result;
    } catch (e) {
      debugPrint('❌ Error uploading and processing report: $e');
      rethrow;
    }
  }

  /// Send OCR text to backend for processing
  Future<Map<String, dynamic>> _sendToBackend(
    String ocrText,
    String imagePath,
    String fileName,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // Prepare request
      final uri = Uri.parse('$_baseUrl/api/reports/enhanced');
      
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['ocrText'] = ocrText
        ..fields['fileName'] = fileName
        ..files.add(await http.MultipartFile.fromPath('file', imagePath));

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ Report processed successfully');
        return data;
      } else {
        throw Exception('Failed to process report: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error sending to backend: $e');
      rethrow;
    }
  }

  /// Extract text from multiple images (for multi-page reports)
  Future<String> extractTextFromMultipleImages(List<String> imagePaths) async {
    if (kIsWeb) {
      throw UnsupportedError('OCR is not supported on web platform');
    }

    final List<String> extractedTexts = [];

    for (final imagePath in imagePaths) {
      try {
        final text = await extractTextFromImage(imagePath);
        extractedTexts.add(text);
      } catch (e) {
        debugPrint('Error extracting text from $imagePath: $e');
      }
    }

    return extractedTexts.join('\n\n--- PAGE BREAK ---\n\n');
  }

  /// Validate if extracted text contains medical content
  bool validateMedicalContent(String text) {
    final lowerText = text.toLowerCase();
    
    final medicalKeywords = [
      'hemoglobin', 'glucose', 'cholesterol', 'platelet', 'creatinine',
      'bilirubin', 'thyroid', 'tsh', 'test result', 'patient',
      'laboratory', 'reference range', 'normal range', 'mg/dl', 'g/dl'
    ];

    int keywordCount = 0;
    for (final keyword in medicalKeywords) {
      if (lowerText.contains(keyword)) {
        keywordCount++;
      }
    }

    // Report is valid if it contains at least 3 medical keywords
    return keywordCount >= 3;
  }

  /// Dispose resources
  void dispose() {
    _textRecognizer?.close();
  }
}
