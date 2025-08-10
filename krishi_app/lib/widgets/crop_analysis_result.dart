import 'package:flutter/material.dart';

class CropAnalysisResult extends StatelessWidget {
  final Map<String, dynamic> result;

  const CropAnalysisResult({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final bool isHealthy = result['is_healthy'] ?? false;
    final String cropType = result['crop_type'] ?? 'Unknown';
    final double confidence = (result['confidence'] ?? 0.0) * 100;
    final int predictionClass = result['prediction_class'] ?? 0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  isHealthy ? Icons.check_circle : Icons.error,
                  color: isHealthy ? Colors.green : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHealthy ? 'Healthy Crop' : 'Unhealthy Crop',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isHealthy ? Colors.green : Colors.red,
                        ),
                      ),
                      Text(
                        'Crop Type: $cropType',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Confidence
            Row(
              children: [
                const Text(
                  'Confidence: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Text(
                  '${confidence.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: confidence > 80
                        ? Colors.green
                        : confidence > 60
                        ? Colors.orange
                        : Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Prediction class
            Text(
              'Prediction Class: $predictionClass',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // All predictions
            if (result['all_predictions'] != null) ...[
              const Text(
                'All Predictions:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ...List.generate((result['all_predictions'] as List).length, (
                index,
              ) {
                double pred = (result['all_predictions'] as List)[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        'Class $index: ',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: pred,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            pred > 0.5 ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(pred * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
