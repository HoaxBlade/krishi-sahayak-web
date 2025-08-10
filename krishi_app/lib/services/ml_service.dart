import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class MLService {
  static const String baseUrl =
      'http://10.5.171.78:5001'; // For physical device
  // Use 'http://10.0.2.2:5001' for Android emulator
  // Use 'http://localhost:5001' for iOS simulator

  final http.Client _client = http.Client();

  Future<Map<String, dynamic>> analyzeCropHealth(XFile imageFile) async {
    try {
      // Read image file
      Uint8List imageBytes = await imageFile.readAsBytes();

      // Convert to base64
      String base64Image = base64Encode(imageBytes);
      String imageData = 'data:image/jpeg;base64,$base64Image';

      // Prepare request
      final response = await _client.post(
        Uri.parse('$baseUrl/analyze_crop'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': imageData}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to analyze image: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error analyzing crop: $e');
    }
  }

  Future<bool> checkServerHealth() async {
    try {
      final response = await _client.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}
