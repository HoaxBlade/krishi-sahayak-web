import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ml_service.dart';
import '../widgets/crop_analysis_result.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  final MLService _mlService = MLService();
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (photo != null) {
        _analyzeImage(photo);
      }
    } catch (e) {
      _showError('Error taking photo: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        _analyzeImage(image);
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  Future<void> _analyzeImage(XFile imageFile) async {
    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    try {
      // Check server health first
      bool serverHealthy = await _mlService.checkServerHealth();
      if (!serverHealthy) {
        throw Exception(
          'ML server is not available. Please check if the Python server is running.',
        );
      }

      final result = await _mlService.analyzeCropHealth(imageFile);
      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      _showError('Analysis failed: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Health Analysis'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Camera buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Analysis status
            if (_isAnalyzing)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Analyzing crop health...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),

            // Results
            if (_analysisResult != null)
              Expanded(child: CropAnalysisResult(result: _analysisResult!)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mlService.dispose();
    super.dispose();
  }
}
