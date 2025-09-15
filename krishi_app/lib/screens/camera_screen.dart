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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Rounded corners for dialog
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0), // Adjusted padding
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0), // Adjusted padding
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16), // Adjusted padding
          title: Row(
            children: [
              Icon(
                modelType == 'server' ? Icons.cloud : Icons.phone_android,
                color: modelType == 'server' ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.primary, // Themed icons
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  modelType == 'server' ? 'Server Analysis' : 'Local Analysis',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
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
                    padding: const EdgeInsets.all(10), // Adjusted padding
                    decoration: BoxDecoration(
                      color: modelType == 'server'
                          ? Theme.of(context).colorScheme.secondary.withOpacity(0.08)
                          : Theme.of(context).colorScheme.primary.withOpacity(0.08), // Themed colors
                      borderRadius: BorderRadius.circular(10), // Rounded corners
                      border: Border.all(
                        color: modelType == 'server'
                            ? Theme.of(context).colorScheme.secondary.withOpacity(0.3)
                            : Theme.of(context).colorScheme.primary.withOpacity(0.3), // Subtle border
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
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(context).colorScheme.primary, // Themed icons
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            modelType == 'server'
                                ? '🌐 Professional AI Server Analysis'
                                : '📱 Local Device Analysis',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: modelType == 'server'
                                  ? Theme.of(context).colorScheme.secondary.withOpacity(0.9)
                                  : Theme.of(context).colorScheme.primary.withOpacity(0.9),
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
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Processing Time: $processingTime',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Model Used: ${modelType.toUpperCase()}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),

                  if (result['fallback_reason'] != null) ...[
                    const SizedBox(height: 12), // Adjusted spacing
                    Container(
                      padding: const EdgeInsets.all(10), // Adjusted padding
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10), // Rounded corners
                        border: Border.all(color: Colors.orange.shade300, width: 1), // Subtle border
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade700), // Themed icon
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Fallback: ${result['fallback_reason']}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.orange.shade700),
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
                      padding: const EdgeInsets.all(14), // More generous padding
                      decoration: BoxDecoration(
                        color: _getHealthStatusColor(
                          result['health_status'],
                        ).withOpacity(0.1), // Subtle background
                        borderRadius: BorderRadius.circular(10), // Rounded corners
                        border: Border.all(
                          color: _getHealthStatusColor(result['health_status']).withOpacity(0.5), // Subtle border
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getHealthStatusIcon(result['health_status']),
                            color: _getHealthStatusColor(
                              result['health_status'],
                            ),
                            size: 28, // Larger icon
                          ),
                          const SizedBox(width: 14), // Increased spacing
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Health Status: ${result['health_status'].toString().toUpperCase()}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: _getHealthStatusColor(
                                      result['health_status'],
                                    ),
                                  ),
                                ),
                                if (result['confidence'] != null)
                                  Text(
                                    'Confidence: ${result['confidence']}%',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: _getHealthStatusColor(
                                        result['health_status'],
                                      ).withOpacity(0.8),
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
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
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
            // backgroundColor and foregroundColor are now handled by AppBarTheme in main.dart
          ),
          body: CropAnalysisResult(result: result),
        ),
      ),
    );
  }

  Color _getHealthStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'healthy':
        return Theme.of(context).colorScheme.primary; // Use primary color for healthy
      case 'unhealthy':
        return Theme.of(context).colorScheme.error; // Use error color for unhealthy
      default:
        return Colors.orange.shade700; // Keep orange for default/unknown
    }
  }

  IconData _getHealthStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'healthy':
        return Icons.check_circle_outline; // More subtle checkmark
      case 'unhealthy':
        return Icons.warning_amber_rounded; // More subtle warning
      default:
        return Icons.help_outline_rounded; // More subtle help
    }
  }

  void _testLocalML() {
    final status = _mlService.getModelStatus();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Icon(Icons.bug_report, color: Theme.of(context).colorScheme.secondary), // Themed icon
              const SizedBox(width: 10),
              Text(
                'Local ML Debug Info',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
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
                  Text(
                    'Local ML Service Ready: ${status['local_ml_ready']}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Local Model Status: ${status['local_model_status']}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Server Available: ${status['server_available']}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (status['local_model_status']
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error)
                          .withOpacity(0.08), // Themed colors
                      borderRadius: BorderRadius.circular(10), // Rounded corners
                      border: Border.all(
                        color: (status['local_model_status']
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.error)
                            .withOpacity(0.3), // Subtle border
                      ),
                    ),
                    child: Text(
                      status['local_model_status']
                          ? '✅ Local ML Model Ready for Fallback'
                          : '❌ Local ML Model Not Ready',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: status['local_model_status']
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.9)
                            : Theme.of(context).colorScheme.error.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
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
              child: Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error, // Themed error color
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
        title: Text('Crop Health Analysis'), // Removed const
        // backgroundColor and foregroundColor are now handled by AppBarTheme in main.dart
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
                  // Style is now handled by ElevatedButtonThemeData in main.dart
                ),
                ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary, // Use secondary color for gallery
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
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
                    backgroundColor: Colors.orange.shade700, // Keep orange for debug
                    foregroundColor: Colors.white,
                  ),
                ),

            const SizedBox(height: 20),

            // Analysis status
            if (_isAnalyzing)
              Column( // Removed const
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary), // Themed progress indicator
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Analyzing crop health...',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This may take a few seconds',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
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
          padding: const EdgeInsets.all(14), // Adjusted padding
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface, // Use surface color
            borderRadius: BorderRadius.circular(12), // Rounded corners
            border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)), // Subtle border
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.psychology_outlined, // More subtle icon
                    color: Theme.of(context).colorScheme.primary, // Themed icon
                    size: 22, // Adjusted size
                  ),
                  const SizedBox(width: 10), // Adjusted spacing
                  Text(
                    'ML Model Status',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 10), // Adjusted spacing
              Row(
                children: [
                  // Local model status
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          localReady ? Icons.check_circle_outline : Icons.error_outline, // More subtle icons
                          color: localReady ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error, // Themed colors
                          size: 18, // Adjusted size
                        ),
                        const SizedBox(width: 6), // Adjusted spacing
                        Text(
                          'Local: ${localReady ? "Ready" : "Not Ready"}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: localReady
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.9)
                                : Theme.of(context).colorScheme.error.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
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
                          serverAvailable ? Icons.check_circle_outline : Icons.error_outline, // More subtle icons
                          color: serverAvailable ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.error, // Themed colors
                          size: 18, // Adjusted size
                        ),
                        const SizedBox(width: 6), // Adjusted spacing
                        Text(
                          'Server: ${serverAvailable ? "Online" : "Offline"}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: serverAvailable
                                ? Theme.of(context).colorScheme.secondary.withOpacity(0.9)
                                : Theme.of(context).colorScheme.error.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6), // Adjusted spacing
              Text(
                'Mode: ${preferredModel.toUpperCase()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
