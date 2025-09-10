// ignore: unnecessary_import
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Initialize database factory for different platforms
    if (Platform.isWindows || Platform.isLinux) {
      // Initialize FFI for desktop platforms
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path = join(await getDatabasesPath(), 'krishi_sahayak.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Crops table with versioning
    await db.execute('''
      CREATE TABLE crops(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        variety TEXT,
        planting_date TEXT,
        harvest_date TEXT,
        notes TEXT,
        status TEXT DEFAULT 'active',
        version INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        last_modified_by TEXT,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // Weather data table
    await db.execute('''
      CREATE TABLE weather_data(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        temperature REAL,
        humidity REAL,
        rainfall REAL,
        wind_speed REAL,
        description TEXT,
        latitude REAL,
        longitude REAL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // User profiles table
    await db.execute('''
      CREATE TABLE user_profiles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        location TEXT,
        farm_size REAL,
        experience_years INTEGER,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // App settings table
    await db.execute('''
      CREATE TABLE app_settings(
        key TEXT PRIMARY KEY,
        value TEXT,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add latitude and longitude columns to weather_data table
      await db.execute('ALTER TABLE weather_data ADD COLUMN latitude REAL');
      await db.execute('ALTER TABLE weather_data ADD COLUMN longitude REAL');
    }
  }

  // Crop operations
  Future<int> insertCrop(Map<String, dynamic> crop) async {
    final db = await database;
    return await db.insert('crops', crop);
  }

  Future<List<Map<String, dynamic>>> getAllCrops() async {
    final db = await database;
    return await db.query('crops', orderBy: 'created_at DESC');
  }

  Future<int> updateCrop(Map<String, dynamic> crop) async {
    final db = await database;
    return await db.update(
      'crops',
      crop,
      where: 'id = ?',
      whereArgs: [crop['id']],
    );
  }

  Future<int> deleteCrop(String id) async {
    final db = await database;
    return await db.delete('crops', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> softDeleteCrop(String id) async {
    final db = await database;
    return await db.update(
      'crops',
      {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getCropsForSync() async {
    final db = await database;
    return await db.query(
      'crops',
      where: 'is_deleted = 0',
      orderBy: 'updated_at DESC',
    );
  }

  // Weather operations
  Future<int> insertWeatherData(Map<String, dynamic> weather) async {
    final db = await database;
    return await db.insert('weather_data', weather);
  }

  Future<List<Map<String, dynamic>>> getWeatherData({int limit = 7}) async {
    final db = await database;
    return await db.query('weather_data', orderBy: 'date DESC', limit: limit);
  }

  Future<Map<String, dynamic>?> getLatestWeather() async {
    final db = await database;
    final results = await db.query(
      'weather_data',
      orderBy: 'date DESC',
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  // User profile operations
  Future<int> insertUserProfile(Map<String, dynamic> profile) async {
    final db = await database;
    return await db.insert('user_profiles', profile);
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final db = await database;
    final results = await db.query('user_profiles', limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateUserProfile(Map<String, dynamic> profile) async {
    final db = await database;
    return await db.update(
      'user_profiles',
      profile,
      where: 'id = ?',
      whereArgs: [profile['id']],
    );
  }

  // App settings operations
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('app_settings', {
      'key': key,
      'value': value,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final results = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    return results.isNotEmpty ? results.first['value'] as String? : null;
  }

  // Database utilities
  Future<void> closeDatabase() async {
    final db = await database;
    await db.close();
  }

  Future<void> deleteDatabase() async {
    final dbPath = join(await getDatabasesPath(), 'krishi_sahayak.db');
    await databaseFactory.deleteDatabase(dbPath);
  }
}
