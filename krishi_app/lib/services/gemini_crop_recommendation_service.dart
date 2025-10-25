import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/crop_recommendation.dart';

class GeminiCropRecommendationService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String _model = 'gemini-2.5-flash';

  // Get API key from environment variables
  static String get _apiKey =>
      dotenv.env['GEMINI_API_KEY'] ?? 'YOUR_GEMINI_API_KEY_HERE';

  /// Get crop recommendations based on location, climate, and season
  static Future<List<CropRecommendation>> getCropRecommendations({
    required String location,
    required String climate,
    required String season,
    required String soilType,
  }) async {
    try {
      debugPrint(
        '🤖 [GeminiCropRecommendationService] Starting crop recommendations request',
      );
      debugPrint('   Location: $location');
      debugPrint('   Climate: $climate');
      debugPrint('   Season: $season');
      debugPrint('   Soil Type: $soilType');

      final prompt = _buildCropRecommendationPrompt(
        location: location,
        climate: climate,
        season: season,
        soilType: soilType,
      );

      debugPrint('🤖 [GeminiCropRecommendationService] Calling Gemini API...');
      final response = await _callGeminiAPI(prompt);

      if (response != null) {
        debugPrint(
          '✅ [GeminiCropRecommendationService] API call successful, parsing response',
        );
        return _parseCropRecommendationsResponse(response);
      } else {
        debugPrint(
          '⚠️ [GeminiCropRecommendationService] API call failed, using default recommendations',
        );
        return getDefaultCropRecommendations();
      }
    } catch (e) {
      debugPrint(
        '❌ [GeminiCropRecommendationService] Error getting crop recommendations: $e',
      );
      return getDefaultCropRecommendations();
    }
  }

  /// Build the prompt for Gemini API
  static String _buildCropRecommendationPrompt({
    required String location,
    required String climate,
    required String season,
    required String soilType,
  }) {
    return '''
You are an agricultural expert specializing in crop recommendations for farmers. I need you to recommend 5 suitable crops for the following conditions:

Location: $location
Climate: $climate
Season: $season
Soil Type: $soilType

IMPORTANT: You MUST respond with ONLY valid JSON format. Do not include any additional text, explanations, or formatting outside the JSON.

Respond with this exact JSON structure:
{
  "crops": [
    {
      "name": "Crop Name",
      "description": "Brief description of the crop and why it's suitable",
      "season": "Best planting season",
      "climate": "Climate requirements",
      "soilType": "Soil type preferences",
      "waterRequirement": "Water needs (low/medium/high)",
      "yieldPotential": "Expected yield potential",
      "marketValue": "Market value and demand",
      "benefits": ["Benefit 1", "Benefit 2", "Benefit 3"],
      "challenges": ["Challenge 1", "Challenge 2"]
    }
  ]
}

Provide 5 different crops that are suitable for the given conditions. Focus on crops that are commonly grown in the specified location and climate.
''';
  }

  /// Call Gemini API
  static Future<Map<String, dynamic>?> _callGeminiAPI(String prompt) async {
    try {
      debugPrint(
        '🤖 [GeminiCropRecommendationService] API Key configured: ${_apiKey != 'YOUR_GEMINI_API_KEY_HERE'}',
      );
      final url = '$_baseUrl/models/$_model:generateContent?key=$_apiKey';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 4096,
          },
        }),
      );

      debugPrint(
        '🤖 [GeminiCropRecommendationService] API Response Status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'];

        debugPrint(
          '🤖 [GeminiCropRecommendationService] Raw API Response: $content',
        );

        if (content != null) {
          // Try to extract JSON from the response (handle markdown code blocks)
          String jsonContent = content;

          // Remove markdown code blocks if present
          if (content.contains('```json')) {
            final codeBlockMatch = RegExp(
              r'```json\s*(.*?)\s*```',
              dotAll: true,
            ).firstMatch(content);
            if (codeBlockMatch != null) {
              jsonContent = codeBlockMatch.group(1)!.trim();
            }
          } else if (content.contains('```')) {
            final codeBlockMatch = RegExp(
              r'```\s*(.*?)\s*```',
              dotAll: true,
            ).firstMatch(content);
            if (codeBlockMatch != null) {
              jsonContent = codeBlockMatch.group(1)!.trim();
            }
          }

          // Try to extract JSON by finding the complete structure
          String cleanJson = jsonContent;

          // Remove markdown code blocks
          if (cleanJson.contains('```json')) {
            cleanJson = cleanJson
                .replaceAll('```json', '')
                .replaceAll('```', '')
                .trim();
          } else if (cleanJson.contains('```')) {
            cleanJson = cleanJson.replaceAll('```', '').trim();
          }

          debugPrint(
            '🧹 [GeminiCropRecommendationService] Cleaned JSON: $cleanJson',
          );

          try {
            return jsonDecode(cleanJson);
          } catch (e) {
            debugPrint(
              '❌ [GeminiCropRecommendationService] Direct parsing failed: $e',
            );

            // Try to find the JSON object boundaries
            final startIndex = cleanJson.indexOf('{');
            final lastIndex = cleanJson.lastIndexOf('}');

            if (startIndex != -1 && lastIndex != -1 && lastIndex > startIndex) {
              final jsonSubstring = cleanJson.substring(
                startIndex,
                lastIndex + 1,
              );
              debugPrint(
                '🔍 [GeminiCropRecommendationService] Trying substring: $jsonSubstring',
              );

              try {
                return jsonDecode(jsonSubstring);
              } catch (e2) {
                debugPrint(
                  '❌ [GeminiCropRecommendationService] Substring parsing failed: $e2',
                );
                return _tryToFixJson(jsonSubstring);
              }
            }
          }
        } else {
          debugPrint(
            '⚠️ [GeminiCropRecommendationService] No content in API response',
          );
        }
      }

      debugPrint(
        '❌ [GeminiCropRecommendationService] API call failed: ${response.statusCode}',
      );
      return null;
    } catch (e) {
      debugPrint('❌ [GeminiCropRecommendationService] API call error: $e');
      return null;
    }
  }

  /// Try to fix common JSON issues
  static Map<String, dynamic>? _tryToFixJson(String jsonString) {
    try {
      debugPrint(
        '🔧 [GeminiCropRecommendationService] Original JSON: $jsonString',
      );

      // Remove any trailing commas
      String fixedJson = jsonString.replaceAll(RegExp(r',\s*}'), '}');
      fixedJson = fixedJson.replaceAll(RegExp(r',\s*\]'), ']');

      // Count braces and brackets to ensure proper closure
      int openBraces = fixedJson.split('{').length - 1;
      int closeBraces = fixedJson.split('}').length - 1;
      int openBrackets = fixedJson.split('[').length - 1;
      int closeBrackets = fixedJson.split(']').length - 1;

      debugPrint(
        '🔧 [GeminiCropRecommendationService] Brace count: {$openBraces:$closeBraces}, Bracket count: [$openBrackets:$closeBrackets]',
      );

      // Add missing closing brackets first
      if (openBrackets > closeBrackets) {
        fixedJson += ']' * (openBrackets - closeBrackets);
      }

      // Then add missing closing braces
      if (openBraces > closeBraces) {
        fixedJson += '}' * (openBraces - closeBraces);
      }

      debugPrint('🔧 [GeminiCropRecommendationService] Fixed JSON: $fixedJson');
      return jsonDecode(fixedJson);
    } catch (e) {
      debugPrint('❌ [GeminiCropRecommendationService] Failed to fix JSON: $e');
      return null;
    }
  }

  /// Parse the response from Gemini API
  static List<CropRecommendation> _parseCropRecommendationsResponse(
    Map<String, dynamic> response,
  ) {
    try {
      final crops = response['crops'] as List<dynamic>?;
      if (crops != null) {
        return crops.map((crop) => CropRecommendation.fromJson(crop)).toList();
      }
    } catch (e) {
      debugPrint(
        '❌ [GeminiCropRecommendationService] Error parsing response: $e',
      );
    }

    return getDefaultCropRecommendations();
  }

  /// Get default crop recommendations when API fails
  static List<CropRecommendation> getDefaultCropRecommendations() {
    return [
      CropRecommendation(
        name: 'Rice',
        description:
            'Staple food crop suitable for tropical and subtropical regions with adequate water supply.',
        season: 'Kharif (June-October)',
        climate: 'Tropical/Subtropical',
        soilType: 'Clayey/Alluvial',
        waterRequirement: 'High',
        yieldPotential: 'High',
        marketValue: 'High demand, stable prices',
        benefits: [
          'High yield potential',
          'Stable market demand',
          'Multiple varieties available',
        ],
        challenges: [
          'High water requirement',
          'Susceptible to pests',
          'Labor intensive',
        ],
      ),
      CropRecommendation(
        name: 'Wheat',
        description:
            'Winter cereal crop ideal for temperate regions with good irrigation facilities.',
        season: 'Rabi (October-March)',
        climate: 'Temperate',
        soilType: 'Loamy/Clayey',
        waterRequirement: 'Medium',
        yieldPotential: 'High',
        marketValue: 'High demand, government support',
        benefits: [
          'High nutritional value',
          'Government MSP support',
          'Multiple uses',
        ],
        challenges: [
          'Requires good irrigation',
          'Susceptible to rust',
          'Storage requirements',
        ],
      ),
      CropRecommendation(
        name: 'Maize',
        description:
            'Versatile crop suitable for various climates and soil types with good market potential.',
        season: 'Kharif/Rabi',
        climate: 'Tropical/Temperate',
        soilType: 'Well-drained',
        waterRequirement: 'Medium',
        yieldPotential: 'High',
        marketValue: 'Growing demand for feed',
        benefits: [
          'Multiple uses',
          'Good market price',
          'Less water requirement',
        ],
        challenges: [
          'Pest management',
          'Post-harvest handling',
          'Storage needs',
        ],
      ),
      CropRecommendation(
        name: 'Sugarcane',
        description:
            'Cash crop with high sugar content, suitable for tropical regions with adequate water.',
        season: 'Year-round',
        climate: 'Tropical',
        soilType: 'Deep, fertile',
        waterRequirement: 'High',
        yieldPotential: 'Very High',
        marketValue: 'High value crop',
        benefits: [
          'High income potential',
          'Multiple products',
          'Long-term crop',
        ],
        challenges: [
          'High initial investment',
          'Long gestation period',
          'Water intensive',
        ],
      ),
      CropRecommendation(
        name: 'Cotton',
        description:
            'Fiber crop suitable for dry regions with good irrigation and pest management.',
        season: 'Kharif',
        climate: 'Semi-arid',
        soilType: 'Black cotton soil',
        waterRequirement: 'Medium',
        yieldPotential: 'Medium-High',
        marketValue: 'Export potential',
        benefits: ['High value fiber', 'Export market', 'Multiple varieties'],
        challenges: [
          'Pest management',
          'Quality maintenance',
          'Market fluctuations',
        ],
      ),
    ];
  }
}
