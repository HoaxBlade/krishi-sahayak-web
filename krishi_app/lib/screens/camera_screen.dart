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
    debugPrint('📸 [CameraScreen] User requested to take a photo...');
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (photo != null) {
        debugPrint(
          '✅ [CameraScreen] Photo captured successfully: ${photo.path}',
        );
        _analyzeImage(photo);
      } else {
        debugPrint('❌ [CameraScreen] No photo was captured');
      }
    } catch (e) {
      debugPrint('💥 [CameraScreen] Error taking photo: $e');
      _showError(
        'Unable to take photo. Please check camera permissions and try again.',
      );
    }
  }

  Future<void> _pickFromGallery() async {
    debugPrint(
      '🖼️ [CameraScreen] User requested to pick image from gallery...',
    );
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (image != null) {
        debugPrint(
          '✅ [CameraScreen] Image selected from gallery: ${image.path}',
        );
        _analyzeImage(image);
      } else {
        debugPrint('❌ [CameraScreen] No image was selected from gallery');
      }
    } catch (e) {
      debugPrint('💥 [CameraScreen] Error picking image from gallery: $e');
      _showError(
        'Unable to access gallery. Please check permissions and try again.',
      );
    }
  }

  Future<void> _analyzeImage(XFile imageFile) async {
    final overallStopwatch = Stopwatch()..start();
    debugPrint('📸 [CameraScreen] Starting image analysis process...');
    debugPrint('📊 [CameraScreen] Image file path: ${imageFile.path}');
    debugPrint('📊 [CameraScreen] Image file name: ${imageFile.name}');

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    try {
      debugPrint('🚀 [CameraScreen] Starting ML analysis...');
      final mlAnalysisStart = Stopwatch()..start();
      final result = await _mlService.analyzeCropHealth(imageFile);
      mlAnalysisStart.stop();
      debugPrint(
        '✅ [CameraScreen] ML analysis completed in ${mlAnalysisStart.elapsedMilliseconds}ms',
      );

      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });

      overallStopwatch.stop();
      debugPrint(
        '🎉 [CameraScreen] Complete analysis process finished in ${overallStopwatch.elapsedMilliseconds}ms',
      );
      debugPrint(
        '📊 [CameraScreen] Analysis result received: ${result.keys.toList()}',
      );

      // Show appropriate dialog based on model type
      _showAnalysisResultDialog(result);
    } catch (e) {
      overallStopwatch.stop();
      debugPrint(
        '💥 [CameraScreen] Analysis failed after ${overallStopwatch.elapsedMilliseconds}ms: $e',
      );
      setState(() {
        _isAnalyzing = false;
      });
      _showError(
        'Crop analysis failed. Please check your internet connection and try again.',
      );
    }
  }

  void _showAnalysisResultDialog(Map<String, dynamic> result) {
    final modelType = result['model_type'] ?? 'unknown';
    final analysisMode = result['analysis_mode'] ?? 'unknown';
    final processingTime = result['processing_time'] ?? 'unknown';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                modelType == 'server' ? Icons.cloud : Icons.phone_android,
                color: modelType == 'server' ? Colors.blue : Colors.green,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  modelType == 'server' ? 'Server Analysis' : 'Local Analysis',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Model type indicator
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: modelType == 'server'
                          ? Colors.blue.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: modelType == 'server'
                            ? Colors.blue
                            : Colors.green,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          modelType == 'server'
                              ? Icons.cloud
                              : Icons.phone_android,
                          color: modelType == 'server'
                              ? Colors.blue
                              : Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            modelType == 'server'
                                ? '🌐 Professional AI Server Analysis'
                                : '📱 Local Device Analysis',
                            style: TextStyle(
                              color: modelType == 'server'
                                  ? Colors.blue.shade700
                                  : Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Analysis details
                  Text(
                    'Analysis Mode: ${analysisMode.toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Processing Time: $processingTime'),
                  Text('Model Used: ${modelType.toUpperCase()}'),

                  if (result['fallback_reason'] != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Fallback: ${result['fallback_reason']}',
                              style: const TextStyle(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Health status
                  if (result['health_status'] != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getHealthStatusColor(
                          result['health_status'],
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getHealthStatusColor(result['health_status']),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getHealthStatusIcon(result['health_status']),
                            color: _getHealthStatusColor(
                              result['health_status'],
                            ),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Health Status: ${result['health_status'].toString().toUpperCase()}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getHealthStatusColor(
                                      result['health_status'],
                                    ),
                                    fontSize: 16,
                                  ),
                                ),
                                if (result['confidence'] != null)
                                  Text(
                                    'Confidence: ${result['confidence']}%',
                                    style: TextStyle(
                                      color: _getHealthStatusColor(
                                        result['health_status'],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Prediction details
                  if (result['prediction'] != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Prediction: ${result['prediction']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Show detailed results
                _showDetailedResults(result);
              },
              child: const Text('View Details'),
            ),
          ],
        );
      },
    );
  }

  void _showDetailedResults(Map<String, dynamic> result) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Detailed Analysis Results'),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          body: CropAnalysisResult(result: result),
        ),
      ),
    );
  }

  Color _getHealthStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'healthy':
        return Colors.green;
      case 'unhealthy':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getHealthStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'healthy':
        return Icons.check_circle;
      case 'unhealthy':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  void _testLocalML() {
    final status = _mlService.getModelStatus();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.bug_report, color: Colors.orange),
              SizedBox(width: 8),
              Text('Local ML Debug Info'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Local ML Service Ready: ${status['local_ml_ready']}'),
                  Text('Local Model Status: ${status['local_model_status']}'),
                  Text('Server Available: ${status['server_available']}'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: status['local_model_status']
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: status['local_model_status']
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    child: Text(
                      status['local_model_status']
                          ? '✅ Local ML Model Ready for Fallback'
                          : '❌ Local ML Model Not Ready',
                      style: TextStyle(
                        color: status['local_model_status']
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      await _mlService.refreshLocalModelStatus();
                      navigator.pop();
                      _testLocalML(); // Refresh the dialog
                    },
                    child: const Text('🔄 Refresh Status'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
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
            // Model status indicator
            _buildModelStatusIndicator(),

            const SizedBox(height: 20),

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

            const SizedBox(height: 16),

            // Debug button for testing local ML
            ElevatedButton.icon(
              onPressed: _testLocalML,
              icon: const Icon(Icons.bug_report),
              label: const Text('Test Local ML'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Analysis status
            if (_isAnalyzing)
              const Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Analyzing crop health...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This may take a few seconds',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
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

  Widget _buildModelStatusIndicator() {
    return FutureBuilder<Map<String, dynamic>>(
      future: Future.value(_mlService.getModelStatus()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final status = snapshot.data!;
        final localReady = status['local_model_ready'] ?? false;
        final serverAvailable = status['server_available'] ?? false;
        final preferredModel = status['preferred_model'] ?? 'unknown';

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ML Model Status',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Local model status
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          localReady ? Icons.check_circle : Icons.error,
                          color: localReady ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Local: ${localReady ? "Ready" : "Not Ready"}',
                          style: TextStyle(
                            color: localReady
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Server model status
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          serverAvailable ? Icons.check_circle : Icons.error,
                          color: serverAvailable ? Colors.blue : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Server: ${serverAvailable ? "Online" : "Offline"}',
                          style: TextStyle(
                            color: serverAvailable
                                ? Colors.blue.shade700
                                : Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Mode: ${preferredModel.toUpperCase()}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _mlService.dispose();
    super.dispose();
  }
}
