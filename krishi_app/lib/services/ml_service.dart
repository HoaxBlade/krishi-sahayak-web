// ignore_for_file: unnecessary_import

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'connectivity_service.dart';

class MLService {
  static const String baseUrl =
      'https://krishi-ml-server.onrender.com'; // Deployed server on Render
  // Use 'http://10.0.2.2:5001' for Android emulator
  // Use 'http://localhost:5001' for iOS simulator

  final http.Client _client = http.Client();
  final ConnectivityService _connectivityService = ConnectivityService();

  Future<Map<String, dynamic>> analyzeCropHealth(XFile imageFile) async {
    final stopwatch = Stopwatch()..start();
    debugPrint('🚀 [MLService] Starting crop health analysis...');

    try {
      // Check connectivity first
      debugPrint('📡 [MLService] Checking network connectivity...');
      final connectivityStart = Stopwatch()..start();
      bool isConnected = await _connectivityService.checkConnectivity();
      connectivityStart.stop();
      debugPrint(
        '📡 [MLService] Connectivity check completed in ${connectivityStart.elapsedMilliseconds}ms',
      );

      if (!isConnected) {
        debugPrint('❌ [MLService] No network connectivity available');
        throw Exception('No network connectivity available');
      }
      debugPrint('✅ [MLService] Network connectivity confirmed');

      // Track image reading
      debugPrint('📖 [MLService] Reading image file...');
      final imageReadStart = Stopwatch()..start();
      Uint8List imageBytes = await imageFile.readAsBytes();
      imageReadStart.stop();
      debugPrint(
        '✅ [MLService] Image read completed in ${imageReadStart.elapsedMilliseconds}ms',
      );
      debugPrint(
        '📊 [MLService] Image size: ${imageBytes.length} bytes (${(imageBytes.length / 1024).toStringAsFixed(2)} KB)',
      );

      // Track base64 conversion
      debugPrint('🔄 [MLService] Converting image to base64...');
      final base64Start = Stopwatch()..start();
      String base64Image = base64Encode(imageBytes);
      String imageData = 'data:image/jpeg;base64,$base64Image';
      base64Start.stop();
      debugPrint(
        '✅ [MLService] Base64 conversion completed in ${base64Start.elapsedMilliseconds}ms',
      );
      debugPrint(
        '📊 [MLService] Base64 string length: ${imageData.length} characters',
      );

      // Track network request preparation
      debugPrint(
        '🌐 [MLService] Preparing network request to $baseUrl/analyze_crop...',
      );
      debugPrint(
        '📊 [MLService] Request payload size: ${jsonEncode({'image': imageData}).length} characters',
      );
      final requestStart = Stopwatch()..start();

      // Prepare request
      final response = await _client.post(
        Uri.parse('$baseUrl/analyze_crop'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': imageData}),
      );

      requestStart.stop();
      debugPrint(
        '✅ [MLService] Network request completed in ${requestStart.elapsedMilliseconds}ms',
      );
      debugPrint('📊 [MLService] Response status: ${response.statusCode}');
      debugPrint(
        '📊 [MLService] Response body length: ${response.body.length} characters',
      );
      debugPrint('📊 [MLService] Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        stopwatch.stop();
        debugPrint(
          '🎉 [MLService] Analysis completed successfully in ${stopwatch.elapsedMilliseconds}ms total',
        );
        debugPrint('📊 [MLService] Final result keys: ${result.keys.toList()}');
        return result;
      } else {
        stopwatch.stop();
        debugPrint(
          '❌ [MLService] Server returned error status ${response.statusCode} after ${stopwatch.elapsedMilliseconds}ms',
        );
        debugPrint('📊 [MLService] Error response: ${response.body}');
        throw Exception('Failed to analyze image: ${response.statusCode}');
      }
    } catch (e) {
      stopwatch.stop();
      debugPrint(
        '💥 [MLService] Error occurred after ${stopwatch.elapsedMilliseconds}ms: $e',
      );
      throw Exception('Error analyzing crop: $e');
    }
  }

  Future<bool> checkServerHealth() async {
    debugPrint('🏥 [MLService] Checking server health at $baseUrl/health...');
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _client.get(Uri.parse('$baseUrl/health'));
      stopwatch.stop();

      if (response.statusCode == 200) {
        debugPrint(
          '✅ [MLService] Server health check passed in ${stopwatch.elapsedMilliseconds}ms',
        );
        return true;
      } else {
        debugPrint(
          '⚠️ [MLService] Server health check failed with status ${response.statusCode} in ${stopwatch.elapsedMilliseconds}ms',
        );
        return false;
      }
    } catch (e) {
      stopwatch.stop();
      debugPrint(
        '❌ [MLService] Server health check error after ${stopwatch.elapsedMilliseconds}ms: $e',
      );
      return false;
    }
  }

  void dispose() {
    debugPrint('🧹 [MLService] Disposing ML service...');
    _client.close();
  }
}
