import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/crop_analysis.dart';
import 'supabase_service.dart';

class AnalysisService {
  static final AnalysisService _instance = AnalysisService._internal();
  factory AnalysisService() => _instance;
  AnalysisService._internal();

  final SupabaseService _supabaseService = SupabaseService();
  final Uuid _uuid = const Uuid();

  /// Save analysis result to Supabase
  Future<CropAnalysis?> saveAnalysisResult({
    required XFile imageFile,
    required Map<String, dynamic> analysisResult,
  }) async {
    try {
      debugPrint('💾 [AnalysisService] Starting to save analysis result...');

      // Check if Supabase is initialized
      if (!_supabaseService.isInitialized) {
        debugPrint(
          '⚠️ [AnalysisService] Supabase not initialized, skipping save',
        );
        return null;
      }

      // Generate unique ID for the analysis
      final analysisId = _uuid.v4();

      // Upload image to Supabase storage
      final imageBytes = await imageFile.readAsBytes();
      final fileName =
          'analysis_${analysisId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      debugPrint('📤 [AnalysisService] Uploading image to Supabase storage...');
      final imageUrl = await _supabaseService.uploadCropImage(
        fileName,
        imageBytes,
      );

      // Prepare analysis data
      final analysisData = {
        'id': analysisId,
        'image_url': imageUrl,
        'crop_type': analysisResult['crop_type'] ?? 'Unknown',
        'disease_type': analysisResult['disease_type'] ?? 'Unknown',
        'health_status': analysisResult['health_status'] ?? 'unknown',
        'is_healthy': analysisResult['is_healthy'] ?? false,
        'confidence': analysisResult['confidence'] ?? 0.0,
        'prediction_class': analysisResult['prediction_class'] ?? 0,
        'all_predictions': analysisResult['all_predictions'] ?? {},
        'model_type': analysisResult['model_type'] ?? 'unknown',
        'analysis_mode': analysisResult['analysis_mode'] ?? 'unknown',
        'processing_time': analysisResult['processing_time'] ?? 'unknown',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      debugPrint('💾 [AnalysisService] Saving analysis data to database...');
      final savedAnalysis = await _supabaseService.insertCropAnalysis(
        analysisData,
      );

      debugPrint(
        '✅ [AnalysisService] Analysis saved successfully with ID: $analysisId',
      );
      return CropAnalysis.fromMap(savedAnalysis);
    } catch (e) {
      debugPrint('❌ [AnalysisService] Error saving analysis result: $e');
      // Don't rethrow - just return null so the analysis still shows to user
      return null;
    }
  }

  /// Get all analysis results
  Future<List<CropAnalysis>> getAllAnalyses() async {
    try {
      debugPrint('📊 [AnalysisService] Fetching all analysis results...');

      // Check if Supabase is initialized
      if (!_supabaseService.isInitialized) {
        debugPrint(
          '⚠️ [AnalysisService] Supabase not initialized, returning empty list',
        );
        return [];
      }

      final analyses = await _supabaseService.getCropAnalyses();

      return analyses
          .map((analysis) => CropAnalysis.fromMap(analysis))
          .toList();
    } catch (e) {
      debugPrint('❌ [AnalysisService] Error fetching analyses: $e');
      return []; // Return empty list instead of rethrowing
    }
  }

  /// Get analysis by ID
  Future<CropAnalysis?> getAnalysisById(String id) async {
    try {
      debugPrint('🔍 [AnalysisService] Fetching analysis by ID: $id');
      final analyses = await _supabaseService.getCropAnalyses();

      final analysis = analyses.firstWhere(
        (analysis) => analysis['id'] == id,
        orElse: () => {},
      );

      if (analysis.isNotEmpty) {
        return CropAnalysis.fromMap(analysis);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [AnalysisService] Error fetching analysis by ID: $e');
      rethrow;
    }
  }

  /// Delete analysis
  Future<void> deleteAnalysis(String id) async {
    try {
      debugPrint('🗑️ [AnalysisService] Deleting analysis: $id');
      await _supabaseService.deleteCropAnalysis(id);
      debugPrint('✅ [AnalysisService] Analysis deleted successfully');
    } catch (e) {
      debugPrint('❌ [AnalysisService] Error deleting analysis: $e');
      rethrow;
    }
  }

  /// Update analysis
  Future<CropAnalysis?> updateAnalysis(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      debugPrint('✏️ [AnalysisService] Updating analysis: $id');
      updates['updated_at'] = DateTime.now().toIso8601String();

      final updatedAnalysis = await _supabaseService.updateCropAnalysis(
        id,
        updates,
      );
      debugPrint('✅ [AnalysisService] Analysis updated successfully');

      return CropAnalysis.fromMap(updatedAnalysis);
    } catch (e) {
      debugPrint('❌ [AnalysisService] Error updating analysis: $e');
      rethrow;
    }
  }
}
