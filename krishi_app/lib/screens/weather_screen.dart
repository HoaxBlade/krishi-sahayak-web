import 'package:flutter/material.dart';
import 'dart:async';
import '../services/weather_service.dart';
import '../services/connectivity_service.dart';
import '../services/gemini_crop_recommendation_service.dart';
import '../models/crop_recommendation.dart';
import '../widgets/crop_details_dialog.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService();
  final ConnectivityService _connectivityService = ConnectivityService();

  WeatherData? _currentWeather;
  List<CropRecommendation> _cropRecommendations =
      GeminiCropRecommendationService.getDefaultCropRecommendations();
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  bool _isConnected = true;
  bool _isRefreshing = false;
  StreamSubscription<bool>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initializeWeather();
    _setupConnectivityListener();

    debugPrint(
      '🌾 [WeatherScreen] Initialized with ${_cropRecommendations.length} default crop recommendations',
    );
  }

  Future<void> _initializeWeather() async {
    debugPrint('🌤️ [WeatherScreen] Initializing weather...');
    await _weatherService.initialize();
    await _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    setState(() => _isLoading = true);
    try {
      debugPrint('📱 [WeatherScreen] Loading weather data...');
      // Use the new method that requests location permission
      final weather = await _weatherService.getWeatherWithLocationPermission(
        context,
      );
      final stats = await _weatherService.getWeatherStats();
      final isConnected = _connectivityService.isConnected;

      // Show default recommendations immediately
      setState(() {
        _currentWeather = weather;
        _stats = stats;
        _isConnected = isConnected;
        _isLoading = false;
      });

      // Load AI recommendations in background and update if successful
      debugPrint('🤖 [WeatherScreen] Calling background AI loading...');
      _loadAIRecommendationsInBackground();

      debugPrint('✅ [WeatherScreen] Weather data loaded successfully');
    } catch (e) {
      debugPrint('❌ [WeatherScreen] Error loading weather data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<List<CropRecommendation>> _getCropRecommendations() async {
    try {
      // Determine location, climate, and season based on current weather
      final location = 'India'; // You can get this from location service
      final climate = _getClimateFromWeather();
      final season = _getCurrentSeason();
      final soilType =
          'Alluvial'; // Default, can be enhanced with location data

      debugPrint('🌾 [WeatherScreen] Getting crop recommendations with:');
      debugPrint('   Location: $location');
      debugPrint('   Climate: $climate');
      debugPrint('   Season: $season');
      debugPrint('   Soil Type: $soilType');
      debugPrint('   Current Weather: ${_currentWeather?.temperature}°C');

      final recommendations =
          await GeminiCropRecommendationService.getCropRecommendations(
            location: location,
            climate: climate,
            season: season,
            soilType: soilType,
          );

      debugPrint(
        '🌾 [WeatherScreen] Received ${recommendations.length} crop recommendations',
      );
      return recommendations;
    } catch (e) {
      debugPrint('❌ [WeatherScreen] Error getting crop recommendations: $e');
      return [];
    }
  }

  String _getClimateFromWeather() {
    if (_currentWeather?.temperature != null) {
      final temp = _currentWeather!.temperature!;
      if (temp > 30) return 'Tropical';
      if (temp > 20) return 'Subtropical';
      if (temp > 10) return 'Temperate';
      return 'Cold';
    }
    return 'Tropical'; // Default for India
  }

  Future<void> _loadAIRecommendationsInBackground() async {
    try {
      debugPrint(
        '🤖 [WeatherScreen] Loading AI recommendations in background...',
      );
      debugPrint(
        '🤖 [WeatherScreen] Current crop count: ${_cropRecommendations.length}',
      );
      final aiRecommendations = await _getCropRecommendations();

      if (aiRecommendations.isNotEmpty && mounted) {
        setState(() {
          _cropRecommendations = aiRecommendations;
        });
        debugPrint('✅ [WeatherScreen] AI recommendations loaded successfully');
      }
    } catch (e) {
      debugPrint('❌ [WeatherScreen] Error loading AI recommendations: $e');
    }
  }

  String _getCurrentSeason() {
    final month = DateTime.now().month;
    if (month >= 6 && month <= 10) return 'Kharif';
    if (month >= 11 || month <= 3) return 'Rabi';
    return 'Summer';
  }

  Future<void> _refreshWeather() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    try {
      debugPrint('🔄 [WeatherScreen] Refreshing weather data...');
      // Use the new method that requests location permission
      final weather = await _weatherService.getWeatherWithLocationPermission(
        context,
      );
      final stats = await _weatherService.getWeatherStats();
      final isConnected = _connectivityService.isConnected;

      setState(() {
        _currentWeather = weather;
        _stats = stats;
        _isConnected = isConnected;
      });
      debugPrint('✅ [WeatherScreen] Weather data refreshed successfully');
    } catch (e) {
      debugPrint('❌ [WeatherScreen] Error refreshing weather: $e');
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = _connectivityService.connectionStatus.listen((
      isConnected,
    ) {
      if (mounted) {
        setState(() => _isConnected = isConnected);
        if (isConnected) {
          debugPrint(
            '📡 [WeatherScreen] Connection restored, refreshing weather...',
          );
          _refreshWeather();
        }
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _weatherService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '🌾 [WeatherScreen] Building with ${_cropRecommendations.length} crop recommendations',
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather'),
        actions: [
          if (!_isConnected) const Icon(Icons.wifi_off, color: Colors.red),
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshWeather,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshWeather,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCurrentWeather(),
                    const SizedBox(height: 16),
                    _buildWeatherStats(),
                    const SizedBox(height: 16),
                    _buildCropRecommendations(),
                    const SizedBox(height: 16),
                    _buildLocationInfo(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentWeather() {
    if (_currentWeather == null) {
      return Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.cloud_off, size: 32, color: Colors.grey[600]),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weather Data Unavailable',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pull down to refresh or check your connection',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _refreshWeather,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wb_sunny, size: 32, color: Colors.orange),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Weather',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        _currentWeather!.date.toString().split(' ')[0],
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (!_isConnected) ...[
                  const Icon(Icons.wifi_off, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  const Text(
                    'Offline',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherItem(
                  'Temperature',
                  '${_currentWeather!.temperature?.toStringAsFixed(1) ?? 'N/A'}°C',
                  Icons.thermostat,
                ),
                _buildWeatherItem(
                  'Humidity',
                  '${_currentWeather!.humidity?.toStringAsFixed(1) ?? 'N/A'}%',
                  Icons.water_drop,
                ),
                _buildWeatherItem(
                  'Rainfall',
                  '${_currentWeather!.rainfall?.toStringAsFixed(1) ?? 'N/A'} mm',
                  Icons.umbrella,
                ),
              ],
            ),
            if (_currentWeather!.description != null) ...[
              const SizedBox(height: 16),
              Text(
                _currentWeather!.description!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildWeatherStats() {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '7-Day Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Avg Temp',
                    '${_stats['avgTemperature']?.toStringAsFixed(1) ?? 'N/A'}°C',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Avg Humidity',
                    '${_stats['avgHumidity']?.toStringAsFixed(1) ?? 'N/A'}%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Rain',
                    '${_stats['totalRainfall']?.toStringAsFixed(1) ?? 'N/A'} mm',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Avg Wind',
                    '${_stats['avgWindSpeed']?.toStringAsFixed(1) ?? 'N/A'} km/h',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildCropRecommendations() {
    if (_cropRecommendations.isEmpty) {
      return Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.agriculture, size: 24, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Crop Recommendations',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Crop recommendations will appear here based on your location and weather conditions.',
                        style: TextStyle(color: Colors.grey),
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
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.agriculture,
                  size: 24,
                  color: const Color(0xFF16A34A),
                ),
                const SizedBox(width: 8),
                Text(
                  'Recommended Crops',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._cropRecommendations.map((crop) => _buildCropCard(crop)),
          ],
        ),
      ),
    );
  }

  Widget _buildCropCard(CropRecommendation crop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showCropDetails(crop),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.agriculture,
                  color: Color(0xFF16A34A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crop.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      crop.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildCropInfoChip('Season', crop.season),
                        _buildCropInfoChip('Water', crop.waterRequirement),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF6B7280),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCropInfoChip(String label, String value) {
    // Truncate long values to prevent overflow
    final truncatedValue = value.length > 15
        ? '${value.substring(0, 15)}...'
        : value;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $truncatedValue',
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF16A34A),
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _showCropDetails(CropRecommendation crop) {
    showDialog(
      context: context,
      builder: (context) => CropDetailsDialog(crop: crop),
    );
  }

  Widget _buildLocationInfo() {
    final position = _weatherService.currentPosition;
    if (position == null) {
      return Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Location',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_off, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  const Text('Location not available'),
                ],
              ),
              const Text(
                'Please enable location permissions in app settings',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Latitude: ${position.latitude.toStringAsFixed(4)}'),
            Text('Longitude: ${position.longitude.toStringAsFixed(4)}'),
            if (position.accuracy > 0)
              Text('Accuracy: ${position.accuracy.toStringAsFixed(1)} meters'),
            if (position.accuracy == 0)
              Text(
                'Using default location (New Delhi, India)',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
          ],
        ),
      ),
    );
  }
}
