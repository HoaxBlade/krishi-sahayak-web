// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/crop_service.dart';
import '../services/sync_service.dart';
import '../services/error_handler_service.dart';
import '../models/crop.dart';
import '../widgets/add_crop_dialog.dart';
import '../widgets/offline_indicator.dart';
import '../widgets/error_dialogs.dart';
import 'camera_screen.dart';

class CropScreen extends StatefulWidget {
  const CropScreen({super.key});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final CropService _cropService = CropService();
  final SyncService _syncService = SyncService();
  final ErrorHandlerService _errorHandler = ErrorHandlerService();
  List<Crop> _crops = [];
  List<Crop> _filteredCrops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCrops();
  }

  Future<void> _loadCrops() async {
    setState(() => _isLoading = true);
    try {
      final crops = await _cropService.getAllCrops();
      setState(() {
        _crops = crops;
        _filteredCrops = crops;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);

      final error = _errorHandler.createDatabaseError(
        'Failed to load crops',
        details: e.toString(),
        operationId: 'load_crops',
      );
      _errorHandler.handleError(error);

      if (mounted) {
        await ErrorDialogHelper.showErrorDialog(
          context,
          error,
          onRetry: _loadCrops,
        );
      }
    }
  }

  void _searchCrops(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCrops = _crops;
      } else {
        _filteredCrops = _crops
            .where(
              (crop) =>
                  crop.name.toLowerCase().contains(query.toLowerCase()) ||
                  (crop.variety?.toLowerCase().contains(query.toLowerCase()) ??
                      false),
            )
            .toList();
      }
    });
  }

  Future<void> _addNewCrop() async {
    final result = await showDialog<Crop>(
      context: context,
      builder: (context) => const AddCropDialog(),
    );

    if (result != null) {
      try {
        final success = await _cropService.addCrop(result);
        if (success) {
          // Add to sync queue
          await _syncService.addSyncOperation('add_crop', result.toMap());

          _loadCrops();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Crop added successfully!')),
            );
          }
        }
      } catch (e) {
        final error = _errorHandler.createDatabaseError(
          'Failed to add crop',
          details: e.toString(),
          operationId: 'add_crop',
        );
        _errorHandler.handleError(error);

        if (mounted) {
          await ErrorDialogHelper.showErrorDialog(
            context,
            error,
            onRetry: () => _addNewCrop(),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // backgroundColor and foregroundColor are now handled by AppBarTheme in main.dart
        title: Text('Crop Management'), // Removed const to allow theme styling
        actions: [
          const OfflineIndicator(),
          IconButton(
            icon: Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.onSurface), // Themed icon color
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CameraScreen()),
              );
            },
            tooltip: 'Analyze Crop Health',
          ),
          IconButton(icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary), onPressed: _addNewCrop), // Themed icon color
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration( // Removed const to allow theme styling
                hintText: 'Search crops...',
                hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)), // Themed hint style
                prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)), // Themed icon color
                // Border is now handled by InputDecorationTheme in main.dart
              ),
              onChanged: _searchCrops,
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)) // Themed progress indicator
                : _filteredCrops.isEmpty
                ? Center(child: Text('No crops found', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)))) // Themed text style
                : ListView.builder(
                    itemCount: _filteredCrops.length,
                    itemBuilder: (context, index) {
                      final crop = _filteredCrops[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6, // Adjusted vertical margin
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.agriculture,
                            color: Theme.of(context).colorScheme.primary, // Themed icon color
                          ),
                          title: Text(crop.name, style: Theme.of(context).textTheme.titleMedium),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (crop.variety != null)
                                Text('Variety: ${crop.variety}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                              if (crop.plantingDate != null)
                                Text(
                                  'Planted: ${crop.plantingDate.toString().split(' ')[0]}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                                ),
                              if (crop.harvestDate != null)
                                Text(
                                  'Harvest: ${crop.harvestDate.toString().split(' ')[0]}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                                ),
                            ],
                          ),
                          trailing: Chip(
                            label: Text(
                              crop.status,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: crop.status == 'active'
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            backgroundColor: crop.status == 'active'
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide.none,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
