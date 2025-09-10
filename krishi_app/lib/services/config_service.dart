// ignore_for_file: avoid_print

// ignore: unused_import
import 'dart:io';
import 'package:flutter/foundation.dart';

// Conditional import - this will work once flutter_dotenv is installed
// ignore: unused_import
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  static const String _envFileName = '.env';
  bool _isInitialized = false;
  final Map<String, String> _fallbackConfig = {};

  // API Keys
  String? get openWeatherMapApiKey {
    try {
      // Try to get from dotenv first
      return dotenv.dotenv.env['OPENWEATHERMAP_API_KEY'];
    } catch (e) {
      // Fallback to local config
      return _fallbackConfig['OPENWEATHERMAP_API_KEY'];
    }
  }

  /// Get Supabase URL
  String? get supabaseUrl {
    try {
      return dotenv.dotenv.env['SUPABASE_URL'];
    } catch (e) {
      return _fallbackConfig['SUPABASE_URL'];
    }
  }

  /// Get Supabase Anonymous Key
  String? get supabaseAnonKey {
    try {
      return dotenv.dotenv.env['SUPABASE_ANON_KEY'];
    } catch (e) {
      return _fallbackConfig['SUPABASE_ANON_KEY'];
    }
  }

  // Other configuration values can be added here
  String get appName {
    try {
      return dotenv.dotenv.env['APP_NAME'] ?? 'Krishi Sahayak';
    } catch (e) {
      return _fallbackConfig['APP_NAME'] ?? 'Krishi Sahayak';
    }
  }

  String get appVersion {
    try {
      return dotenv.dotenv.env['APP_VERSION'] ?? '1.0.0';
    } catch (e) {
      return _fallbackConfig['APP_VERSION'] ?? '1.0.0';
    }
  }

  // Environment
  String get environment {
    try {
      return dotenv.dotenv.env['ENVIRONMENT'] ?? 'development';
    } catch (e) {
      return _fallbackConfig['ENVIRONMENT'] ?? 'development';
    }
  }

  bool get isProduction => environment == 'production';
  bool get isDevelopment => environment == 'development';

  /// Initialize the configuration service
  /// This should be called before accessing any config values
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🔍 [ConfigService] Starting initialization...');
    debugPrint(
      '📁 [ConfigService] Current working directory: ${Directory.current.path}',
    );
    debugPrint('📁 [ConfigService] Looking for .env file...');

    try {
      // Try to load from .env file - use multiple possible paths
      bool loaded = false;

      // Try current directory first
      try {
        debugPrint(
          '📍 [ConfigService] Attempt 1: Loading from current directory',
        );
        await dotenv.dotenv.load(fileName: _envFileName);
        loaded = true;
        debugPrint(
          '✅ [ConfigService] Environment variables loaded from .env file',
        );
      } catch (e) {
        debugPrint(
          '⚠️ [ConfigService] Could not load .env from current directory: $e',
        );
      }

      // If not loaded, try with full path
      if (!loaded) {
        try {
          final currentDir = Directory.current.path;
          final envPath = '$currentDir/$_envFileName';
          debugPrint(
            '📍 [ConfigService] Attempt 2: Loading from full path: $envPath',
          );

          if (await File(envPath).exists()) {
            await dotenv.dotenv.load(fileName: envPath);
            loaded = true;
            debugPrint(
              '✅ [ConfigService] Environment variables loaded from full path',
            );
          } else {
            debugPrint('❌ [ConfigService] .env file not found at: $envPath');
          }
        } catch (e) {
          debugPrint(
            '⚠️ [ConfigService] Could not load .env from full path: $e',
          );
        }
      }

      // If still not loaded, try from assets
      if (!loaded) {
        try {
          debugPrint('📍 [ConfigService] Attempt 3: Loading from assets');
          await dotenv.dotenv.load(fileName: 'assets/.env');
          loaded = true;
          debugPrint(
            '✅ [ConfigService] Environment variables loaded from assets',
          );
        } catch (e) {
          debugPrint('⚠️ [ConfigService] Could not load .env from assets: $e');
        }
      }

      if (loaded) {
        _isInitialized = true;
        debugPrint(
          '🎉 [ConfigService] Successfully loaded environment variables!',
        );
        // Validate required environment variables
        _validateRequiredEnvVars();
      } else {
        throw Exception('Could not load .env file from any location');
      }
    } catch (e) {
      debugPrint('⚠️ [ConfigService] Could not load .env file: $e');
      debugPrint('📝 [ConfigService] Using fallback configuration');

      // Set up fallback configuration
      _setupFallbackConfig();
      _isInitialized = true;
    }
  }

  /// Set up fallback configuration for development
  void _setupFallbackConfig() {
    // Don't set a fallback API key as it won't work
    _fallbackConfig['OPENWEATHERMAP_API_KEY'] = '';
    _fallbackConfig['APP_NAME'] = 'Krishi Sahayak';
    _fallbackConfig['APP_VERSION'] = '1.0.0';
    _fallbackConfig['ENVIRONMENT'] = 'development';

    debugPrint(
      '⚠️ [ConfigService] No .env file found or invalid configuration',
    );
    debugPrint(
      '📝 [ConfigService] Please create a .env file with your real API keys',
    );
    debugPrint(envFileInstructions);
  }

  /// Validate that all required environment variables are present
  void _validateRequiredEnvVars() {
    final requiredVars = ['OPENWEATHERMAP_API_KEY'];

    final missingVars = <String>[];
    for (final varName in requiredVars) {
      try {
        final value = dotenv.dotenv.env[varName];
        if (value == null || value.isEmpty) {
          missingVars.add(varName);
        }
      } catch (e) {
        missingVars.add(varName);
      }
    }

    if (missingVars.isNotEmpty) {
      debugPrint(
        '❌ [ConfigService] Missing required environment variables: ${missingVars.join(', ')}',
      );
      debugPrint('📝 [ConfigService] Please check your .env file');
    } else {
      debugPrint(
        '✅ [ConfigService] All required environment variables are present',
      );
    }
  }

  /// Get a configuration value with a default fallback
  String getConfig(String key, {String defaultValue = ''}) {
    try {
      return dotenv.dotenv.env[key] ?? defaultValue;
    } catch (e) {
      return _fallbackConfig[key] ?? defaultValue;
    }
  }

  /// Check if a configuration value exists
  bool hasConfig(String key) {
    try {
      final value = dotenv.dotenv.env[key];
      return value != null && value.isNotEmpty;
    } catch (e) {
      final value = _fallbackConfig[key];
      return value != null && value.isNotEmpty;
    }
  }

  /// Reload configuration (useful for testing or dynamic updates)
  Future<void> reload() async {
    _isInitialized = false;
    await initialize();
  }

  /// Get instructions for creating .env file
  String get envFileInstructions {
    final currentDir = Directory.current.path;
    return '''
📁 Create a .env file in: $currentDir

🔑 Add your API key:
OPENWEATHERMAP_API_KEY=bf5945787401f51daf7ce7f1fe7a2779

📝 Example .env file content:
# Weather API Configuration
OPENWEATHERMAP_API_KEY=bf5945787401f51daf7ce7f1fe7a2779

# App Configuration (optional)
APP_NAME=Krishi Sahayak
APP_VERSION=1.0.0
ENVIRONMENT=development
''';
  }

  /// Check if .env file exists
  Future<bool> get hasEnvFile async {
    try {
      final envFile = File('${Directory.current.path}/.env');
      return await envFile.exists();
    } catch (e) {
      return false;
    }
  }
}
