import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../services/preferences_service.dart';

class OfflineIndicator extends StatelessWidget {
  final bool showText;
  final double iconSize;
  final Color? color;

  const OfflineIndicator({
    super.key,
    this.showText = true,
    this.iconSize = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ConnectivityService().connectionStatus,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? true;

        if (isConnected) {
          return const SizedBox.shrink();
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: iconSize, color: color ?? Colors.red),
            if (showText) ...[
              const SizedBox(width: 4),
              Text(
                'Offline',
                style: TextStyle(
                  color: color ?? Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class SyncStatusIndicator extends StatefulWidget {
  final double iconSize;
  final Color? color;

  const SyncStatusIndicator({super.key, this.iconSize = 16, this.color});

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator> {
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _loadLastSyncTime();
  }

  Future<void> _loadLastSyncTime() async {
    final lastSync = PreferencesService().getLastSyncTime();
    if (mounted) {
      setState(() {
        _lastSyncTime = lastSync;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ConnectivityService().connectionStatus,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? true;

        if (!isConnected) {
          return const SizedBox.shrink();
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sync,
              size: widget.iconSize,
              color: widget.color ?? Colors.green,
            ),
            const SizedBox(width: 4),
            Text(
              _getSyncText(),
              style: TextStyle(
                color: widget.color ?? Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }

  String _getSyncText() {
    if (_lastSyncTime == null) {
      return 'Never synced';
    }

    final now = DateTime.now();
    final difference = now.difference(_lastSyncTime!);

    if (difference.inMinutes < 1) {
      return 'Just synced';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class ConnectivityBanner extends StatefulWidget {
  final Widget child;

  const ConnectivityBanner({super.key, required this.child});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadDismissState();
  }

  Future<void> _loadDismissState() async {
    final dismissed = PreferencesService().getConnectivityBannerDismissed();
    final dismissTime = PreferencesService().getConnectivityBannerDismissTime();

    // Auto-reset dismiss state after 24 hours
    if (dismissed && dismissTime != null) {
      final now = DateTime.now();
      final difference = now.difference(dismissTime);
      if (difference.inHours >= 24) {
        await PreferencesService().setConnectivityBannerDismissed(false);
        if (mounted) {
          setState(() {
            _isDismissed = false;
          });
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isDismissed = dismissed;
      });
    }
  }

  Future<void> _dismissBanner() async {
    await PreferencesService().setConnectivityBannerDismissed(true);
    await PreferencesService().setConnectivityBannerDismissTime(DateTime.now());
    if (mounted) {
      setState(() {
        _isDismissed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ConnectivityService().connectionStatus,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? true;

        if (isConnected || _isDismissed) {
          return widget.child;
        }

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.orange,
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'You are offline. Some features may be limited.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                    onPressed: _dismissBanner,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Expanded(child: widget.child),
          ],
        );
      },
    );
  }
}
