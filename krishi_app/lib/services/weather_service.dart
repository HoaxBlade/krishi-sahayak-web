// ignore_for_file: avoid_print

import 'database_helper.dart';

class WeatherData {
  final int? id;
  final DateTime date;
  final double? temperature;
  final double? humidity;
  final double? rainfall;
  final double? windSpeed;
  final String? description;
  final DateTime createdAt;

  WeatherData({
    this.id,
    required this.date,
    this.temperature,
    this.humidity,
    this.rainfall,
    this.windSpeed,
    this.description,
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
    );
  }
}

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Cache weather data
  Future<bool> cacheWeatherData(WeatherData weatherData) async {
    try {
      final id = await _dbHelper.insertWeatherData(weatherData.toMap());
      return id > 0;
    } catch (e) {
      print('Error caching weather data: $e');
      return false;
    }
  }

  // Get latest weather data
  Future<WeatherData?> getLatestWeather() async {
    try {
      final weatherData = await _dbHelper.getLatestWeather();
      return weatherData != null ? WeatherData.fromMap(weatherData) : null;
    } catch (e) {
      print('Error getting latest weather: $e');
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
      print('Error getting weather for date: $e');
      return null;
    }
  }

  // Get weather forecast (cached data for next few days)
  Future<List<WeatherData>> getWeatherForecast({int days = 7}) async {
    try {
      final weatherDataList = await _dbHelper.getWeatherData(limit: days);
      return weatherDataList.map((data) => WeatherData.fromMap(data)).toList();
    } catch (e) {
      print('Error getting weather forecast: $e');
      return [];
    }
  }

  // Get weather history
  Future<List<WeatherData>> getWeatherHistory({int days = 30}) async {
    try {
      final weatherDataList = await _dbHelper.getWeatherData(limit: days);
      return weatherDataList.map((data) => WeatherData.fromMap(data)).toList();
    } catch (e) {
      print('Error getting weather history: $e');
      return [];
    }
  }

  // Check if weather data is fresh (less than 1 hour old)
  Future<bool> isWeatherDataFresh() async {
    try {
      final latestWeather = await getLatestWeather();
      if (latestWeather == null) return false;

      final now = DateTime.now();
      final timeDifference = now.difference(latestWeather.createdAt);
      return timeDifference.inHours < 1;
    } catch (e) {
      print('Error checking weather data freshness: $e');
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
          print('Would delete old weather data: ${data['date']}');
        }
      }
    } catch (e) {
      print('Error clearing old weather data: $e');
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
      print('Error getting weather stats: $e');
      return {
        'avgTemperature': 0.0,
        'avgHumidity': 0.0,
        'totalRainfall': 0.0,
        'avgWindSpeed': 0.0,
      };
    }
  }
}
