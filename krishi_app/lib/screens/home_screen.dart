import 'package:flutter/material.dart';
import 'dart:async';
import '../services/crop_service.dart';
import '../services/weather_service.dart';
import '../services/user_service.dart';
import '../services/connectivity_service.dart';
import '../services/firebase_analytics_service.dart';
import '../models/crop.dart';
import '../widgets/offline_indicator.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToAdvanced;

  const HomeScreen({super.key, this.onNavigateToAdvanced});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CropService _cropService = CropService();
  final WeatherService _weatherService = WeatherService();
  final UserService _userService = UserService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final FirebaseAnalyticsService _analytics = FirebaseAnalyticsService();

  List<Crop> _crops = [];
  List<Crop> _upcomingHarvests = [];
  WeatherData? _currentWeather;
  Map<String, String> _userProfile = {};
  bool _isLoading = true;
  StreamSubscription<bool>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupConnectivityListener();
    _trackScreenView();
  }

  Future<void> _trackScreenView() async {
    await _analytics.logScreenView(
      screenName: 'home_screen',
      screenClass: 'HomeScreen',
    );
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final crops = await _cropService.getActiveCrops();
      final harvests = await _cropService.getUpcomingHarvests();
      final weather = await _weatherService.getLatestWeather();
      final profile = await _userService.getProfileSummary();

      setState(() {
        _crops = crops;
        _upcomingHarvests = harvests;
        _currentWeather = weather;
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = _connectivityService.connectionStatus.listen((
      isConnected,
    ) {
      if (mounted) {
        // Reload data when connectivity changes, especially if it comes online
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // backgroundColor and foregroundColor are now handled by AppBarTheme in main.dart
        title: Text('Krishi Sahayak - Home'), // Removed const to allow theme styling
        actions: [const OfflineIndicator(), const SyncStatusIndicator()],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)) // Themed progress indicator
          : RefreshIndicator(
              onRefresh: _loadData,
              color: Theme.of(context).colorScheme.primary, // Themed refresh indicator
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(),
                    const SizedBox(height: 16),
                    _buildStatsCards(),
                    const SizedBox(height: 16),
                    _buildUpcomingHarvests(),
                    const SizedBox(height: 16),
                    _buildWeatherCard(),
                    const SizedBox(height: 16),
                    _buildAdvancedFeaturesCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0), // Adjusted padding
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20), // More generous padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, ${_userProfile['name'] ?? 'Farmer'}!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600, // Slightly bolder
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage your crops and stay updated with weather information.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), // Subtle text color
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20), // More generous padding
              child: Column(
                children: [
                  Icon(Icons.agriculture, size: 36, color: Theme.of(context).colorScheme.primary), // Themed icon
                  const SizedBox(height: 12), // Increased spacing
                  Text(
                    '${_crops.length}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700, // Bolder value
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Active Crops',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), // Subtle text
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20), // More generous padding
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 36,
                    color: Theme.of(context).colorScheme.secondary, // Themed icon
                  ),
                  const SizedBox(height: 12), // Increased spacing
                  Text(
                    '${_upcomingHarvests.length}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700, // Bolder value
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Upcoming Harvests',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), // Subtle text
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingHarvests() {
    if (_upcomingHarvests.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20), // More generous padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.agriculture, size: 28, color: Theme.of(context).colorScheme.primary), // Themed icon
                  const SizedBox(width: 10),
                  Text(
                    'Upcoming Harvests',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16), // Increased spacing
              Container(
                padding: const EdgeInsets.all(16), // More padding
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.05), // Subtle background
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)), // Subtle border
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary), // Themed icon
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Add crops to track harvest dates and get reminders.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.9), // Themed text color
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16), // Increased spacing
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to add crop
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Your First Crop'),
                // Style is now handled by ElevatedButtonThemeData in main.dart
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20), // More generous padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming Harvests',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12), // Increased spacing
            ..._upcomingHarvests
                .take(3)
                .map(
                  (crop) => ListTile(
                    leading: Icon(Icons.agriculture, color: Theme.of(context).colorScheme.primary), // Themed icon
                    title: Text(crop.name, style: Theme.of(context).textTheme.titleMedium),
                    subtitle: Text(
                      'Harvest: ${crop.harvestDate?.toString().split(' ')[0] ?? 'Not set'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4), // Adjusted padding
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    if (_currentWeather == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20), // More generous padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.wb_sunny, size: 28, color: Theme.of(context).colorScheme.secondary), // Themed icon
                  const SizedBox(width: 10),
                  Text(
                    'Current Weather',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16), // Increased spacing
              Container(
                padding: const EdgeInsets.all(16), // More padding
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.05), // Subtle background
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                  border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.2)), // Subtle border
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_off, color: Theme.of(context).colorScheme.secondary), // Themed icon
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Weather data will appear here. Check your internet connection.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.9), // Themed text color
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20), // More generous padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wb_sunny, size: 28, color: Theme.of(context).colorScheme.secondary), // Themed icon
                const SizedBox(width: 10),
                Text(
                  'Current Weather',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const OfflineIndicator(showText: true, iconSize: 16),
              ],
            ),
            const SizedBox(height: 12), // Increased spacing
            Row(
              children: [
                Text(
                  '${_currentWeather!.temperature?.toStringAsFixed(1) ?? 'N/A'}°C',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 20), // Increased spacing
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Humidity: ${_currentWeather!.humidity?.toStringAsFixed(1) ?? 'N/A'}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      'Rainfall: ${_currentWeather!.rainfall?.toStringAsFixed(1) ?? 'N/A'} mm',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedFeaturesCard() {
    return Card(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.05), // Themed background
      child: Padding(
        padding: const EdgeInsets.all(20), // More generous padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rocket_launch, size: 28, color: Theme.of(context).colorScheme.primary), // Themed icon
                const SizedBox(width: 10),
                Text(
                  'Advanced Features',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary, // Themed text color
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(Icons.new_releases, color: Theme.of(context).colorScheme.secondary), // Themed icon
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Explore offline maps, image storage, background sync, and smart notifications.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16), // Increased spacing
            ElevatedButton.icon(
              onPressed: widget.onNavigateToAdvanced,
              icon: const Icon(Icons.explore),
              label: const Text('Explore Advanced Features'),
              // Style is now handled by ElevatedButtonThemeData in main.dart
            ),
          ],
        ),
      ),
    );
  }
}
