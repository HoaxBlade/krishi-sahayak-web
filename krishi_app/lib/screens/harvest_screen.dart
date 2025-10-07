// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:async';
import '../services/crop_service.dart';
import '../models/crop.dart';
import '../widgets/add_crop_dialog.dart';

class HarvestScreen extends StatefulWidget {
  const HarvestScreen({super.key});

  @override
  State<HarvestScreen> createState() => _HarvestScreenState();
}

class _HarvestScreenState extends State<HarvestScreen> {
  final CropService _cropService = CropService();
  List<Crop> _allCrops = [];
  List<Crop> _upcomingHarvests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCrops();
  }

  Future<void> _loadCrops() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('🔍 [HarvestScreen] Starting to load crops...');
      final crops = await _cropService.getAllCrops();
      debugPrint(
        '🔍 [HarvestScreen] getAllCrops() returned ${crops.length} crops',
      );

      final harvests = await _cropService.getUpcomingHarvests();
      debugPrint(
        '🔍 [HarvestScreen] getUpcomingHarvests() returned ${harvests.length} harvests',
      );

      // Debug information
      debugPrint('🌾 [HarvestScreen] Loaded ${crops.length} total crops');
      debugPrint(
        '📅 [HarvestScreen] Loaded ${harvests.length} upcoming harvests',
      );

      for (var crop in crops) {
        debugPrint(
          '🌱 Crop: ${crop.name}, Harvest Date: ${crop.harvestDate}, Status: ${crop.status}',
        );
      }

      setState(() {
        _allCrops = crops;
        _upcomingHarvests = harvests;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ [HarvestScreen] Error loading crops: $e');
      debugPrint('❌ [HarvestScreen] Error type: ${e.runtimeType}');
      debugPrint('❌ [HarvestScreen] Error details: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Harvest Management'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadCrops,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: Icon(Icons.add, color: Colors.black),
            onPressed: _addCrop,
            tooltip: 'Add New Crop',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(onRefresh: _loadCrops, child: _buildContent()),
    );
  }

  Widget _buildContent() {
    if (_allCrops.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsSection(),
          const SizedBox(height: 20),
          _buildAllCropsSection(),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.agriculture, size: 32, color: Colors.green),
                  const SizedBox(height: 8),
                  Text(
                    '${_allCrops.length}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                  Text(
                    'Total Crops',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.calendar_today, size: 32, color: Colors.green),
                  const SizedBox(height: 8),
                  Text(
                    '${_upcomingHarvests.length}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                  Text(
                    'Upcoming Harvests',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAllCropsSection() {
    // Sort crops by harvest date (closest first, nulls last)
    final sortedCrops = List<Crop>.from(_allCrops);
    sortedCrops.sort((a, b) {
      if (a.harvestDate == null && b.harvestDate == null) return 0;
      if (a.harvestDate == null) return 1;
      if (b.harvestDate == null) return -1;
      return a.harvestDate!.compareTo(b.harvestDate!);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Crops',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),
        const SizedBox(height: 12),
        ...sortedCrops.map((crop) => _buildCropCard(crop)),
      ],
    );
  }

  Widget _buildCropCard(Crop crop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.agriculture, size: 24, color: Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    crop.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                  if (crop.variety != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Variety: ${crop.variety}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        'Harvest: ${crop.harvestDate?.toString().split(' ')[0] ?? 'Not set'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _editCrop(crop),
              tooltip: 'Edit Crop',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addCrop() async {
    final result = await showDialog<Crop>(
      context: context,
      builder: (context) => AddCropDialog(),
    );

    if (result != null) {
      // Actually save the crop to the database
      debugPrint('🌱 [HarvestScreen] Saving crop: ${result.name}');
      final success = await _cropService.addCrop(result);

      if (success) {
        debugPrint('✅ [HarvestScreen] Crop saved successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Crop "${result.name}" added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadCrops();
      } else {
        debugPrint('❌ [HarvestScreen] Failed to save crop');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save crop. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editCrop(Crop crop) async {
    // For now, just show a message that editing is not available
    // In a full implementation, you would create an EditCropDialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit functionality coming soon!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.agriculture, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Crops Added Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first crop to start tracking harvests and manage your farming activities.',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addCrop,
              icon: Icon(Icons.add),
              label: Text('Add Your First Crop'),
            ),
          ],
        ),
      ),
    );
  }
}
