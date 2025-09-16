// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:weather/weather.dart';
import 'package:geolocator/geolocator.dart';
import 'database_helper.dart';
import 'config_service.dart';
import 'cache_service.dart';
import 'firebase_analytics_service.dart';
import 'dart:io'; // Added for Directory.current
import 'location_service.dart';

class WeatherData {
  final int? id;
  final DateTime date;
  final double? temperature;
  final double? humidity;
  final double? rainfall;
  final double? windSpeed;
  final String? description;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;

  WeatherData({
    this.id,
    required this.date,
    this.temperature,
    this.humidity,
    this.rainfall,
    this.windSpeed,
    this.description,
    this.latitude,
    this.longitude,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'temperature': temperature,
      'humidity': humidity,
      'rainfall': rainfall,
      'wind_speed': windSpeed,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WeatherData.fromMap(Map<String, dynamic> map) {
    return WeatherData(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      temperature: map['temperature'] as double?,
      humidity: map['humidity'] as double?,
      rainfall: map['rainfall'] as double?,
      windSpeed: map['wind_speed'] as double?,
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
    );
  }

  factory WeatherData.fromWeather(
    Weather weather, {
    double? latitude,
    double? longitude,
  }) {
    return WeatherData(
      date: DateTime.now(),
      temperature: weather.temperature?.celsius,
      humidity: weather.humidity?.toDouble(),
      rainfall: weather.rainLastHour,
      windSpeed: weather.windSpeed,
      latitude: latitude,
      longitude: longitude,
      description: weather.weatherDescription,
    );
  }
}

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  WeatherFactory? _weatherFactory;
  final ConfigService _configService = ConfigService();
  final CacheService _cacheService = CacheService();
  final FirebaseAnalyticsService _analytics = FirebaseAnalyticsService();

  Position? _currentPosition;
  Timer? _refreshTimer;
  static const Duration _refreshInterval = Duration(minutes: 10);

  // Initialize weather service
  Future<void> initialize() async {
    debugPrint('🌤️ [WeatherService] Initializing weather service...');

    // Check if already initialized
    if (_weatherFactory != null) {
      debugPrint('✅ [WeatherService] Already initialized, skipping...');
      return;
    }

    // Initialize config service first
    await _configService.initialize();

    // Initialize weather factory with API key from config
    final apiKey = _configService.openWeatherMapApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint(
        '❌ [WeatherService] OpenWeatherMap API key not found in environment variables',
      );
      debugPrint(
        '📝 [WeatherService] Please create a .env file with OPENWEATHERMAP_API_KEY=your_api_key',
      );
      debugPrint(
        '📁 [WeatherService] Expected location: ${Directory.current.path}/.env',
      );
      throw Exception(
        'OpenWeatherMap API key not found. Please create a .env file with OPENWEATHERMAP_API_KEY=your_api_key',
      );
    }

    if (apiKey == 'DEMO_KEY' || apiKey.length < 10) {
      debugPrint('❌ [WeatherService] Invalid API key detected: $apiKey');
      debugPrint(
        '📝 [WeatherService] Please use a valid OpenWeatherMap API key',
      );
      throw Exception(
        'Invalid API key. Please use a valid OpenWeatherMap API key from openweathermap.org',
      );
    }

    _weatherFactory = WeatherFactory(apiKey);
    debugPrint(
      '🔑 [WeatherService] Weather API initialized with key: ${apiKey.substring(0, 8)}...',
    );

    _currentPosition = await LocationService().getCurrentLocation();
    _startAutoRefresh();
  }


  // Start automatic refresh timer
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      debugPrint('🔄 [WeatherService] Auto-refreshing weather data...');
      fetchCurrentWeather();
    });
    debugPrint(
      '⏰ [WeatherService] Auto-refresh timer started (${_refreshInterval.inMinutes} minutes)',
    );
  }

  // Check if weather service is ready
  bool get isReady => _weatherFactory != null && _currentPosition != null;

  // Ensure service is initialized
  Future<void> _ensureInitialized() async {
    if (!isReady) {
      debugPrint(
        '⚠️ [WeatherService] Service not initialized, initializing now...',
      );
      await initialize();
    }
  }

  // Fetch current weather API
  Future<WeatherData?> fetchCurrentWeather() async {
    try {
      await _ensureInitialized();

      if (_currentPosition == null) {
        _currentPosition = await LocationService().getCurrentLocation();
        if (_currentPosition == null) {
          debugPrint(
            '❌ [WeatherService] No location available for weather fetch',
          );
          return null;
        }
      }

      debugPrint('🌤️ [WeatherService] Fetching current weather from API...');
      final stopwatch = Stopwatch()..start();

      Weather weather = await _weatherFactory!.currentWeatherByLocation(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      stopwatch.stop();
      debugPrint(
        '✅ [WeatherService] Weather API call completed in ${stopwatch.elapsedMilliseconds}ms',
      );

      final weatherData = WeatherData.fromWeather(
        weather,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );

      // Cache the weather data
      debugPrint('💾 [WeatherService] Caching weather data...');
      await cacheWeatherData(weatherData);
      debugPrint('✅ [WeatherService] Weather data cached successfully');

      // Track analytics
      await _analytics.logWeatherCheck(
        location:
            '${_currentPosition!.latitude},${_currentPosition!.longitude}',
        temperature: weatherData.temperature ?? 0.0,
        humidity: weatherData.humidity ?? 0.0,
        description: weatherData.description ?? 'unknown',
      );

      return weatherData;
    } catch (e) {
      debugPrint('💥 [WeatherService] Error fetching current weather: $e');
      return null;
    }
  }

  // Fetch weather forecast from API
  Future<List<WeatherData>> fetchWeatherForecast({int days = 7}) async {
    try {
      await _ensureInitialized();

      if (_currentPosition == null) {
        _currentPosition = await LocationService().getCurrentLocation();
        if (_currentPosition == null) {
          debugPrint(
            '❌ [WeatherService] No location available for forecast fetch',
          );
          return [];
        }
      }

      debugPrint('🌤️ [WeatherService] Fetching weather forecast from API...');
      final stopwatch = Stopwatch()..start();

      List<Weather> forecast = await _weatherFactory!.fiveDayForecastByLocation(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      stopwatch.stop();
      debugPrint(
        '✅ [WeatherService] Forecast API call completed in ${stopwatch.elapsedMilliseconds}ms',
      );

      List<WeatherData> forecastData = [];
      for (int i = 0; i < days && i < forecast.length; i++) {
        final weather = forecast[i];
        final weatherData = WeatherData.fromWeather(
          weather,
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
        );
        forecastData.add(weatherData);

        // Cache each forecast data point
        await cacheWeatherData(weatherData);
      }

      debugPrint('💾 [WeatherService] Forecast data cached successfully');
      return forecastData;
    } catch (e) {
      debugPrint('💥 [WeatherService] Error fetching forecast: $e');
      return [];
    }
  }

  // Update all weather data (current + forecast)
  Future<void> updateWeatherData() async {
    debugPrint('🔄 [WeatherService] Updating all weather data...');
    final stopwatch = Stopwatch()..start();

    await fetchCurrentWeather();
    await fetchWeatherForecast();

    stopwatch.stop();
    debugPrint(
      '✅ [WeatherService] All weather data updated in ${stopwatch.elapsedMilliseconds}ms',
    );
  }

  // Cache weather data
  Future<bool> cacheWeatherData(WeatherData weatherData) async {
    try {
      final id = await _dbHelper.insertWeatherData(weatherData.toMap());
      return id > 0;
    } catch (e) {
      debugPrint('❌ [WeatherService] Error caching weather data: $e');
      return false;
    }
  }

  // Get latest weather data with smart caching
  Future<WeatherData?> getLatestWeather() async {
    try {
      // Check cache first for recent data
      final cacheKey =
          'current_weather_${_currentPosition?.latitude}_${_currentPosition?.longitude}';
      final cachedWeather = _cacheService.get(cacheKey);

      if (cachedWeather != null) {
        debugPrint('⚡ [WeatherService] Using cached weather data (fast)');
        return WeatherData.fromMap(cachedWeather);
      }

      // Check if we have fresh data in database
      if (await isWeatherDataFresh()) {
        debugPrint('📱 [WeatherService] Using fresh database weather data');
        final weatherData = await _dbHelper.getLatestWeather();
        if (weatherData != null) {
          final weather = WeatherData.fromMap(weatherData);
          // Cache for quick access
          await _cacheService.set(cacheKey, weatherData, 'weather');
          return weather;
        }
      }

      // Fetch fresh data from API
      debugPrint('🌐 [WeatherService] Fetching fresh weather data from API');
      final freshWeather = await fetchCurrentWeather();
      if (freshWeather != null) {
        // Cache the fresh data
        await _cacheService.set(cacheKey, freshWeather.toMap(), 'weather');
        return freshWeather;
      }

      // Final fallback to any cached data
      debugPrint('📱 [WeatherService] Using any available cached weather data');
      final weatherData = await _dbHelper.getLatestWeather();
      return weatherData != null ? WeatherData.fromMap(weatherData) : null;
    } catch (e) {
      debugPrint('❌ [WeatherService] Error getting latest weather: $e');
      return null;
    }
  }

  // Get weather data for specific date
  Future<WeatherData?> getWeatherForDate(DateTime date) async {
    try {
      final weatherDataList = await _dbHelper.getWeatherData(limit: 30);
      final targetDate = DateTime(date.year, date.month, date.day);

      for (final data in weatherDataList) {
        final weatherDate = DateTime.parse(data['date'] as String);
        final weatherDateOnly = DateTime(
          weatherDate.year,
          weatherDate.month,
          weatherDate.day,
        );

        if (weatherDateOnly.isAtSameMomentAs(targetDate)) {
          return WeatherData.fromMap(data);
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ [WeatherService] Error getting weather for date: $e');
      return null;
    }
  }

  // Get weather forecast with smart caching
  Future<List<WeatherData>> getWeatherForecast({int days = 7}) async {
    try {
      // Check cache first for recent forecast
      final cacheKey =
          'weather_forecast_${days}d_${_currentPosition?.latitude}_${_currentPosition?.longitude}';
      final cachedForecast = _cacheService.get(cacheKey);

      if (cachedForecast != null) {
        debugPrint('⚡ [WeatherService] Using cached forecast data (fast)');
        return (cachedForecast as List)
            .map((data) => WeatherData.fromMap(data))
            .toList();
      }

      // Check if we have recent forecast in database
      final dbForecast = await _dbHelper.getWeatherData(limit: days);
      if (dbForecast.isNotEmpty) {
        final latestDbEntry = DateTime.parse(dbForecast.first['created_at']);
        final timeSinceUpdate = DateTime.now().difference(latestDbEntry);

        if (timeSinceUpdate.inMinutes < 30) {
          debugPrint('📱 [WeatherService] Using recent database forecast');
          final forecast = dbForecast
              .map((data) => WeatherData.fromMap(data))
              .toList();
          // Cache for quick access
          await _cacheService.set(cacheKey, dbForecast, 'weather');
          return forecast;
        }
      }

      // Fetch fresh forecast from API
      debugPrint('🌐 [WeatherService] Fetching fresh forecast from API');
      final freshForecast = await fetchWeatherForecast(days: days);
      if (freshForecast.isNotEmpty) {
        // Cache the fresh forecast
        final forecastMaps = freshForecast.map((w) => w.toMap()).toList();
        await _cacheService.set(cacheKey, forecastMaps, 'weather');
        return freshForecast;
      }

      // Fallback to any available cached data
      debugPrint('📱 [WeatherService] Using any available forecast data');
      return dbForecast.map((data) => WeatherData.fromMap(data)).toList();
    } catch (e) {
      debugPrint('❌ [WeatherService] Error getting forecast: $e');
      return [];
    }
  }

  // Get weather history
  Future<List<WeatherData>> getWeatherHistory({int days = 30}) async {
    try {
      final weatherDataList = await _dbHelper.getWeatherData(limit: days);
      return weatherDataList.map((data) => WeatherData.fromMap(data)).toList();
    } catch (e) {
      debugPrint('❌ [WeatherService] Error getting weather history: $e');
      return [];
    }
  }

  // Check if weather data is fresh (less than 15 minutes old)
  Future<bool> isWeatherDataFresh() async {
    try {
      // Directly check database without going through getLatestWeather to avoid recursion
      final latestWeather = await _dbHelper.getLatestWeather();
      if (latestWeather == null) return false;

      final now = DateTime.now();
      final timeDifference = now.difference(
        DateTime.parse(latestWeather['created_at']),
      );
      return timeDifference.inMinutes < 15;
    } catch (e) {
      debugPrint(
        '❌ [WeatherService] Error checking weather data freshness: $e',
      );
      return false;
    }
  }

  // Clear old weather data (older than 30 days)
  Future<void> clearOldWeatherData() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final weatherDataList = await _dbHelper.getWeatherData(limit: 1000);

      for (final data in weatherDataList) {
        final weatherDate = DateTime.parse(data['date'] as String);
        if (weatherDate.isBefore(thirtyDaysAgo)) {
          // Note: We'll need to add a delete method to DatabaseHelper for this
          // For now, we'll just log it
          debugPrint('Would delete old weather data: ${data['date']}');
        }
      }
    } catch (e) {
      debugPrint('❌ [WeatherService] Error clearing old weather data: $e');
    }
  }

  // Get weather statistics
  Future<Map<String, dynamic>> getWeatherStats({int days = 7}) async {
    try {
      final weatherDataList = await getWeatherHistory(days: days);

      if (weatherDataList.isEmpty) {
        return {
          'avgTemperature': 0.0,
          'avgHumidity': 0.0,
          'totalRainfall': 0.0,
          'avgWindSpeed': 0.0,
        };
      }

      double totalTemp = 0;
      double totalHumidity = 0;
      double totalRainfall = 0;
      double totalWindSpeed = 0;
      int tempCount = 0;
      int humidityCount = 0;
      int windCount = 0;

      for (final weather in weatherDataList) {
        if (weather.temperature != null) {
          totalTemp += weather.temperature!;
          tempCount++;
        }
        if (weather.humidity != null) {
          totalHumidity += weather.humidity!;
          humidityCount++;
        }
        if (weather.rainfall != null) {
          totalRainfall += weather.rainfall!;
        }
        if (weather.windSpeed != null) {
          totalWindSpeed += weather.windSpeed!;
          windCount++;
        }
      }

      return {
        'avgTemperature': tempCount > 0 ? totalTemp / tempCount : 0.0,
        'avgHumidity': humidityCount > 0 ? totalHumidity / humidityCount : 0.0,
        'totalRainfall': totalRainfall,
        'avgWindSpeed': windCount > 0 ? totalWindSpeed / windCount : 0.0,
      };
    } catch (e) {
      debugPrint('❌ [WeatherService] Error getting weather stats: $e');
      return {
        'avgTemperature': 0.0,
        'avgHumidity': 0.0,
        'totalRainfall': 0.0,
        'avgWindSpeed': 0.0,
      };
    }
  }

  // Get current location coordinates
  Position? get currentPosition => _currentPosition;

  // Manual refresh
  Future<void> refresh() async {
    debugPrint('🔄 [WeatherService] Manual refresh requested...');
    await updateWeatherData();
  }

  // Reset the service (useful for testing or reinitialization)
  Future<void> reset() async {
    debugPrint('🔄 [WeatherService] Resetting weather service...');
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _currentPosition = null;
    _weatherFactory = null;
    // _isInitialized = false; // This field doesn't exist in the original file
  }

  // Dispose resources
  void dispose() {
    debugPrint('🧹 [WeatherService] Disposing weather service...');
    _refreshTimer?.cancel();
    _refreshTimer = null;
    // Don't reset other fields as this is a singleton
  }
}
