// ignore_for_file: unused_local_variable, unnecessary_brace_in_string_interps, unused_import

import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class OfflineMapsService {
  static final OfflineMapsService _instance = OfflineMapsService._internal();
  factory OfflineMapsService() => _instance;
  OfflineMapsService._internal();

  static const String _tileCacheDirName = 'tile_cache';
  static const String _offlineMapsDirName = 'offline_maps';
  static const int _maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const int _maxTileAge = 30 * 24 * 60 * 60 * 1000; // 30 days

  Directory? _cacheDir;
  Directory? _offlineMapsDir;
  final Map<String, DateTime> _tileTimestamps = {};

  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory('${appDir.path}/$_tileCacheDirName');
    _offlineMapsDir = Directory('${appDir.path}/$_offlineMapsDirName');

    await _cacheDir!.create(recursive: true);
    await _offlineMapsDir!.create(recursive: true);

    await _loadTileTimestamps();
    await _cleanupOldTiles();
  }

  Future<void> _loadTileTimestamps() async {
    final timestampFile = File('${_cacheDir!.path}/timestamps.json');
    if (await timestampFile.exists()) {
      try {
        final content = await timestampFile.readAsString();
        // Parse timestamps from JSON (simplified for this example)
        // In a real implementation, you'd use proper JSON parsing
      } catch (e) {
        debugPrint('Error loading tile timestamps: $e');
      }
    }
  }

  Future<void> _saveTileTimestamps() async {
    final timestampFile = File('${_cacheDir!.path}/timestamps.json');
    try {
      // Save timestamps to JSON (simplified for this example)
      // In a real implementation, you'd use proper JSON serialization
    } catch (e) {
      debugPrint('Error saving tile timestamps: $e');
    }
  }

  Future<Uint8List?> getTile(int x, int y, int z) async {
    final tileKey = '${z}_${x}_${y}';
    final tileFile = File('${_cacheDir!.path}/$tileKey.png');

    if (await tileFile.exists()) {
      _tileTimestamps[tileKey] = DateTime.now();
      return await tileFile.readAsBytes();
    }

    return null;
  }

  Future<void> cacheTile(int x, int y, int z, Uint8List data) async {
    final tileKey = '${z}_${x}_${y}';
    final tileFile = File('${_cacheDir!.path}/$tileKey.png');

    await tileFile.writeAsBytes(data);
    _tileTimestamps[tileKey] = DateTime.now();

    await _saveTileTimestamps();
    await _manageCacheSize();
  }

  Future<void> _manageCacheSize() async {
    final cacheSize = await _getCacheSize();
    if (cacheSize > _maxCacheSize) {
      await _cleanupOldTiles();
    }
  }

  Future<int> _getCacheSize() async {
    int totalSize = 0;
    await for (final file in _cacheDir!.list(recursive: true)) {
      if (file is File) {
        totalSize += await file.length();
      }
    }
    return totalSize;
  }

  Future<void> _cleanupOldTiles() async {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    for (final entry in _tileTimestamps.entries) {
      final age = now.difference(entry.value).inMilliseconds;
      if (age > _maxTileAge) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      final tileFile = File('${_cacheDir!.path}/$key.png');
      if (await tileFile.exists()) {
        await tileFile.delete();
      }
      _tileTimestamps.remove(key);
    }

    await _saveTileTimestamps();
  }

  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  Future<LatLng?> getCurrentLocation() async {
    if (!await requestLocationPermission()) {
      return null;
    }

    try {
      // This would integrate with geolocator package
      // For now, returning a default location
      return const LatLng(20.5937, 78.9629); // India center
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  Future<void> downloadOfflineMap(
    LatLng center,
    double radiusKm,
    int minZoom,
    int maxZoom,
  ) async {
    final mapName = 'offline_map_${DateTime.now().millisecondsSinceEpoch}';
    final mapDir = Directory('${_offlineMapsDir!.path}/$mapName');
    await mapDir.create();

    // Calculate tile bounds
    final tiles = _calculateTileBounds(center, radiusKm, minZoom, maxZoom);

    int downloadedTiles = 0;
    final totalTiles = tiles.length;

    for (final tile in tiles) {
      try {
        final tileData = await _downloadTile(tile.x, tile.y, tile.z);
        if (tileData != null) {
          await cacheTile(tile.x, tile.y, tile.z, tileData);
          downloadedTiles++;

          // Update progress
          final progress = downloadedTiles / totalTiles;
          // Note: setOfflineMapProgress method needs to be added to PreferencesService
        }
      } catch (e) {
        debugPrint('Error downloading tile: $e');
      }
    }

    // Save map metadata
    await _saveMapMetadata(
      mapName,
      center,
      radiusKm,
      minZoom,
      maxZoom,
      downloadedTiles,
    );
  }

  List<TileCoordinates> _calculateTileBounds(
    LatLng center,
    double radiusKm,
    int minZoom,
    int maxZoom,
  ) {
    final tiles = <TileCoordinates>[];

    for (int z = minZoom; z <= maxZoom; z++) {
      final centerTile = _latLngToTile(center, z);
      final radiusTiles =
          (radiusKm / 111.32) / (156543.03392 / (256 * pow(2, z)));

      final minX = (centerTile.x - radiusTiles).floor();
      final maxX = (centerTile.x + radiusTiles).ceil();
      final minY = (centerTile.y - radiusTiles).floor();
      final maxY = (centerTile.y + radiusTiles).ceil();

      for (int x = minX; x <= maxX; x++) {
        for (int y = minY; y <= maxY; y++) {
          tiles.add(TileCoordinates(x, y, z));
        }
      }
    }

    return tiles;
  }

  TileCoordinates _latLngToTile(LatLng latLng, int zoom) {
    final n = pow(2, zoom);
    final xtile = ((latLng.longitude + 180) / 360 * n).floor();
    final latRad = radians(latLng.latitude);
    final ytile = ((1 - log(tan(latRad) + 1 / cos(latRad))) / pi * n / 2)
        .floor();
    return TileCoordinates(xtile, ytile, zoom);
  }

  Future<Uint8List?> _downloadTile(int x, int y, int z) async {
    final url = 'https://tile.openstreetmap.org/$z/$x/$y.png';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      debugPrint('Error downloading tile: $e');
    }
    return null;
  }

  Future<void> _saveMapMetadata(
    String mapName,
    LatLng center,
    double radiusKm,
    int minZoom,
    int maxZoom,
    int tileCount,
  ) async {
    final metadata = {
      'name': mapName,
      'center_lat': center.latitude,
      'center_lng': center.longitude,
      'radius_km': radiusKm,
      'min_zoom': minZoom,
      'max_zoom': maxZoom,
      'tile_count': tileCount,
      'created_at': DateTime.now().toIso8601String(),
    };

    final metadataFile = File(
      '${_offlineMapsDir!.path}/$mapName/metadata.json',
    );
    await metadataFile.writeAsString(metadata.toString());
  }

  Future<List<Map<String, dynamic>>> getOfflineMaps() async {
    final maps = <Map<String, dynamic>>[];

    await for (final entity in _offlineMapsDir!.list()) {
      if (entity is Directory) {
        final metadataFile = File('${entity.path}/metadata.json');
        if (await metadataFile.exists()) {
          try {
            final content = await metadataFile.readAsString();
            // Parse metadata (simplified for this example)
            maps.add({
              'name': entity.path.split('/').last,
              'path': entity.path,
              'metadata': content,
            });
          } catch (e) {
            debugPrint('Error reading map metadata: $e');
          }
        }
      }
    }

    return maps;
  }

  Future<void> deleteOfflineMap(String mapName) async {
    final mapDir = Directory('${_offlineMapsDir!.path}/$mapName');
    if (await mapDir.exists()) {
      await mapDir.delete(recursive: true);
    }
  }

  Future<void> clearAllOfflineMaps() async {
    await for (final entity in _offlineMapsDir!.list()) {
      if (entity is Directory) {
        await entity.delete(recursive: true);
      }
    }
  }
}

class TileCoordinates {
  final int x;
  final int y;
  final int z;

  TileCoordinates(this.x, this.y, this.z);
}

double radians(double degrees) => degrees * pi / 180;
