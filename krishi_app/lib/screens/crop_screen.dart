// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/crop_service.dart';
import '../services/sync_service.dart';
import '../services/error_handler_service.dart';
import '../models/crop.dart';
import '../widgets/add_crop_dialog.dart';
import '../widgets/offline_indicator.dart';
import '../widgets/error_dialogs.dart';

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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Crop Management'),
        actions: [
          const OfflineIndicator(),
          IconButton(icon: const Icon(Icons.add), onPressed: _addNewCrop),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search crops...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _searchCrops,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCrops.isEmpty
                ? const Center(child: Text('No crops found'))
                : ListView.builder(
                    itemCount: _filteredCrops.length,
                    itemBuilder: (context, index) {
                      final crop = _filteredCrops[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.agriculture,
                            color: Colors.green,
                          ),
                          title: Text(crop.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (crop.variety != null)
                                Text('Variety: ${crop.variety}'),
                              if (crop.plantingDate != null)
                                Text(
                                  'Planted: ${crop.plantingDate.toString().split(' ')[0]}',
                                ),
                              if (crop.harvestDate != null)
                                Text(
                                  'Harvest: ${crop.harvestDate.toString().split(' ')[0]}',
                                ),
                            ],
                          ),
                          trailing: Chip(
                            label: Text(crop.status),
                            backgroundColor: crop.status == 'active'
                                // ignore: duplicate_ignore
                                // ignore: deprecated_member_use
                                ? Colors.green.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.2),
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
