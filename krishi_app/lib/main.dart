// ignore_for_file: avoid_print, unused_field

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/database_helper.dart';
import 'services/connectivity_service.dart';
import 'services/preferences_service.dart';
import 'services/sync_service.dart';
import 'services/error_handler_service.dart';
import 'services/analytics_service.dart';
import 'services/firebase_analytics_service.dart';
import 'services/cache_service.dart';
import 'services/offline_maps_service.dart';
import 'services/image_storage_service.dart';
import 'services/background_sync_service.dart';
import 'services/push_notification_service.dart';
import 'services/config_service.dart';
import 'services/weather_service.dart';
import 'services/ml_service.dart';
import 'services/location_service.dart';
import 'screens/home_screen.dart';
import 'screens/crop_screen.dart';
import 'screens/weather_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/advanced_features_demo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

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

  // Initialize Location Service
  await LocationService().initialize();

  // Initialize Firebase Analytics
  await FirebaseAnalyticsService().initialize();

  // Initialize weather service (depends on config) - handle errors gracefully
  try {
    await WeatherService().initialize();
    debugPrint('✅ [Main] Weather service initialized successfully');
  } catch (e) {
    debugPrint('⚠️ [Main] Weather service initialization failed: $e');
    debugPrint('📱 [Main] App will continue without weather functionality');
  }

  // Initialize ML service (depends on config) - handle errors gracefully
  try {
    await MLService().initialize();
    debugPrint('✅ [Main] ML service initialized successfully');
  } catch (e) {
    debugPrint('⚠️ [Main] ML service initialization failed: $e');
    debugPrint('📱 [Main] App will continue without offline ML functionality');
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
      debugShowCheckedModeBanner: false,
      title: 'Krishi Sahayak',
      theme: ThemeData(
        useMaterial3: true,
        // Define a custom color scheme for a more refined look
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          primary: const Color(0xFF16A34A), // A slightly darker green for primary actions
          onPrimary: Colors.white,
          secondary: const Color(0xFF3B82F6), // A blue for secondary actions/accents
          onSecondary: Colors.white,
          surface: Colors.white, // Clean white surfaces
          onSurface: const Color(0xFF1F2937), // Dark gray for text on surfaces
          background: const Color(0xFFF9FAFB), // Light gray background
          onBackground: const Color(0xFF1F2937),
          error: Colors.red.shade700,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB), // Consistent light background
        fontFamily: 'SF Pro Display', // Attempting an Apple-like font (might need to import custom font)

        // AppBar Theme for a minimalistic, clean look
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F2937),
          elevation: 0, // Flat app bar
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: const Color(0xFF1F2937),
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'SF Pro Display',
          ),
        ),

        // Card Theme for subtle depth and rounded corners
        cardTheme: CardThemeData( // Corrected to CardThemeData and removed const
          elevation: 2, // Subtle shadow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Consistent rounded corners
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0), // Consistent margins
        ),

        // ElevatedButton Theme for premium buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF16A34A), // Green primary button
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), // Rounded corners
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'SF Pro Display',
            ),
            elevation: 2, // Subtle shadow
            shadowColor: Colors.green.shade200,
          ),
        ),

        // TextButton Theme
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF16A34A), // Green text buttons
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'SF Pro Display',
            ),
          ),
        ),

        // Bottom Navigation Bar Theme
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF16A34A), // Green for selected items
          unselectedItemColor: Colors.grey.shade600, // Darker grey for unselected
          elevation: 8, // Subtle shadow for the bar
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            fontFamily: 'SF Pro Display',
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
            fontFamily: 'SF Pro Display',
          ),
        ),

        // Input Decoration Theme for text fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none, // No border by default
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: const Color(0xFF16A34A), width: 2), // Green border on focus
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1), // Subtle border when enabled
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          hintStyle: TextStyle(color: Colors.grey.shade500),
        ),
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
      debugPrint('Global error caught: ${error.message}');

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
