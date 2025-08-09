import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  static SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // App settings
  Future<void> setAppTheme(String theme) async {
    await _prefs?.setString('app_theme', theme);
  }

  String getAppTheme() {
    return _prefs?.getString('app_theme') ?? 'system';
  }

  Future<void> setLanguage(String language) async {
    await _prefs?.setString('language', language);
  }

  String getLanguage() {
    return _prefs?.getString('language') ?? 'en';
  }

  // User preferences
  Future<void> setUserName(String name) async {
    await _prefs?.setString('user_name', name);
  }

  String? getUserName() {
    return _prefs?.getString('user_name');
  }

  Future<void> setUserLocation(String location) async {
    await _prefs?.setString('user_location', location);
  }

  String? getUserLocation() {
    return _prefs?.getString('user_location');
  }

  // App state
  Future<void> setLastSyncTime(DateTime time) async {
    await _prefs?.setString('last_sync_time', time.toIso8601String());
  }

  DateTime? getLastSyncTime() {
    final timeString = _prefs?.getString('last_sync_time');
    return timeString != null ? DateTime.parse(timeString) : null;
  }

  Future<void> setOfflineMode(bool isOffline) async {
    await _prefs?.setBool('offline_mode', isOffline);
  }

  bool getOfflineMode() {
    return _prefs?.getBool('offline_mode') ?? false;
  }

  // Notifications
  Future<void> setNotificationEnabled(bool enabled) async {
    await _prefs?.setBool('notifications_enabled', enabled);
  }

  bool getNotificationEnabled() {
    return _prefs?.getBool('notifications_enabled') ?? true;
  }

  // Weather preferences
  Future<void> setTemperatureUnit(String unit) async {
    await _prefs?.setString('temperature_unit', unit);
  }

  String getTemperatureUnit() {
    return _prefs?.getString('temperature_unit') ?? 'celsius';
  }

  // Connectivity banner dismiss state
  Future<void> setConnectivityBannerDismissed(bool dismissed) async {
    await _prefs?.setBool('connectivity_banner_dismissed', dismissed);
  }

  bool getConnectivityBannerDismissed() {
    return _prefs?.getBool('connectivity_banner_dismissed') ?? false;
  }

  Future<void> setConnectivityBannerDismissTime(DateTime time) async {
    await _prefs?.setString(
      'connectivity_banner_dismiss_time',
      time.toIso8601String(),
    );
  }

  DateTime? getConnectivityBannerDismissTime() {
    final timeString = _prefs?.getString('connectivity_banner_dismiss_time');
    return timeString != null ? DateTime.parse(timeString) : null;
  }

  // Offline map progress tracking
  Future<void> setOfflineMapProgress(String mapName, double progress) async {
    await _prefs?.setDouble('offline_map_progress_$mapName', progress);
  }

  double getOfflineMapProgress(String mapName) {
    return _prefs?.getDouble('offline_map_progress_$mapName') ?? 0.0;
  }

  Future<void> setOfflineMapStatus(String mapName, String status) async {
    await _prefs?.setString('offline_map_status_$mapName', status);
  }

  String getOfflineMapStatus(String mapName) {
    return _prefs?.getString('offline_map_status_$mapName') ?? 'idle';
  }

  // Clear all preferences
  Future<void> clearAll() async {
    await _prefs?.clear();
  }

  // Generic settings methods
  Future<void> setSetting(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  String? getSetting(String key) {
    return _prefs?.getString(key);
  }
}
