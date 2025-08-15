// ignore_for_file: avoid_print, unused_field

import 'package:flutter/material.dart';
import 'services/database_helper.dart';
import 'services/connectivity_service.dart';
import 'services/preferences_service.dart';
import 'services/sync_service.dart';
import 'services/error_handler_service.dart';
import 'services/analytics_service.dart';
import 'services/cache_service.dart';
import 'services/offline_maps_service.dart';
import 'services/image_storage_service.dart';
import 'services/background_sync_service.dart';
import 'services/push_notification_service.dart';
import 'services/config_service.dart';
import 'services/weather_service.dart';
import 'screens/home_screen.dart';
import 'screens/crop_screen.dart';
import 'screens/weather_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/advanced_features_demo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core services
  await DatabaseHelper().database;
  await ConnectivityService().initialize();
  await PreferencesService().initialize();
  await SyncService().initialize();

  // Initialize Phase 5 advanced services
  await OfflineMapsService().initialize();
  await ImageStorageService().initialize();
  await BackgroundSyncService().initialize();
  await PushNotificationService().initialize();

  // Initialize configuration service first
  await ConfigService().initialize();

  // Initialize weather service (depends on config) - handle errors gracefully
  try {
    await WeatherService().initialize();
    print('✅ [Main] Weather service initialized successfully');
  } catch (e) {
    print('⚠️ [Main] Weather service initialization failed: $e');
    print('📱 [Main] App will continue without weather functionality');
  }

  // Initialize error handler (no async initialization needed)
  ErrorHandlerService();

  // Initialize analytics and cache services
  await AnalyticsService().trackEvent('app_started');
  await CacheService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Krishi Sahayak',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MainScreen(),
      builder: (context, child) {
        return ErrorHandlerWrapper(child: child!);
      },
    );
  }
}

class ErrorHandlerWrapper extends StatefulWidget {
  final Widget child;

  const ErrorHandlerWrapper({super.key, required this.child});

  @override
  State<ErrorHandlerWrapper> createState() => _ErrorHandlerWrapperState();
}

class _ErrorHandlerWrapperState extends State<ErrorHandlerWrapper> {
  final ErrorHandlerService _errorHandler = ErrorHandlerService();

  @override
  void initState() {
    super.initState();
    _setupErrorListener();
  }

  void _setupErrorListener() {
    _errorHandler.errorStream.listen((error) {
      // Log error for debugging
      print('Global error caught: ${error.message}');

      // You can add global error handling here, like showing a snackbar
      // or sending error reports to analytics
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    CropScreen(),
    WeatherScreen(),
    AdvancedFeaturesDemo(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeScreen(onNavigateToAdvanced: () => _navigateToTab(3)),
          CropScreen(),
          WeatherScreen(),
          AdvancedFeaturesDemo(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.agriculture),
            label: 'Crops',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.wb_sunny), label: 'Weather'),
          BottomNavigationBarItem(
            icon: Icon(Icons.rocket_launch),
            label: 'Advanced',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
