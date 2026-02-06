import 'dart:io' if (dart.library.html) '../../../core/utils/file_stub.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../models/test_type_model.dart';
import '../providers/report_provider.dart';

class UploadReportScreen extends StatefulWidget {
  const UploadReportScreen({super.key});

  @override
  State<UploadReportScreen> createState() => _UploadReportScreenState();
}

class _UploadReportScreenState extends State<UploadReportScreen> {
  XFile? _selectedImage;
  String? _extractedText;
  bool _isProcessing = false;
  bool _isImageClear = true;
  bool _hasMedicalContent = false;
  List<String> _detectedParameters = [];

  // TestType? _selectedTestType; // Removed - auto-detection enabled
  // final _reportDateController = TextEditingController(); // Removed - uses current date
  final _labNameController = TextEditingController();

  // Medical keywords for validation
  static const List<String> _medicalKeywords = [
    'hemoglobin',
    'hb',
    'hgb',
    'glucose',
    'sugar',
    'cholesterol',
    'rbc',
    'wbc',
    'platelet',
    'creatinine',
    'urea',
    'bun',
    'sgot',
    'sgpt',
    'bilirubin',
    'albumin',
    'globulin',
    'tsh',
    't3',
    't4',
    'thyroid',
    'ldl',
    'hdl',
    'triglyceride',
    'hba1c',
    'test result',
    'patient',
    'lab',
    'laboratory',
    'medical',
    'report',
    'reference range',
    'normal range',
    'mg/dl',
    'g/dl',
    'mmol/l',
    'u/l',
    'cells/µl',
    'million/µl'
  ];

  final ImagePicker _picker = ImagePicker();
  TextRecognizer? _textRecognizer;

  @override
  void initState() {
    super.initState();
    // Only initialize ML Kit on mobile platforms
    if (!kIsWeb) {
      _textRecognizer = TextRecognizer();
    }
  }

  @override
  void dispose() {
    // _reportDateController.dispose(); // Removed
    _labNameController.dispose();
    _textRecognizer?.close();
    super.dispose();
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _processImage(image);
      }
    } catch (e) {
      _showError('Failed to capture image: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _processImage(image);
      }
    } catch (e) {
      _showError('Failed to select image: $e');
    }
  }

  Future<void> _processImage(XFile imageFile) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Check file size (limit to 5MB)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        _showError('File size exceeds 5MB limit');
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Validate image clarity and extract text (only on mobile)
      if (!kIsWeb) {
        // Safely create File with null check
        final filePath = imageFile.path;
        if (filePath.isEmpty) {
          _showError('Invalid file path');
          setState(() {
            _isProcessing = false;
          });
          return;
        }

        final file = File(filePath);

        // Verify file exists
        if (!await file.exists()) {
          _showError('File not found');
          setState(() {
            _isProcessing = false;
          });
          return;
        }

        // Process in background to avoid UI freezing
        await _validateImageClarity(file);
        await _extractTextFromImage(file);
      } else {
        setState(() {
          _isImageClear = true;
          _extractedText =
              'OCR not available on web. Please use Android or iOS device for text extraction.';
        });
      }

      setState(() {
        _selectedImage = imageFile;
        _isProcessing = false;
      });
    } catch (e) {
      _showError('Failed to process image: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _validateImageClarity(File imageFile) async {
    try {
      // Using ML Kit Image Labeling to check if image is clear
      final inputImage = InputImage.fromFile(imageFile as dynamic);
      final imageLabeler = ImageLabeler(
        options: ImageLabelerOptions(confidenceThreshold: 0.5),
      );

      // Process in try-catch to handle ML Kit failures
      try {
        final labels = await imageLabeler.processImage(inputImage);

        // Check for blur or unclear indicators
        final hasDocumentLabel = labels.any(
          (label) =>
              label.label.toLowerCase().contains('document') ||
              label.label.toLowerCase().contains('text') ||
              label.label.toLowerCase().contains('paper'),
        );

        setState(() {
          _isImageClear = hasDocumentLabel || labels.length > 3;
        });
      } finally {
        // Always close the labeler
        await imageLabeler.close();
      }
    } catch (e) {
      print('⚠️ Image clarity validation failed: $e');
      // If image labeling fails, assume image is acceptable
      setState(() {
        _isImageClear = true;
      });
    }
  }

  Future<void> _extractTextFromImage(File imageFile) async {
    try {
      if (_textRecognizer == null) {
        print('⚠️ Text recognizer not initialized');
        setState(() {
          _extractedText = 'Text recognizer not available';
          _hasMedicalContent = false;
        });
        return;
      }

      final inputImage = InputImage.fromFile(imageFile as dynamic);

      // Process with timeout to prevent hanging
      final RecognizedText recognizedText =
          await _textRecognizer!.processImage(inputImage).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('OCR processing timed out');
        },
      );

      final StringBuffer extractedText = StringBuffer();

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          extractedText.writeln(line.text);
        }
      }

      final text = extractedText.toString();

      if (mounted) {
        setState(() {
          _extractedText = text;
          _validateMedicalContent(text);
        });
      }
    } catch (e) {
      print('❌ Text extraction failed: $e');
      _showError('Failed to extract text: $e');
      if (mounted) {
        setState(() {
          _extractedText = 'Failed to extract text from image';
          _hasMedicalContent = false;
          _detectedParameters = [];
        });
      }
    }
  }

  void _validateMedicalContent(String text) {
    if (text.isEmpty) {
      _hasMedicalContent = false;
      _detectedParameters = [];
      return;
    }

    final lowerText = text.toLowerCase();

    // Check for medical keywords
    int keywordMatches = 0;
    for (final keyword in _medicalKeywords) {
      if (lowerText.contains(keyword)) {
        keywordMatches++;
      }
    }

    // Detect test parameters (format: Parameter: Value Unit)
    final parameterPattern = RegExp(
      r'(hemoglobin|hb|hgb|glucose|sugar|cholesterol|rbc|wbc|platelet|creatinine|urea|bun|sgot|sgpt|bilirubin|tsh|t3|t4|ldl|hdl|triglyceride|hba1c)\s*:?\s*([\d.]+)\s*(g/dl|mg/dl|mmol/l|u/l|%|cells/µl|million/µl)?',
      caseSensitive: false,
    );

    final matches = parameterPattern.allMatches(lowerText);
    _detectedParameters = matches.map((m) {
      final param = m.group(1) ?? '';
      final value = m.group(2) ?? '';
      final unit = m.group(3) ?? '';
      return '$param: $value $unit'.trim();
    }).toList();

    // Consider it medical content if:
    // - At least 2 medical keywords found OR
    // - At least 1 test parameter detected
    _hasMedicalContent = keywordMatches >= 2 || _detectedParameters.isNotEmpty;
  }

  Future<void> _submitReport() async {
    if (_selectedImage == null) {
      _showError('Please select an image');
      return;
    }

    // Removed validation for test type and date - auto-detection enabled

    // Validate medical content (skip for web)
    if (!kIsWeb && !_hasMedicalContent) {
      await _showMedicalContentWarning();
      return;
    }

    if (!_isImageClear) {
      final confirm = await _showConfirmDialog(
        'Image Quality Warning',
        'The selected image may not be clear. Do you want to proceed anyway?',
      );
      if (!confirm) return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Uploading and analyzing report...'),
              ],
            ),
          ),
        ),
      ),
    );

    final reportProvider = context.read<ReportProvider>();
    final success = await reportProvider.uploadReport(
      testType: 'unknown', // Backend will auto-detect
      testName: 'Medical Report', // Backend will auto-detect
      reportDate: DateTime.now(), // Use current date
      imagePath: _selectedImage!.path,
      extractedText: _extractedText,
    );

    // Close loading dialog
    if (mounted) Navigator.pop(context);

    if (success && mounted) {
      // Refresh reports to get the updated data with auto-detected test type
      await reportProvider.fetchReports(forceRefresh: true);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Report uploaded and analyzed successfully!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );

      // Show results dialog with analyzed data
      await _showAnalysisResults();

      // Navigate back
      if (mounted) Navigator.pop(context);
    } else if (mounted) {
      final errorMsg = reportProvider.errorMessage ?? 'Failed to upload report';

      // Check if auth error
      if (errorMsg.contains('authenticate') ||
          errorMsg.contains('401') ||
          errorMsg.contains('Unauthorized')) {
        _showError('Session expired. Please login again.');
        // Navigate to login after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        });
      } else {
        _showError(errorMsg);
      }
    }
  }

  Future<void> _showAnalysisResults() async {
    final reportProvider = context.read<ReportProvider>();
    final latestReport =
        reportProvider.reports.isNotEmpty ? reportProvider.reports.first : null;

    if (latestReport == null) return;

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics,
                      color: AppColors.primary, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Analysis Complete',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Test info
                      _buildResultItem(
                        'Test Type',
                        latestReport.testName,
                        Icons.medical_services,
                      ),
                      _buildResultItem(
                        'Report Date',
                        '${latestReport.reportDate.day}/${latestReport.reportDate.month}/${latestReport.reportDate.year}',
                        Icons.calendar_today,
                      ),

                      const SizedBox(height: 16),
                      Text(
                        'Extracted Test Results',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),

                      // Show extracted test parameters
                      if (latestReport.extractedText != null &&
                          latestReport.extractedText!.isNotEmpty)
                        ..._buildExtractedParameters(
                            latestReport.extractedText!),

                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: AppColors.success),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Report data has been stored in database and is available for tracking.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.done),
                  label: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildExtractedParameters(String extractedText) {
    final List<Widget> widgets = [];
    final lines = extractedText.split('\\n');

    // Pattern to match test results
    final pattern = RegExp(
      r'(Hemoglobin|Hb|HGB|Glucose|Sugar|Cholesterol|RBC|WBC|Platelets|Creatinine|Urea)\\s*:?\\s*([\\d.]+)\\s*(g/dL|mg/dL|million/µL|cells/µL)?',
      caseSensitive: false,
    );

    for (var line in lines) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        final parameter = match.group(1) ?? '';
        final value = match.group(2) ?? '';
        final unit = match.group(3) ?? '';

        widgets.add(
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.science,
                    color: AppColors.primary, size: 20),
              ),
              title: Text(
                parameter,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Text(
                '$value $unit',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        );
      }
    }

    if (widgets.isEmpty) {
      widgets.add(
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No test parameters detected in the extracted text.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildResultItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _showMedicalContentWarning() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
            SizedBox(width: 12),
            Expanded(child: Text('Not a Medical Report')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The selected image does not appear to contain medical report data.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Medical reports should contain:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                      '• Test parameter names (e.g., Hemoglobin, Glucose)'),
                  const Text('• Numerical values with units (e.g., 14.5 g/dL)'),
                  const Text('• Lab name or medical facility information'),
                  const Text('• Patient or report identification'),
                  const SizedBox(height: 12),
                  if (_detectedParameters.isEmpty)
                    const Text(
                      'No test parameters were detected in this image.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please ensure you are uploading a clear image of a medical report.',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Select Different Image'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Report'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Selection
            _buildImageSelector(),

            if (_selectedImage != null) ...[
              const SizedBox(height: 24),

              // Image Preview
              _buildImagePreview(),

              const SizedBox(height: 24),

              // Test Type Selection - Removed (auto-detection enabled)
              // _buildTestTypeSelector(),

              // Report Date - Removed (uses current date)
              // _buildDateSelector(),

              // Lab Name (Optional)
              TextField(
                controller: _labNameController,
                decoration: const InputDecoration(
                  labelText: 'Lab Name (Optional)',
                  hintText: 'Enter lab name',
                  prefixIcon: Icon(Icons.business),
                ),
              ),

              const SizedBox(height: 24),

              // Medical Content Validation Status
              if (_extractedText != null &&
                  _extractedText!.isNotEmpty &&
                  !kIsWeb)
                _buildMedicalValidationStatus(),

              const SizedBox(height: 16),

              // Extracted Text Preview
              if (_extractedText != null && _extractedText!.isNotEmpty)
                _buildExtractedTextPreview(),

              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isProcessing ? null : _submitReport,
                child: const Text('Submit Report'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageSelector() {
    if (_selectedImage == null) {
      return Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.upload_file,
              size: 80,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Upload Medical Report',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Select an image of your medical report',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _pickImageFromCamera,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take Photo'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickImageFromGallery,
            icon: const Icon(Icons.photo_library),
            label: const Text('Choose from Gallery'),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildImagePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Selected Image',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                  _extractedText = null;
                  _isImageClear = true;
                });
              },
              icon: const Icon(Icons.close),
              label: const Text('Remove'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: kIsWeb
              ? Image.network(
                  _selectedImage!.path,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : Image.file(
                  File(_selectedImage!.path) as dynamic,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
        ),
        if (!_isImageClear) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber, color: AppColors.warning),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Image quality may be low. Consider retaking the photo.',
                    style: TextStyle(color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_isProcessing) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          const Text(
            'Processing image and extracting text...',
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  // Removed _buildTestTypeSelector() and _buildDateSelector() - auto-detection enabled

  Widget _buildMedicalValidationStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _hasMedicalContent
            ? AppColors.success.withOpacity(0.1)
            : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hasMedicalContent ? AppColors.success : AppColors.error,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _hasMedicalContent
                    ? Icons.check_circle
                    : Icons.warning_amber_rounded,
                color: _hasMedicalContent ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _hasMedicalContent
                      ? 'Medical Report Detected'
                      : 'No Medical Data Detected',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _hasMedicalContent
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          if (_detectedParameters.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Detected Parameters (${_detectedParameters.length}):',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ...(_detectedParameters.take(5).map(
                  (param) => Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check,
                            size: 16, color: AppColors.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            param,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
            if (_detectedParameters.length > 5)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Text(
                  '+ ${_detectedParameters.length - 5} more...',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ] else if (!_hasMedicalContent) ...[
            const SizedBox(height: 8),
            const Text(
              'This image does not appear to contain medical test results. Please upload a valid medical report.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExtractedTextPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Extracted Text Preview',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: SingleChildScrollView(
            child: Text(
              _extractedText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
