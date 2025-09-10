import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class ImageCompressionService {
  static final ImageCompressionService _instance =
      ImageCompressionService._internal();
  factory ImageCompressionService() => _instance;
  ImageCompressionService._internal();

  // Compression settings for different use cases
  static const Map<String, Map<String, dynamic>> _compressionPresets = {
    'ml_analysis': {
      'maxWidth': 512,
      'maxHeight': 512,
      'quality': 70,
      'format': 'jpg',
    },
    'storage': {
      'maxWidth': 1024,
      'maxHeight': 1024,
      'quality': 80,
      'format': 'jpg',
    },
    'thumbnail': {
      'maxWidth': 256,
      'maxHeight': 256,
      'quality': 60,
      'format': 'jpg',
    },
  };

  /// Compress image for ML analysis (optimized for speed and model requirements)
  Future<Uint8List> compressForMLAnalysis(XFile imageFile) async {
    return await _compressImage(imageFile, 'ml_analysis');
  }

  /// Compress image for storage (balanced quality and size)
  Future<Uint8List> compressForStorage(XFile imageFile) async {
    return await _compressImage(imageFile, 'storage');
  }

  /// Create thumbnail (small size, fast loading)
  Future<Uint8List> createThumbnail(XFile imageFile) async {
    return await _compressImage(imageFile, 'thumbnail');
  }

  /// Compress image with custom settings
  Future<Uint8List> compressCustom(
    XFile imageFile, {
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 80,
  }) async {
    final stopwatch = Stopwatch()..start();
    debugPrint('🗜️ [ImageCompression] Starting custom compression...');
    debugPrint(
      '📊 [ImageCompression] Target: ${maxWidth}x$maxHeight, quality: $quality',
    );

    try {
      // Read original image
      final originalBytes = await imageFile.readAsBytes();
      final originalSize = originalBytes.length;
      debugPrint(
        '📊 [ImageCompression] Original size: ${_formatBytes(originalSize)}',
      );

      // Decode image
      final image = img.decodeImage(originalBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      debugPrint(
        '📊 [ImageCompression] Original dimensions: ${image.width}x${image.height}',
      );

      // Calculate new dimensions maintaining aspect ratio
      final aspectRatio = image.width / image.height;
      int newWidth = maxWidth;
      int newHeight = maxHeight;

      if (aspectRatio > 1) {
        // Landscape
        newHeight = (maxWidth / aspectRatio).round();
        if (newHeight > maxHeight) {
          newHeight = maxHeight;
          newWidth = (maxHeight * aspectRatio).round();
        }
      } else {
        // Portrait or square
        newWidth = (maxHeight * aspectRatio).round();
        if (newWidth > maxWidth) {
          newWidth = maxWidth;
          newHeight = (maxWidth / aspectRatio).round();
        }
      }

      // Resize image if needed
      img.Image resizedImage;
      if (image.width > newWidth || image.height > newHeight) {
        debugPrint('📊 [ImageCompression] Resizing to: ${newWidth}x$newHeight');
        resizedImage = img.copyResize(
          image,
          width: newWidth,
          height: newHeight,
        );
      } else {
        debugPrint('📊 [ImageCompression] No resizing needed');
        resizedImage = image;
      }

      // Encode with compression
      final compressedBytes = img.encodeJpg(resizedImage, quality: quality);
      final compressedSize = compressedBytes.length;

      stopwatch.stop();
      final compressionRatio =
          ((originalSize - compressedSize) / originalSize * 100);

      debugPrint(
        '✅ [ImageCompression] Compression completed in ${stopwatch.elapsedMilliseconds}ms',
      );
      debugPrint(
        '📊 [ImageCompression] Compressed size: ${_formatBytes(compressedSize)}',
      );
      debugPrint(
        '📊 [ImageCompression] Compression ratio: ${compressionRatio.toStringAsFixed(1)}%',
      );
      debugPrint(
        '📊 [ImageCompression] Final dimensions: ${resizedImage.width}x${resizedImage.height}',
      );

      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      stopwatch.stop();
      debugPrint(
        '❌ [ImageCompression] Compression failed after ${stopwatch.elapsedMilliseconds}ms: $e',
      );
      rethrow;
    }
  }

  /// Internal compression method using presets
  Future<Uint8List> _compressImage(XFile imageFile, String preset) async {
    final settings = _compressionPresets[preset]!;
    return await compressCustom(
      imageFile,
      maxWidth: settings['maxWidth'],
      maxHeight: settings['maxHeight'],
      quality: settings['quality'],
    );
  }

  /// Get compression statistics for an image
  Future<Map<String, dynamic>> getCompressionStats(XFile imageFile) async {
    try {
      final originalBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(originalBytes);

      if (image == null) {
        return {'error': 'Failed to decode image'};
      }

      // Test compression with ML preset
      final compressedBytes = await compressForMLAnalysis(imageFile);
      final compressionRatio =
          ((originalBytes.length - compressedBytes.length) /
          originalBytes.length *
          100);

      return {
        'originalSize': originalBytes.length,
        'originalDimensions': '${image.width}x${image.height}',
        'compressedSize': compressedBytes.length,
        'compressionRatio': compressionRatio,
        'estimatedUploadTime': _estimateUploadTime(compressedBytes.length),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Estimate upload time based on compressed size (assuming 1 Mbps connection)
  double _estimateUploadTime(int bytes) {
    const double avgConnectionSpeedBps = 125000; // 1 Mbps in bytes per second
    return bytes / avgConnectionSpeedBps;
  }

  /// Format bytes to human readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Optimize image for specific ML model requirements
  Future<Uint8List> optimizeForModel(
    XFile imageFile, {
    String modelType = 'crop_health',
  }) async {
    switch (modelType) {
      case 'crop_health':
        // Optimized for crop health detection model
        return await compressCustom(
          imageFile,
          maxWidth: 224, // Common CNN input size
          maxHeight: 224,
          quality: 75,
        );
      case 'disease_detection':
        // Higher resolution for disease detection
        return await compressCustom(
          imageFile,
          maxWidth: 512,
          maxHeight: 512,
          quality: 80,
        );
      default:
        return await compressForMLAnalysis(imageFile);
    }
  }

  /// Batch compress multiple images
  Future<List<Uint8List>> batchCompress(
    List<XFile> imageFiles,
    String preset,
  ) async {
    final results = <Uint8List>[];

    for (int i = 0; i < imageFiles.length; i++) {
      debugPrint(
        '🗜️ [ImageCompression] Processing batch ${i + 1}/${imageFiles.length}',
      );
      try {
        final compressed = await _compressImage(imageFiles[i], preset);
        results.add(compressed);
      } catch (e) {
        debugPrint(
          '❌ [ImageCompression] Failed to compress image ${i + 1}: $e',
        );
        rethrow;
      }
    }

    return results;
  }
}
