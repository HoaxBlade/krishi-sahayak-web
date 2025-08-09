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
  StreamSubscription<bool>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
    _setupConnectivityListener();
  }

  Future<void> _loadWeatherData() async {
    setState(() => _isLoading = true);
    try {
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
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = _connectivityService.connectionStatus.listen((
      isConnected,
    ) {
      if (mounted) {
        setState(() => _isConnected = isConnected);
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Weather'),
        actions: [
          if (!_isConnected) const Icon(Icons.wifi_off, color: Colors.red),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWeatherData,
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
}
