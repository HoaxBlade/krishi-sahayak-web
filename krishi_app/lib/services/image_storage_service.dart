import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageStorageService {
  static final ImageStorageService _instance = ImageStorageService._internal();
  factory ImageStorageService() => _instance;
  ImageStorageService._internal();

  static const String _imageCacheDirName = 'image_cache';
  static const String _cropImagesDirName = 'crop_images';
  static const String _userImagesDirName = 'user_images';

  Directory? _cacheDir;
  Directory? _cropImagesDir;
  Directory? _userImagesDir;
  final ImagePicker _picker = ImagePicker();

  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory('${appDir.path}/$_imageCacheDirName');
    _cropImagesDir = Directory('${appDir.path}/$_cropImagesDirName');
    _userImagesDir = Directory('${appDir.path}/$_userImagesDirName');

    await _cacheDir!.create(recursive: true);
    await _cropImagesDir!.create(recursive: true);
    await _userImagesDir!.create(recursive: true);
  }

  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<File?> pickImage({
    ImageSource source = ImageSource.gallery,
    double maxWidth = 1920,
    double maxHeight = 1080,
    int imageQuality = 85,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
    return null;
  }

  Future<File?> captureImage({
    double maxWidth = 1920,
    double maxHeight = 1080,
    int imageQuality = 85,
  }) async {
    if (!await requestCameraPermission()) {
      return null;
    }

    return await pickImage(
      source: ImageSource.camera,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }

  Future<File> saveCropImage(File imageFile, String cropId) async {
    final fileName =
        'crop_${cropId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedFile = File('${_cropImagesDir!.path}/$fileName');

    await imageFile.copy(savedFile.path);
    return savedFile;
  }

  Future<File> saveUserImage(File imageFile, String userId) async {
    final fileName =
        'user_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedFile = File('${_userImagesDir!.path}/$fileName');

    await imageFile.copy(savedFile.path);
    return savedFile;
  }

  Future<File?> getCropImage(String cropId) async {
    final files = _cropImagesDir!.listSync();
    for (final file in files) {
      if (file is File && file.path.contains('crop_$cropId')) {
        return file;
      }
    }
    return null;
  }

  Future<List<File>> getAllCropImages() async {
    final files = <File>[];
    await for (final entity in _cropImagesDir!.list()) {
      if (entity is File && entity.path.endsWith('.jpg')) {
        files.add(entity);
      }
    }
    return files;
  }

  Future<File?> getUserImage(String userId) async {
    final files = _userImagesDir!.listSync();
    for (final file in files) {
      if (file is File && file.path.contains('user_$userId')) {
        return file;
      }
    }
    return null;
  }

  Future<void> deleteCropImage(String cropId) async {
    final imageFile = await getCropImage(cropId);
    if (imageFile != null) {
      await imageFile.delete();
    }
  }

  Future<void> deleteUserImage(String userId) async {
    final imageFile = await getUserImage(userId);
    if (imageFile != null) {
      await imageFile.delete();
    }
  }

  Future<void> clearAllImages() async {
    await for (final entity in _cacheDir!.list()) {
      if (entity is File) {
        await entity.delete();
      }
    }
    await for (final entity in _cropImagesDir!.list()) {
      if (entity is File) {
        await entity.delete();
      }
    }
    await for (final entity in _userImagesDir!.list()) {
      if (entity is File) {
        await entity.delete();
      }
    }
  }

  Future<int> getTotalImageSize() async {
    int totalSize = 0;

    await for (final file in _cacheDir!.list(recursive: true)) {
      if (file is File) {
        totalSize += await file.length();
      }
    }

    await for (final file in _cropImagesDir!.list(recursive: true)) {
      if (file is File) {
        totalSize += await file.length();
      }
    }

    await for (final file in _userImagesDir!.list(recursive: true)) {
      if (file is File) {
        totalSize += await file.length();
      }
    }

    return totalSize;
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
