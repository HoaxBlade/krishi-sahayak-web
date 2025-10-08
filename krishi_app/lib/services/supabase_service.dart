import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config_service.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final ConfigService _configService = ConfigService();

  SupabaseClient get client {
    if (!_isInitialized) {
      throw Exception(
        'SupabaseService not initialized. Call initialize() first.',
      );
    }
    return Supabase.instance.client;
  }

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initialize Supabase
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🚀 [SupabaseService] Initializing Supabase...');

      // Initialize config service first
      await _configService.initialize();

      // Get Supabase credentials from environment
      final supabaseUrl = _configService.supabaseUrl;
      final supabaseAnonKey = _configService.supabaseAnonKey;

      if (supabaseUrl == null || supabaseAnonKey == null) {
        debugPrint(
          '⚠️ [SupabaseService] Supabase credentials not found in .env',
        );
        debugPrint(
          '📝 [SupabaseService] Add SUPABASE_URL and SUPABASE_ANON_KEY to .env file',
        );
        throw Exception('Supabase credentials not configured');
      }

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: kDebugMode,
      );

      _isInitialized = true;
      debugPrint('✅ [SupabaseService] Supabase initialized successfully');

      // Test connection with a simple query
      try {
        await client.from('crops').select('id').limit(1);
        debugPrint('✅ [SupabaseService] Database connection verified');
      } catch (e) {
        debugPrint('⚠️ [SupabaseService] Database connection test failed: $e');
        // Don't throw here as tables might not exist yet
      }
    } catch (e) {
      debugPrint('❌ [SupabaseService] Failed to initialize Supabase: $e');
      rethrow;
    }
  }

  /// Authentication Methods

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('📝 [SupabaseService] Signing up user: $email');

      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );

      debugPrint('✅ [SupabaseService] User signed up successfully');
      return response;
    } catch (e) {
      debugPrint('❌ [SupabaseService] Sign up failed: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 [SupabaseService] Signing in user: $email');

      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      debugPrint('✅ [SupabaseService] User signed in successfully');
      return response;
    } catch (e) {
      debugPrint('❌ [SupabaseService] Sign in failed: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      debugPrint('👋 [SupabaseService] Signing out user');
      await client.auth.signOut();
      debugPrint('✅ [SupabaseService] User signed out successfully');
    } catch (e) {
      debugPrint('❌ [SupabaseService] Sign out failed: $e');
      rethrow;
    }
  }

  // Get current user
  User? get currentUser => client.auth.currentUser;

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Database Operations

  // Crops table operations
  Future<List<Map<String, dynamic>>> getCrops({String? userId}) async {
    try {
      final query = client.from('crops').select();

      if (userId != null) {
        query.eq('user_id', userId);
      }

      final response = await query.order('created_at', ascending: false);
      debugPrint('✅ [SupabaseService] Retrieved ${response.length} crops');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ [SupabaseService] Error getting crops: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> insertCrop(Map<String, dynamic> cropData) async {
    try {
      // Add user_id if authenticated
      if (isAuthenticated) {
        cropData['user_id'] = currentUser!.id;
      }

      final response = await client
          .from('crops')
          .insert(cropData)
          .select()
          .single();

      debugPrint('✅ [SupabaseService] Crop inserted successfully');
      return response;
    } catch (e) {
      debugPrint('❌ [SupabaseService] Error inserting crop: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateCrop(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await client
          .from('crops')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      debugPrint('✅ [SupabaseService] Crop updated successfully');
      return response;
    } catch (e) {
      debugPrint('❌ [SupabaseService] Error updating crop: $e');
      rethrow;
    }
  }

  Future<void> deleteCrop(String id) async {
    try {
      await client.from('crops').delete().eq('id', id);
      debugPrint('✅ [SupabaseService] Crop deleted successfully');
    } catch (e) {
      debugPrint('❌ [SupabaseService] Error deleting crop: $e');
      rethrow;
    }
  }

  /// Storage Operations

  // Upload crop image
  Future<String> uploadCropImage(String fileName, List<int> fileBytes) async {
    try {
      debugPrint('📤 [SupabaseService] Uploading crop image: $fileName');

      final path = 'crop_images/${currentUser?.id ?? 'anonymous'}/$fileName';

      await client.storage
          .from('crop-images')
          .uploadBinary(path, Uint8List.fromList(fileBytes));

      final publicUrl = client.storage.from('crop-images').getPublicUrl(path);

      debugPrint('✅ [SupabaseService] Image uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ [SupabaseService] Error uploading image: $e');
      rethrow;
    }
  }

  // Delete image
  Future<void> deleteImage(String path) async {
    try {
      await client.storage.from('crop-images').remove([path]);
      debugPrint('✅ [SupabaseService] Image deleted successfully');
    } catch (e) {
      debugPrint('❌ [SupabaseService] Error deleting image: $e');
      rethrow;
    }
  }

  /// Analysis Operations

  // Get all crop analyses
  Future<List<Map<String, dynamic>>> getCropAnalyses({String? userId}) async {
    try {
      final query = client.from('crop_analyses').select();

      if (userId != null) {
        query.eq('user_id', userId);
      }

      final response = await query.order('created_at', ascending: false);
      debugPrint(
        '✅ [SupabaseService] Retrieved ${response.length} crop analyses',
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ [SupabaseService] Error getting crop analyses: $e');
      rethrow;
    }
  }

  // Insert crop analysis
  Future<Map<String, dynamic>> insertCropAnalysis(
    Map<String, dynamic> analysisData,
  ) async {
    try {
      // Add user_id if authenticated
      if (isAuthenticated) {
        analysisData['user_id'] = currentUser!.id;
      }

      final response = await client
          .from('crop_analyses')
          .insert(analysisData)
          .select()
          .single();

      debugPrint('✅ [SupabaseService] Crop analysis inserted successfully');
      return response;
    } catch (e) {
      debugPrint('❌ [SupabaseService] Error inserting crop analysis: $e');
      rethrow;
    }
  }

  // Update crop analysis
  Future<Map<String, dynamic>> updateCropAnalysis(
    String id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await client
          .from('crop_analyses')
          .update(updates)
          .eq('id', id)
          .select()
          .single();

      debugPrint('✅ [SupabaseService] Crop analysis updated successfully');
      return response;
    } catch (e) {
      debugPrint('❌ [SupabaseService] Error updating crop analysis: $e');
      rethrow;
    }
  }

  // Delete crop analysis
  Future<void> deleteCropAnalysis(String id) async {
    try {
      await client.from('crop_analyses').delete().eq('id', id);
      debugPrint('✅ [SupabaseService] Crop analysis deleted successfully');
    } catch (e) {
      debugPrint('❌ [SupabaseService] Error deleting crop analysis: $e');
      rethrow;
    }
  }

  /// Real-time Subscriptions

  // Listen to crop changes
  RealtimeChannel subscribeToCrops({
    String? userId,
    required void Function(List<Map<String, dynamic>>) onData,
    required void Function(String) onError,
  }) {
    debugPrint('👂 [SupabaseService] Setting up real-time crop subscription');

    final channel = client
        .channel('crops_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'crops',
          filter: userId != null
              ? PostgresChangeFilter(
                  type: PostgresChangeFilterType.eq,
                  column: 'user_id',
                  value: userId,
                )
              : null,
          callback: (payload) {
            debugPrint('📡 [SupabaseService] Real-time crop change received');
            // Refresh crops data
            getCrops(
              userId: userId,
            ).then(onData).catchError((error) => onError(error.toString()));
          },
        )
        .subscribe();

    return channel;
  }

  // Unsubscribe from channel
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await client.removeChannel(channel);
    debugPrint('👋 [SupabaseService] Unsubscribed from real-time channel');
  }

  /// Health Check
  Future<bool> checkConnection() async {
    try {
      // Simple query to test connection
      await client.from('crops').select('id').limit(1);
      return true;
    } catch (e) {
      debugPrint('❌ [SupabaseService] Connection check failed: $e');
      return false;
    }
  }

  /// Sync local data to Supabase
  Future<void> syncLocalData(List<Map<String, dynamic>> localCrops) async {
    try {
      debugPrint(
        '🔄 [SupabaseService] Syncing ${localCrops.length} local crops to Supabase',
      );

      for (final cropData in localCrops) {
        // Check if crop exists in Supabase
        final existing = await client
            .from('crops')
            .select('id')
            .eq('id', cropData['id'])
            .maybeSingle();

        if (existing == null) {
          // Insert new crop
          await insertCrop(cropData);
        } else {
          // Update existing crop
          await updateCrop(cropData['id'], cropData);
        }
      }

      debugPrint('✅ [SupabaseService] Local data sync completed');
    } catch (e) {
      debugPrint('❌ [SupabaseService] Error syncing local data: $e');
      rethrow;
    }
  }
}
