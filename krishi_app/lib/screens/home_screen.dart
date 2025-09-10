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
      if (mounted) {}
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Krishi Sahayak - Home'),
        actions: [const OfflineIndicator(), const SyncStatusIndicator()],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, ${_userProfile['name'] ?? 'Farmer'}!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your crops and stay updated with weather information.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
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
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.agriculture, size: 32, color: Colors.green),
                  const SizedBox(height: 8),
                  Text(
                    '${_crops.length}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Text('Active Crops'),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 32,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_upcomingHarvests.length}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Text('Upcoming Harvests'),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.agriculture, size: 24, color: Colors.green[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Upcoming Harvests',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green[600]),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Add crops to track harvest dates and get reminders.',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to add crop
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Your First Crop'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming Harvests',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ..._upcomingHarvests
                .take(3)
                .map(
                  (crop) => ListTile(
                    leading: const Icon(Icons.agriculture),
                    title: Text(crop.name),
                    subtitle: Text(
                      'Harvest: ${crop.harvestDate?.toString().split(' ')[0] ?? 'Not set'}',
                    ),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.wb_sunny, size: 24, color: Colors.orange[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Current Weather',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_off, color: Colors.orange[600]),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Weather data will appear here. Check your internet connection.',
                        style: TextStyle(color: Colors.orange),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wb_sunny, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Current Weather',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                const OfflineIndicator(showText: true, iconSize: 16),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${_currentWeather!.temperature?.toStringAsFixed(1) ?? 'N/A'}°C',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Humidity: ${_currentWeather!.humidity?.toStringAsFixed(1) ?? 'N/A'}%',
                    ),
                    Text(
                      'Rainfall: ${_currentWeather!.rainfall?.toStringAsFixed(1) ?? 'N/A'} mm',
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
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.rocket_launch, size: 24, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Advanced Features',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.green.shade700,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.new_releases, color: Colors.orange),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Explore offline maps, image storage, background sync, and smart notifications.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: widget.onNavigateToAdvanced,
              icon: const Icon(Icons.explore),
              label: const Text('Explore Advanced Features'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
