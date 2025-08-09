// ignore_for_file: avoid_print

import '../models/crop.dart';
import 'database_helper.dart';

class CropService {
  static final CropService _instance = CropService._internal();
  factory CropService() => _instance;
  CropService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Get all crops
  Future<List<Crop>> getAllCrops() async {
    try {
      final cropsData = await _dbHelper.getAllCrops();
      return cropsData.map((data) => Crop.fromMap(data)).toList();
    } catch (e) {
      print('Error getting crops: $e');
      return [];
    }
  }

  // Get active crops only
  Future<List<Crop>> getActiveCrops() async {
    try {
      final cropsData = await _dbHelper.getAllCrops();
      return cropsData
          .where((data) => data['status'] == 'active')
          .map((data) => Crop.fromMap(data))
          .toList();
    } catch (e) {
      print('Error getting active crops: $e');
      return [];
    }
  }

  // Add new crop
  Future<bool> addCrop(Crop crop) async {
    try {
      final id = await _dbHelper.insertCrop(crop.toMap());
      return id > 0;
    } catch (e) {
      print('Error adding crop: $e');
      return false;
    }
  }

  // Update crop
  Future<bool> updateCrop(Crop crop) async {
    try {
      final rowsAffected = await _dbHelper.updateCrop(crop.toMap());
      return rowsAffected > 0;
    } catch (e) {
      print('Error updating crop: $e');
      return false;
    }
  }

  // Delete crop
  Future<bool> deleteCrop(String id) async {
    try {
      final rowsAffected = await _dbHelper.deleteCrop(id);
      return rowsAffected > 0;
    } catch (e) {
      print('Error deleting crop: $e');
      return false;
    }
  }

  // Get crop by ID
  Future<Crop?> getCropById(String id) async {
    try {
      final cropsData = await _dbHelper.getAllCrops();
      final cropData = cropsData.where((data) => data['id'] == id).firstOrNull;
      return cropData != null ? Crop.fromMap(cropData) : null;
    } catch (e) {
      print('Error getting crop by ID: $e');
      return null;
    }
  }

  // Search crops by name
  Future<List<Crop>> searchCrops(String query) async {
    try {
      final cropsData = await _dbHelper.getAllCrops();
      return cropsData
          .where(
            (data) =>
                data['name'].toString().toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                (data['variety'] != null &&
                    data['variety'].toString().toLowerCase().contains(
                      query.toLowerCase(),
                    )),
          )
          .map((data) => Crop.fromMap(data))
          .toList();
    } catch (e) {
      print('Error searching crops: $e');
      return [];
    }
  }

  // Get crops by status
  Future<List<Crop>> getCropsByStatus(String status) async {
    try {
      final cropsData = await _dbHelper.getAllCrops();
      return cropsData
          .where((data) => data['status'] == status)
          .map((data) => Crop.fromMap(data))
          .toList();
    } catch (e) {
      print('Error getting crops by status: $e');
      return [];
    }
  }

  // Get crops planted in a specific month
  Future<List<Crop>> getCropsByPlantingMonth(int month) async {
    try {
      final cropsData = await _dbHelper.getAllCrops();
      return cropsData
          .where((data) {
            if (data['planting_date'] == null) return false;
            final plantingDate = DateTime.parse(data['planting_date']);
            return plantingDate.month == month;
          })
          .map((data) => Crop.fromMap(data))
          .toList();
    } catch (e) {
      print('Error getting crops by planting month: $e');
      return [];
    }
  }

  // Get upcoming harvests (within next 30 days)
  Future<List<Crop>> getUpcomingHarvests() async {
    try {
      final now = DateTime.now();
      final thirtyDaysFromNow = now.add(const Duration(days: 30));

      final cropsData = await _dbHelper.getAllCrops();
      return cropsData
          .where((data) {
            if (data['harvest_date'] == null) return false;
            final harvestDate = DateTime.parse(data['harvest_date']);
            return harvestDate.isAfter(now) &&
                harvestDate.isBefore(thirtyDaysFromNow) &&
                data['status'] == 'active';
          })
          .map((data) => Crop.fromMap(data))
          .toList();
    } catch (e) {
      print('Error getting upcoming harvests: $e');
      return [];
    }
  }
}
