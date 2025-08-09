// ignore_for_file: unused_field, unused_import

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/offline_maps_service.dart';
import '../services/image_storage_service.dart';
import '../services/background_sync_service.dart';
import '../services/push_notification_service.dart';
import '../services/preferences_service.dart';

class AdvancedFeaturesDemo extends StatefulWidget {
  const AdvancedFeaturesDemo({super.key});

  @override
  State<AdvancedFeaturesDemo> createState() => _AdvancedFeaturesDemoState();
}

class _AdvancedFeaturesDemoState extends State<AdvancedFeaturesDemo> {
  bool _isLoading = false;
  String _statusMessage = '';
  final double _offlineMapProgress = 0.0;
  int _totalImageSize = 0;
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final lastSync = await BackgroundSyncService().getLastSyncTime();
      final imageSize = await ImageStorageService().getTotalImageSize();

      setState(() {
        _lastSyncTime = lastSync;
        _totalImageSize = imageSize;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phase 5: Advanced Features'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Offline Maps', Icons.map, [
                    _buildFeatureCard(
                      'Download Offline Map',
                      'Download map tiles for offline use',
                      () => _downloadOfflineMap(),
                    ),
                    _buildFeatureCard(
                      'View Offline Maps',
                      'List all downloaded offline maps',
                      () => _viewOfflineMaps(),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSection('Image Storage', Icons.image, [
                    _buildFeatureCard(
                      'Capture Crop Image',
                      'Take a photo of your crop',
                      () => _captureCropImage(),
                    ),
                    _buildFeatureCard(
                      'View Stored Images',
                      'Browse all stored crop images',
                      () => _viewStoredImages(),
                    ),
                    _buildInfoCard(
                      'Total Storage Used',
                      ImageStorageService().formatFileSize(_totalImageSize),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSection('Background Sync', Icons.sync, [
                    _buildFeatureCard(
                      'Force Sync Now',
                      'Manually trigger data synchronization',
                      () => _forceSync(),
                    ),
                    _buildFeatureCard(
                      'Toggle Auto Sync',
                      'Enable/disable automatic background sync',
                      () => _toggleAutoSync(),
                    ),
                    _buildInfoCard(
                      'Last Sync',
                      _lastSyncTime != null
                          ? _formatDateTime(_lastSyncTime!)
                          : 'Never',
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSection('Push Notifications', Icons.notifications, [
                    _buildFeatureCard(
                      'Test Notification',
                      'Send a test notification',
                      () => _sendTestNotification(),
                    ),
                    _buildFeatureCard(
                      'Schedule Crop Reminder',
                      'Set a reminder for crop management',
                      () => _scheduleCropReminder(),
                    ),
                    _buildFeatureCard(
                      'Toggle Notifications',
                      'Enable/disable push notifications',
                      () => _toggleNotifications(),
                    ),
                  ]),
                  if (_statusMessage.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Text(
                        _statusMessage,
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.green, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildFeatureCard(
    String title,
    String description,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ),
    );
  }

  Future<void> _downloadOfflineMap() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Downloading offline map...';
    });

    try {
      // This would typically get the user's current location
      // For demo purposes, using a default location (India center)
      const center = LatLng(20.5937, 78.9629);

      await OfflineMapsService().downloadOfflineMap(
        center,
        10.0, // 10km radius
        10, // min zoom
        15, // max zoom
      );

      setState(() {
        _statusMessage = 'Offline map downloaded successfully!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error downloading offline map: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _viewOfflineMaps() async {
    try {
      final maps = await OfflineMapsService().getOfflineMaps();
      if (maps.isEmpty) {
        setState(() {
          _statusMessage = 'No offline maps found. Download one first!';
        });
      } else {
        setState(() {
          _statusMessage = 'Found ${maps.length} offline map(s)';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading offline maps: $e';
      });
    }
  }

  Future<void> _captureCropImage() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Opening camera...';
    });

    try {
      final imageFile = await ImageStorageService().captureImage();
      if (imageFile != null) {
        await ImageStorageService().saveCropImage(imageFile, 'demo_crop');
        await _loadData(); // Refresh image size

        setState(() {
          _statusMessage = 'Crop image captured and saved!';
        });
      } else {
        setState(() {
          _statusMessage = 'No image captured';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error capturing image: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _viewStoredImages() async {
    try {
      final images = await ImageStorageService().getAllCropImages();
      setState(() {
        _statusMessage = 'Found ${images.length} stored crop image(s)';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading stored images: $e';
      });
    }
  }

  Future<void> _forceSync() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Syncing data...';
    });

    try {
      await BackgroundSyncService().forceSync();
      await _loadData(); // Refresh sync time

      setState(() {
        _statusMessage = 'Data sync completed successfully!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error syncing data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAutoSync() async {
    try {
      final isEnabled = await BackgroundSyncService().isSyncEnabled();
      await BackgroundSyncService().setSyncEnabled(!isEnabled);

      setState(() {
        _statusMessage = 'Auto sync ${!isEnabled ? 'enabled' : 'disabled'}';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error toggling auto sync: $e';
      });
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      await PushNotificationService().showTestNotification();
      setState(() {
        _statusMessage = 'Test notification sent!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error sending notification: $e';
      });
    }
  }

  Future<void> _scheduleCropReminder() async {
    try {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      await PushNotificationService().scheduleCropReminder(
        cropName: 'Demo Crop',
        task: 'water',
        scheduledTime: tomorrow,
      );

      setState(() {
        _statusMessage = 'Crop reminder scheduled for tomorrow!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error scheduling reminder: $e';
      });
    }
  }

  Future<void> _toggleNotifications() async {
    try {
      final isEnabled = await PushNotificationService().isNotificationEnabled();
      await PushNotificationService().setNotificationEnabled(!isEnabled);

      setState(() {
        _statusMessage = 'Notifications ${!isEnabled ? 'enabled' : 'disabled'}';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error toggling notifications: $e';
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
