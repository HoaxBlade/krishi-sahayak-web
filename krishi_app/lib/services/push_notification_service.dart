import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'preferences_service.dart';

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _initializeLocalNotifications();
    await _requestPermissions();

    _isInitialized = true;
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.notification.request();
    if (status.isDenied) {
      debugPrint('Notification permission denied');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    debugPrint('Notification tapped: ${response.payload}');

    // Navigate to appropriate screen based on notification type
    if (response.payload != null) {
      final data = json.decode(response.payload!);
      _handleNotificationNavigation(data);
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'] as String?;

    switch (type) {
      case 'weather_alert':
        // Navigate to weather screen
        break;
      case 'crop_reminder':
        // Navigate to crop screen
        break;
      case 'sync_complete':
        // Show sync status
        break;
      default:
        // Navigate to home screen
        break;
    }
  }

  Future<void> showWeatherAlert({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showNotification(
      id: 1,
      title: title,
      body: body,
      payload: payload ?? json.encode({'type': 'weather_alert'}),
      channelId: 'weather_alerts',
      channelName: 'Weather Alerts',
      channelDescription: 'Important weather updates and alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
  }

  Future<void> showCropReminder({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showNotification(
      id: 2,
      title: title,
      body: body,
      payload: payload ?? json.encode({'type': 'crop_reminder'}),
      channelId: 'crop_reminders',
      channelName: 'Crop Reminders',
      channelDescription: 'Reminders for crop management tasks',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
  }

  Future<void> showSyncNotification({
    required String title,
    required String body,
    bool isSuccess = true,
  }) async {
    await _showNotification(
      id: 3,
      title: title,
      body: body,
      payload: json.encode({'type': 'sync_complete', 'success': isSuccess}),
      channelId: 'sync_notifications',
      channelName: 'Sync Notifications',
      channelDescription: 'Data synchronization status updates',
      importance: Importance.low,
      priority: Priority.low,
    );
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    required String channelId,
    required String channelName,
    required String channelDescription,
    required Importance importance,
    required Priority priority,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: importance,
          priority: priority,
          showWhen: true,
          enableVibration: true,
          enableLights: true,
          color: const Color(0xFF4CAF50), // Green color for agriculture theme
        );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> scheduleCropReminder({
    required String cropName,
    required String task,
    required DateTime scheduledTime,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'crop_reminders',
          'Crop Reminders',
          channelDescription: 'Scheduled reminders for crop management tasks',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails();

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _localNotifications.periodicallyShow(
      100 + DateTime.now().millisecondsSinceEpoch % 1000, // Unique ID
      'Crop Reminder: $cropName',
      'Time to $task for your $cropName',
      RepeatInterval.daily,
      notificationDetails,
      payload: json.encode({
        'type': 'crop_reminder',
        'crop_name': cropName,
        'task': task,
      }),
    );
  }

  Future<void> scheduleWeatherCheck() async {
    // Schedule daily weather check at 6 AM
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'weather_checks',
          'Weather Checks',
          channelDescription: 'Daily weather updates',
          importance: Importance.low,
          priority: Priority.low,
        );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails();

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _localNotifications.periodicallyShow(
      4,
      'Daily Weather Update',
      'Check today\'s weather for your crops',
      RepeatInterval.daily,
      notificationDetails,
      payload: json.encode({'type': 'weather_check'}),
    );
  }

  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }

  Future<bool> isNotificationEnabled() async {
    return PreferencesService().getNotificationEnabled();
  }

  Future<void> setNotificationEnabled(bool enabled) async {
    await PreferencesService().setNotificationEnabled(enabled);

    if (!enabled) {
      await cancelAllNotifications();
    }
  }

  Future<void> showTestNotification() async {
    await showCropReminder(
      title: 'Test Notification',
      body: 'This is a test notification from Krishi Sahayak',
    );
  }

  void dispose() {
    // Cleanup if needed
  }
}
