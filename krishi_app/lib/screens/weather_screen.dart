import 'package:flutter/material.dart';
import 'dart:async';
import '../services/weather_service.dart';
import '../services/connectivity_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService();
  final ConnectivityService _connectivityService = ConnectivityService();

  WeatherData? _currentWeather;
  List<WeatherData> _forecast = [];
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
      final weather = await _weatherService.getLatestWeather();
      final forecast = await _weatherService.getWeatherForecast();
      final stats = await _weatherService.getWeatherStats();
      final isConnected = _connectivityService.isConnected;

      setState(() {
        _currentWeather = weather;
        _forecast = forecast;
        _stats = stats;
        _isConnected = isConnected;
        _isLoading = false;
      });

      debugPrint('✅ [WeatherScreen] Weather data loaded successfully');
    } catch (e) {
      debugPrint('❌ [WeatherScreen] Error loading weather data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshWeather() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    try {
      debugPrint('🔄 [WeatherScreen] Refreshing weather data...');
      await _weatherService.refresh();
      await _loadWeatherData();
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                    _buildForecast(),
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
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No current weather data available'),
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

  Widget _buildForecast() {
    if (_forecast.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No forecast data available'),
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
              'Weather Forecast',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ..._forecast
                .take(5)
                .map(
                  (weather) => ListTile(
                    leading: const Icon(Icons.wb_sunny),
                    title: Text(weather.date.toString().split(' ')[0]),
                    subtitle: Text(weather.description ?? 'No description'),
                    trailing: Text(
                      '${weather.temperature?.toStringAsFixed(1) ?? 'N/A'}°C',
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    final position = _weatherService.currentPosition;
    if (position == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Location',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Location not available'),
              Text(
                'Please enable location permissions in app settings',
                style: TextStyle(fontSize: 12, color: Colors.grey),
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
