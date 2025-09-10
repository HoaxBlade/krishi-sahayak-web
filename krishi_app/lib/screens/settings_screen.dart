import 'package:flutter/material.dart';
import '../services/cache_service.dart';
import '../services/image_storage_service.dart';
import '../services/database_helper.dart';
import '../widgets/confirmation_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final CacheService _cacheService = CacheService();
  final ImageStorageService _imageService = ImageStorageService();

  bool _isLoading = false;
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Storage Section
          _buildSectionHeader('Storage Management'),
          _buildStorageCard(),
          const SizedBox(height: 24),

          // Data Section
          _buildSectionHeader('Data Management'),
          _buildDataCard(),
          const SizedBox(height: 24),

          // Status
          if (_statusMessage.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusMessage,
                style: TextStyle(color: Colors.blue[700]),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.green[700],
        ),
      ),
    );
  }

  Widget _buildStorageCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: Colors.orange[600]),
                const SizedBox(width: 8),
                const Text(
                  'Storage & Cache',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Clear Cache Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _clearCache,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Cache'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Clear Images Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _clearImages,
                icon: const Icon(Icons.image_not_supported),
                label: const Text('Clear All Images'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Text(
              'Clearing cache will remove temporary data to free up space. Images and important data will be preserved.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storage, color: Colors.red[600]),
                const SizedBox(width: 8),
                const Text(
                  'Data Management',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Reset App Data Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _resetAppData,
                icon: const Icon(Icons.restore),
                label: const Text('Reset App Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Text(
              'WARNING: This will permanently delete all your crops, weather data, and settings. This action cannot be undone.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearCache() async {
    final confirmed = await ConfirmationDialog.showClearData(
      context: context,
      dataType: 'Cache',
      customMessage:
          'This will clear temporary data to free up storage space. Your crops and important data will not be affected.',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Clearing cache...';
    });

    try {
      await _cacheService.clear();
      setState(() {
        _statusMessage =
            'Cache cleared successfully! Storage space has been freed up.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to clear cache. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearImages() async {
    final confirmed = await ConfirmationDialog.showClearData(
      context: context,
      dataType: 'Images',
      customMessage:
          'This will permanently delete all stored crop analysis images and cached photos. This action cannot be undone.',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Clearing images...';
    });

    try {
      await _imageService.clearAllImages();
      setState(() {
        _statusMessage =
            'All images cleared successfully! Storage space has been freed up.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to clear images. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetAppData() async {
    final confirmed = await ConfirmationDialog.showReset(
      context: context,
      itemName: 'App Data',
      customMessage:
          'This will permanently delete ALL your data including crops, weather history, images, and settings. This action cannot be undone and you will lose all your information.',
    );

    if (!confirmed) return;

    // Double confirmation for such a destructive action
    final doubleConfirmed = await ConfirmationDialog.show(
      // ignore: use_build_context_synchronously
      context: context,
      title: 'Final Confirmation',
      message:
          'Are you absolutely sure? This will delete EVERYTHING and cannot be undone.',
      confirmText: 'Yes, Delete Everything',
      cancelText: 'Cancel',
      icon: Icons.warning,
      iconColor: Colors.red,
      confirmColor: Colors.red[800],
    );

    if (!doubleConfirmed) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Resetting app data...';
    });

    try {
      // Clear all data
      await _cacheService.clear();
      await _imageService.clearAllImages();
      await DatabaseHelper().deleteDatabase();

      setState(() {
        _statusMessage = 'App data reset successfully! Please restart the app.';
      });

      // Show restart dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.restart_alt, color: Colors.green),
                SizedBox(width: 8),
                Text('Restart Required'),
              ],
            ),
            content: const Text(
              'App data has been reset. Please close and restart the app to complete the process.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to reset app data. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
