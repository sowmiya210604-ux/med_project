import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/ocr_processing_service.dart';
import '../providers/report_provider.dart';

/// Enhanced Report Upload Screen with Auto-Classification
class EnhancedUploadReportScreen extends StatefulWidget {
  const EnhancedUploadReportScreen({super.key});

  @override
  State<EnhancedUploadReportScreen> createState() =>
      _EnhancedUploadReportScreenState();
}

class _EnhancedUploadReportScreenState
    extends State<EnhancedUploadReportScreen> {
  final ImagePicker _picker = ImagePicker();
  final OcrProcessingService _ocrService = OcrProcessingService();

  XFile? _selectedImage;
  bool _isProcessing = false;
  String? _processingStage;
  Map<String, dynamic>? _processedResult;

  @override
  void initState() {
    super.initState();
    _ocrService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Medical Report'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUploadOptions(),
            const SizedBox(height: 24),
            if (_selectedImage != null) _buildImagePreview(),
            if (_isProcessing) _buildProcessingIndicator(),
            if (_processedResult != null) _buildResultPreview(),
          ],
        ),
      ),
    );
  }

  /// Build upload option buttons
  Widget _buildUploadOptions() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              '📋 Choose Upload Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _buildUploadButton(
              icon: Icons.camera_alt,
              label: 'Take Photo',
              color: AppColors.primary,
              onTap: _pickFromCamera,
            ),
            const SizedBox(height: 12),
            _buildUploadButton(
              icon: Icons.photo_library,
              label: 'Select from Gallery',
              color: AppColors.secondary,
              onTap: _pickFromGallery,
            ),
            const SizedBox(height: 12),
            _buildUploadButton(
              icon: Icons.picture_as_pdf,
              label: 'Select PDF',
              color: Colors.red.shade400,
              onTap: _pickPdf,
            ),
          ],
        ),
      ),
    );
  }

  /// Build upload button
  Widget _buildUploadButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isProcessing ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build image preview
  Widget _buildImagePreview() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Selected Image',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(_selectedImage!.path),
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _processImage,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Process & Upload'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build processing indicator
  Widget _buildProcessingIndicator() {
    return Card(
      elevation: 2,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _processingStage ?? 'Processing...',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please wait while we analyze your report',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build result preview
  Widget _buildResultPreview() {
    final report = _processedResult!['report'];
    final category = report['category'] ?? 'Unknown';
    final subcategory = report['subcategory'] ?? 'Unknown';
    final labCenter = report['labCenter']?['centerName'] ?? 'Unknown Lab';
    final testResults = report['testResults'] as List? ?? [];

    return Card(
      elevation: 2,
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700, size: 32),
                const SizedBox(width: 12),
                const Text(
                  'Report Processed Successfully!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildResultRow('Category:', category),
            _buildResultRow('Subcategory:', subcategory),
            _buildResultRow('Lab/Center:', labCenter),
            _buildResultRow('Parameters Found:', '${testResults.length}'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Optionally navigate to report details
              },
              icon: const Icon(Icons.done),
              label: const Text('Done'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pick image from camera
  Future<void> _pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
          _processedResult = null;
        });
      }
    } catch (e) {
      _showError('Failed to capture image: $e');
    }
  }

  /// Pick image from gallery
  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
          _processedResult = null;
        });
      }
    } catch (e) {
      _showError('Failed to select image: $e');
    }
  }

  /// Pick PDF (placeholder - requires additional implementation)
  Future<void> _pickPdf() async {
    _showError('PDF upload feature coming soon!');
  }

  /// Process and upload image
  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
      _processingStage = '🔍 Extracting text from image...';
    });

    try {
      // Step 1: Extract text
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Step 2: Auto-classify
      setState(() {
        _processingStage = '🎯 Auto-classifying report...';
      });
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 3: Extract parameters
      setState(() {
        _processingStage = '📊 Extracting test parameters...';
      });
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 4: Upload to server
      setState(() {
        _processingStage = '☁️ Uploading to server...';
      });

      final result = await _ocrService.uploadAndProcessReport(
        imagePath: _selectedImage!.path,
        fileName: _selectedImage!.name,
      );

      // Refresh reports list
      if (mounted) {
        await context.read<ReportProvider>().loadReports();
      }

      setState(() {
        _isProcessing = false;
        _processingStage = null;
        _processedResult = result;
      });

      _showSuccess('Report uploaded and processed successfully!');
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _processingStage = null;
      });
      _showError('Failed to process report: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
