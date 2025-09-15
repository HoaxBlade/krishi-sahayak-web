import 'package:flutter/material.dart';

class CropAnalysisResult extends StatelessWidget {
  final Map<String, dynamic> result;

  const CropAnalysisResult({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final bool isHealthy = result['is_healthy'] ?? false;
    final String cropType = result['crop_type'] ?? 'Unknown';

    // Safely convert confidence to double
    double confidence = 0.0;
    if (result['confidence'] != null) {
      if (result['confidence'] is String) {
        confidence = double.tryParse(result['confidence'] as String) ?? 0.0;
      } else if (result['confidence'] is num) {
        confidence = (result['confidence'] as num).toDouble();
      }
    }
    confidence = confidence * 100;

    // Safely convert prediction class to int
    int predictionClass = 0;
    if (result['prediction_class'] != null) {
      if (result['prediction_class'] is String) {
        predictionClass =
            int.tryParse(result['prediction_class'] as String) ?? 0;
      } else if (result['prediction_class'] is num) {
        predictionClass = (result['prediction_class'] as num).toInt();
      }
    }

    return Card(
      // elevation is now handled by CardThemeData
      child: Padding(
        padding: const EdgeInsets.all(20.0), // More generous padding
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    isHealthy ? Icons.check_circle_outline : Icons.warning_amber_rounded, // More subtle icons
                    color: isHealthy ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error, // Themed colors
                    size: 36, // Larger icon
                  ),
                  const SizedBox(width: 14), // Increased spacing
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isHealthy ? 'Healthy Crop' : 'Unhealthy Crop',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isHealthy ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
                          ),
                        ),
                        Text(
                          'Crop Type: $cropType',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24), // Increased spacing

              // Confidence
              Row(
                children: [
                  Text(
                    'Confidence: ',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${confidence.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: confidence > 80
                          ? Theme.of(context).colorScheme.primary
                          : confidence > 60
                          ? Colors.orange.shade700
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16), // Increased spacing

              // Prediction class
              Text(
                'Prediction Class: $predictionClass',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              ),

              const SizedBox(height: 24), // Increased spacing

              // All predictions
              if (result['all_predictions'] != null) ...[
                Text(
                  'All Predictions:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10), // Increased spacing
                ...List.generate((result['all_predictions'] as List).length, (
                  index,
                ) {
                  // Safely convert prediction to double
                  double pred = 0.0;
                  final predictionValue =
                      (result['all_predictions'] as List)[index];
                  if (predictionValue is String) {
                    pred = double.tryParse(predictionValue) ?? 0.0;
                  } else if (predictionValue is num) {
                    pred = (predictionValue).toDouble();
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4), // Adjusted vertical padding
                    child: Row(
                      children: [
                        Text(
                          'Class $index: ',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: pred,
                            minHeight: 6, // Slightly thicker progress bar
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest, // Themed background
                            valueColor: AlwaysStoppedAnimation<Color>(
                              pred > 0.5 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.3), // Themed colors
                            ),
                          ),
                        ),
                        const SizedBox(width: 10), // Increased spacing
                        Text(
                          '${(pred * 100).toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
