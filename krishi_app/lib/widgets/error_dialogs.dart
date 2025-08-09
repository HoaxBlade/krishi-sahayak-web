// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import '../services/error_handler_service.dart';
import '../services/connectivity_service.dart';

class ErrorDialog extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final String? customTitle;

  const ErrorDialog({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
    this.customTitle,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(_getErrorIcon(), color: _getErrorColor(), size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              customTitle ?? _getErrorTitle(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ErrorHandlerService().getUserFriendlyMessage(error),
            style: const TextStyle(fontSize: 16),
          ),
          if (error.details != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                error.details!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildRecoverySuggestions(),
        ],
      ),
      actions: _buildActions(context),
    );
  }

  IconData _getErrorIcon() {
    switch (error.type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.database:
        return Icons.storage;
      case ErrorType.sync:
        return Icons.sync_problem;
      case ErrorType.validation:
        return Icons.warning;
      case ErrorType.unknown:
        return Icons.error;
    }
  }

  Color _getErrorColor() {
    switch (error.severity) {
      case ErrorSeverity.low:
        return Colors.orange;
      case ErrorSeverity.medium:
        return Colors.orange;
      case ErrorSeverity.high:
        return Colors.red;
      case ErrorSeverity.critical:
        return Colors.red[900]!;
    }
  }

  String _getErrorTitle() {
    switch (error.type) {
      case ErrorType.network:
        return 'Connection Error';
      case ErrorType.database:
        return 'Storage Error';
      case ErrorType.sync:
        return 'Sync Error';
      case ErrorType.validation:
        return 'Input Error';
      case ErrorType.unknown:
        return 'Error';
    }
  }

  Widget _buildRecoverySuggestions() {
    final suggestions = ErrorHandlerService().getRecoverySuggestions(error);

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Suggestions:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...suggestions.map(
          (suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(suggestion, style: const TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final actions = <Widget>[];

    if (onDismiss != null) {
      actions.add(
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDismiss?.call();
          },
          child: const Text('Dismiss'),
        ),
      );
    }

    if (error.isRetryable && onRetry != null) {
      actions.add(
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onRetry?.call();
          },
          child: const Text('Retry'),
        ),
      );
    }

    if (actions.isEmpty) {
      actions.add(
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      );
    }

    return actions;
  }
}

class OfflineErrorDialog extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onContinueOffline;

  const OfflineErrorDialog({
    super.key,
    required this.message,
    this.onRetry,
    this.onContinueOffline,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.orange, size: 24),
          const SizedBox(width: 8),
          const Text(
            'Offline Mode',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: 16),
          const Text('You can:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.check_circle, size: 16, color: Colors.green),
              SizedBox(width: 8),
              Expanded(child: Text('Continue using the app offline')),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Icon(Icons.check_circle, size: 16, color: Colors.green),
              SizedBox(width: 8),
              Expanded(child: Text('Your data will be saved locally')),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Icon(Icons.check_circle, size: 16, color: Colors.green),
              SizedBox(width: 8),
              Expanded(child: Text('Sync when connection is restored')),
            ],
          ),
        ],
      ),
      actions: [
        if (onContinueOffline != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onContinueOffline?.call();
            },
            child: const Text('Continue Offline'),
          ),
        if (onRetry != null)
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry?.call();
            },
            child: const Text('Retry'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class SyncConflictDialog extends StatelessWidget {
  final String localData;
  final String serverData;
  final VoidCallback onUseLocal;
  final VoidCallback onUseServer;
  final VoidCallback onMerge;

  const SyncConflictDialog({
    super.key,
    required this.localData,
    required this.serverData,
    required this.onUseLocal,
    required this.onUseServer,
    required this.onMerge,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.sync_problem, color: Colors.orange, size: 24),
          const SizedBox(width: 8),
          const Text(
            'Sync Conflict',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data conflict detected. Choose how to resolve:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildDataComparison(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onUseLocal();
          },
          child: const Text('Use Local'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onUseServer();
          },
          child: const Text('Use Server'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onMerge();
          },
          child: const Text('Merge'),
        ),
      ],
    );
  }

  Widget _buildDataComparison() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Local Data:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 4),
              Text(localData),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Server Data:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 4),
              Text(serverData),
            ],
          ),
        ),
      ],
    );
  }
}

// Utility function to show error dialogs
class ErrorDialogHelper {
  static Future<void> showErrorDialog(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
    String? customTitle,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        error: error,
        onRetry: onRetry,
        onDismiss: onDismiss,
        customTitle: customTitle,
      ),
    );
  }

  static Future<void> showOfflineErrorDialog(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
    VoidCallback? onContinueOffline,
  }) {
    return showDialog(
      context: context,
      builder: (context) => OfflineErrorDialog(
        message: message,
        onRetry: onRetry,
        onContinueOffline: onContinueOffline,
      ),
    );
  }

  static Future<void> showSyncConflictDialog(
    BuildContext context,
    String localData,
    String serverData, {
    required VoidCallback onUseLocal,
    required VoidCallback onUseServer,
    required VoidCallback onMerge,
  }) {
    return showDialog(
      context: context,
      builder: (context) => SyncConflictDialog(
        localData: localData,
        serverData: serverData,
        onUseLocal: onUseLocal,
        onUseServer: onUseServer,
        onMerge: onMerge,
      ),
    );
  }
}
