import 'package:flutter/material.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final IconData? icon;
  final Color? iconColor;
  final Color? confirmColor;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.icon,
    this.iconColor,
    this.confirmColor,
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(icon!, color: iconColor ?? Colors.orange, size: 24),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
            onCancel?.call();
          },
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor ?? Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }

  /// Show a confirmation dialog and return the result
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    IconData? icon,
    Color? iconColor,
    Color? confirmColor,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        icon: icon,
        iconColor: iconColor,
        confirmColor: confirmColor,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    );
    return result ?? false;
  }

  /// Show a delete confirmation dialog
  static Future<bool> showDelete({
    required BuildContext context,
    required String itemName,
    String? customMessage,
  }) async {
    return await show(
      context: context,
      title: 'Delete $itemName',
      message:
          customMessage ??
          'Are you sure you want to delete this $itemName? This action cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      icon: Icons.delete_forever,
      iconColor: Colors.red,
      confirmColor: Colors.red,
    );
  }

  /// Show a clear data confirmation dialog
  static Future<bool> showClearData({
    required BuildContext context,
    required String dataType,
    String? customMessage,
  }) async {
    return await show(
      context: context,
      title: 'Clear $dataType',
      message:
          customMessage ??
          'Are you sure you want to clear all $dataType? This will free up storage space but remove cached data.',
      confirmText: 'Clear',
      cancelText: 'Cancel',
      icon: Icons.clear_all,
      iconColor: Colors.orange,
      confirmColor: Colors.orange,
    );
  }

  /// Show a reset confirmation dialog
  static Future<bool> showReset({
    required BuildContext context,
    required String itemName,
    String? customMessage,
  }) async {
    return await show(
      context: context,
      title: 'Reset $itemName',
      message:
          customMessage ??
          'Are you sure you want to reset $itemName? All settings will be restored to defaults.',
      confirmText: 'Reset',
      cancelText: 'Cancel',
      icon: Icons.restore,
      iconColor: Colors.red,
      confirmColor: Colors.red,
    );
  }
}
