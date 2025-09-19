import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CropAnalysisResult extends StatefulWidget {
  final Map<String, dynamic> result;

  const CropAnalysisResult({super.key, required this.result});

  @override
  State<CropAnalysisResult> createState() => _CropAnalysisResultState();
}

class _CropAnalysisResultState extends State<CropAnalysisResult> {
  late SharedPreferences _prefs;
  bool _isHindiSelected = true; // Default to Hindi

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _isHindiSelected = _prefs.getBool('isHindi') ?? true;
    });
  }

  Future<void> _toggleLanguage(bool value) async {
    setState(() {
      _isHindiSelected = value;
    });
    await _prefs.setBool('isHindi', _isHindiSelected);
  }

  @override
  Widget build(BuildContext context) {
    final bool isHealthy = widget.result['is_healthy'] ?? false;
    final String cropType = widget.result['crop_type'] ?? 'Unknown';
    final String? geminiAnalysisEnglish =
        widget.result['gemini_analysis_english'];
    final String? geminiAnalysisHindi = widget.result['gemini_analysis_hindi'];

    // Safely convert confidence to double
    double confidence = 0.0;
    if (widget.result['confidence'] != null) {
      if (widget.result['confidence'] is String) {
        confidence =
            double.tryParse(widget.result['confidence'] as String) ?? 0.0;
      } else if (widget.result['confidence'] is num) {
        confidence = (widget.result['confidence'] as num).toDouble();
      }
    }
    confidence = confidence * 100;

    // Safely convert prediction class to int
    int predictionClass = 0;
    if (widget.result['prediction_class'] != null) {
      if (widget.result['prediction_class'] is String) {
        predictionClass =
            int.tryParse(widget.result['prediction_class'] as String) ?? 0;
      } else if (widget.result['prediction_class'] is num) {
        predictionClass = (widget.result['prediction_class'] as num).toInt();
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
                    isHealthy
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_rounded, // More subtle icons
                    color: isHealthy
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error, // Themed colors
                    size: 36, // Larger icon
                  ),
                  const SizedBox(width: 14), // Increased spacing
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isHealthy ? 'Healthy Crop' : 'Unhealthy Crop',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isHealthy
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.error,
                              ),
                        ),
                        Text(
                          'Crop Type: $cropType',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24), // Increased spacing
              // Enhanced Confidence Display for Multitask Models
              if (widget.result['model_type'] == 'multitask' ||
                  widget.result['regression_confidence'] != null) ...[
                // Regression Confidence (Primary)
                Row(
                  children: [
                    Text(
                      'AI Confidence: ',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(widget.result['regression_confidence'] ?? confidence * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color:
                            (widget.result['regression_confidence'] ??
                                    confidence * 100) >
                                80
                            ? Theme.of(context).colorScheme.primary
                            : (widget.result['regression_confidence'] ??
                                      confidence * 100) >
                                  60
                            ? Colors.orange.shade700
                            : Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Class Confidence (Secondary)
                Row(
                  children: [
                    Text(
                      'Class Confidence: ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      '${(widget.result['class_confidence'] ?? confidence * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Model Type Indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.psychology,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Enhanced AI Analysis',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Standard Confidence Display
                Row(
                  children: [
                    Text(
                      'Confidence: ',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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
              ],

              const SizedBox(height: 16), // Increased spacing
              // Prediction class
              Text(
                'Prediction Class: $predictionClass',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),

              const SizedBox(height: 24), // Increased spacing
              // Gemini Analysis Section
              if (geminiAnalysisEnglish != null ||
                  geminiAnalysisHindi != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detailed Analysis',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'English',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: _isHindiSelected
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.6)
                                    : Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        Switch(
                          value: _isHindiSelected,
                          onChanged: _toggleLanguage,
                          activeColor: Theme.of(context).colorScheme.primary,
                          inactiveThumbColor: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                          inactiveTrackColor: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.3),
                        ),
                        Text(
                          'हिंदी',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: _isHindiSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _isHindiSelected
                      ? (geminiAnalysisHindi ?? 'No Hindi analysis available.')
                      : (geminiAnalysisEnglish ??
                            'No English analysis available.'),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
              ],

              // All predictions
              if (widget.result['all_predictions'] != null) ...[
                Text(
                  'All Predictions:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10), // Increased spacing
                Builder(
                  builder: (context) {
                    // Safely extract predictions from the 4D tensor structure
                    List<double> predictions = [];
                    try {
                      final allPredictions = widget.result['all_predictions'];
                      if (allPredictions is List) {
                        // Handle 4D tensor: List<List<List<List<double>>>>
                        if (allPredictions.isNotEmpty &&
                            allPredictions[0] is List &&
                            allPredictions[0].isNotEmpty &&
                            allPredictions[0][0] is List &&
                            allPredictions[0][0].isNotEmpty &&
                            allPredictions[0][0][0] is List) {
                          // Extract the first batch's predictions
                          predictions = (allPredictions[0][0][0] as List)
                              .cast<double>();
                        } else if (allPredictions.isNotEmpty &&
                            allPredictions[0] is num) {
                          // Handle simple list of numbers
                          predictions = allPredictions.cast<double>();
                        }
                      }
                    } catch (e) {
                      debugPrint('Error extracting predictions: $e');
                    }

                    if (predictions.isEmpty) {
                      return Text(
                        'No prediction data available',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      );
                    }

                    return Column(
                      children: List.generate(predictions.length, (index) {
                        final pred = predictions[index];

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Text(
                                'Class $index: ',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.8),
                                    ),
                              ),
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: pred,
                                  minHeight: 6,
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    pred > 0.5
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.3),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${(pred * 100).toStringAsFixed(1)}%',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                              ),
                            ],
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
