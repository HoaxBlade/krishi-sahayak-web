import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/disease_info.dart';

class GeminiDiseaseService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String _model = 'gemini-2.5-flash';

  // Get API key from environment variables
  static String get _apiKey =>
      dotenv.env['GEMINI_API_KEY'] ?? 'YOUR_GEMINI_API_KEY_HERE';

  /// Get comprehensive disease information using Gemini AI
  static Future<DiseaseInfo> getDiseaseInfo({
    required String diseaseName,
    required String cropType,
  }) async {
    try {
      final prompt = _buildDiseasePrompt(diseaseName, cropType);
      final response = await _callGeminiAPI(prompt);

      if (response != null) {
        return _parseDiseaseResponse(response, diseaseName, cropType);
      } else {
        return _getDefaultDiseaseInfo(diseaseName, cropType);
      }
    } catch (e) {
      debugPrint('❌ [GeminiDiseaseService] Error getting disease info: $e');
      return _getDefaultDiseaseInfo(diseaseName, cropType);
    }
  }

  /// Build the prompt for Gemini API
  static String _buildDiseasePrompt(String diseaseName, String cropType) {
    return '''
You are an agricultural expert. I need you to provide detailed information about the disease "$diseaseName" affecting "$cropType" crops.

IMPORTANT: You MUST respond with ONLY valid JSON format. Do not include any additional text, explanations, or formatting outside the JSON.

Respond with this exact JSON structure:
{
  "diseaseName": "$diseaseName",
  "cropType": "$cropType",
  "description": "Brief description of the disease",
  "symptoms": ["symptom1", "symptom2", "symptom3"],
  "causes": ["cause1", "cause2", "cause3"],
  "preventionMethods": ["prevention1", "prevention2", "prevention3"],
  "treatmentOptions": ["treatment1", "treatment2", "treatment3"],
  "severity": "low",
  "seasonality": "When this disease typically occurs",
  "environmentalConditions": "Environmental factors that favor this disease"
}

Focus on:
1. Practical symptoms farmers can observe
2. Actionable prevention methods
3. Effective treatment options
4. Environmental conditions that trigger the disease
5. Seasonal patterns

Make the information farmer-friendly and practical. Respond with ONLY the JSON object, no other text.
''';
  }

  /// Call Gemini API
  static Future<String?> _callGeminiAPI(String prompt) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/models/$_model:generateContent?key=$_apiKey',
      );

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.3,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 2048,
          'responseMimeType': 'application/json',
        },
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      } else {
        debugPrint(
          '❌ [GeminiDiseaseService] API Error: ${response.statusCode}',
        );
        debugPrint('Response: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [GeminiDiseaseService] Network Error: $e');
      return null;
    }
  }

  /// Parse Gemini response into DiseaseInfo object
  static DiseaseInfo _parseDiseaseResponse(
    String response,
    String diseaseName,
    String cropType,
  ) {
    try {
      // Clean the response - remove any leading/trailing whitespace
      String cleanedResponse = response.trim();

      // Try to find JSON in the response
      final jsonStart = cleanedResponse.indexOf('{');
      final jsonEnd = cleanedResponse.lastIndexOf('}') + 1;

      if (jsonStart != -1 && jsonEnd > jsonStart) {
        final jsonString = cleanedResponse.substring(jsonStart, jsonEnd);
        debugPrint('🔍 [GeminiDiseaseService] Extracted JSON: $jsonString');

        final Map<String, dynamic> data = jsonDecode(jsonString);
        return DiseaseInfo.fromMap(data);
      } else {
        // If no JSON found, try to parse the entire response as JSON
        debugPrint(
          '🔍 [GeminiDiseaseService] No JSON markers found, trying full response',
        );
        final Map<String, dynamic> data = jsonDecode(cleanedResponse);
        return DiseaseInfo.fromMap(data);
      }
    } catch (e) {
      debugPrint('❌ [GeminiDiseaseService] Error parsing response: $e');
      debugPrint('Raw response: $response');

      // Try to extract information from text response as fallback
      return _parseTextResponse(response, diseaseName, cropType);
    }
  }

  /// Parse text response as fallback when JSON parsing fails
  static DiseaseInfo _parseTextResponse(
    String response,
    String diseaseName,
    String cropType,
  ) {
    debugPrint('🔄 [GeminiDiseaseService] Attempting text parsing fallback');

    // Extract key information from text response
    String description = _extractTextSection(response, [
      'description',
      'overview',
      'about',
    ]);
    List<String> symptoms = _extractListFromText(response, [
      'symptoms',
      'signs',
      'indicators',
    ]);
    List<String> prevention = _extractListFromText(response, [
      'prevention',
      'prevent',
      'avoid',
    ]);
    List<String> treatment = _extractListFromText(response, [
      'treatment',
      'control',
      'manage',
    ]);

    return DiseaseInfo(
      diseaseName: diseaseName,
      cropType: cropType,
      description: description.isNotEmpty
          ? description
          : 'Disease information retrieved from AI analysis.',
      symptoms: symptoms.isNotEmpty
          ? symptoms
          : ['Visual symptoms may include spots, discoloration, or wilting'],
      causes: [
        'Environmental factors',
        'Pathogen presence',
        'Poor growing conditions',
      ],
      preventionMethods: prevention.isNotEmpty
          ? prevention
          : [
              'Maintain proper plant spacing for air circulation',
              'Use disease-resistant varieties when available',
              'Practice crop rotation',
            ],
      treatmentOptions: treatment.isNotEmpty
          ? treatment
          : [
              'Consult with local agricultural extension services',
              'Use approved fungicides or treatments as recommended',
            ],
      severity: 'moderate',
      seasonality: 'Can occur throughout growing season',
      environmentalConditions:
          'Favored by humid conditions and poor air circulation',
      lastUpdated: DateTime.now(),
    );
  }

  /// Extract text section from response
  static String _extractTextSection(String response, List<String> keywords) {
    for (String keyword in keywords) {
      final pattern = RegExp('$keyword[\\s:]*([^\\n]+)', caseSensitive: false);
      final match = pattern.firstMatch(response);
      if (match != null) {
        return match.group(1)?.trim() ?? '';
      }
    }
    return '';
  }

  /// Extract list items from text response
  static List<String> _extractListFromText(
    String response,
    List<String> keywords,
  ) {
    List<String> items = [];
    for (String keyword in keywords) {
      final pattern = RegExp(
        '$keyword[\\s:]*([^\\n]+(?:\\n[^\\n]+)*)',
        caseSensitive: false,
      );
      final match = pattern.firstMatch(response);
      if (match != null) {
        String text = match.group(1)?.trim() ?? '';
        // Split by common list indicators
        items = text
            .split(RegExp(r'[•\-\*]\s*|\d+\.\s*'))
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
        if (items.isNotEmpty) break;
      }
    }
    return items;
  }

  /// Get default disease info when API fails
  static DiseaseInfo _getDefaultDiseaseInfo(
    String diseaseName,
    String cropType,
  ) {
    return DiseaseInfo(
      diseaseName: diseaseName,
      cropType: cropType,
      description:
          'Information about $diseaseName in $cropType crops. Please check with local agricultural experts for detailed guidance.',
      symptoms: [
        'Visual symptoms may include spots, discoloration, or wilting',
        'Monitor plant growth and development regularly',
        'Check for unusual patterns on leaves, stems, or fruits',
      ],
      causes: [
        'Environmental factors',
        'Pathogen presence',
        'Poor growing conditions',
      ],
      preventionMethods: [
        'Maintain proper plant spacing for air circulation',
        'Use disease-resistant varieties when available',
        'Practice crop rotation',
        'Ensure proper irrigation and drainage',
        'Remove and destroy infected plant material',
      ],
      treatmentOptions: [
        'Consult with local agricultural extension services',
        'Use approved fungicides or treatments as recommended',
        'Improve growing conditions',
        'Consider biological control methods',
      ],
      severity: 'moderate',
      seasonality: 'Can occur throughout growing season',
      environmentalConditions:
          'Favored by humid conditions and poor air circulation',
      lastUpdated: DateTime.now(),
    );
  }

  /// Get quick disease summary (shorter response)
  static Future<String> getDiseaseSummary({
    required String diseaseName,
    required String cropType,
  }) async {
    try {
      final prompt =
          '''
Provide a brief summary (2-3 sentences) about "$diseaseName" disease in "$cropType" crops, including:
1. Main symptoms
2. Key prevention method
3. When it typically occurs

Keep it concise and farmer-friendly.
''';

      final response = await _callGeminiAPI(prompt);
      return response ?? 'Unable to get disease information at this time.';
    } catch (e) {
      debugPrint('❌ [GeminiDiseaseService] Error getting summary: $e');
      return 'Unable to get disease information at this time.';
    }
  }

  /// Check if API key is configured
  static bool get isApiKeyConfigured {
    return _apiKey != 'YOUR_GEMINI_API_KEY_HERE' && _apiKey.isNotEmpty;
  }
}
