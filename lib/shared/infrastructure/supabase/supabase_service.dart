import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/di/disposable.dart';

/// Supabase service - Manages Supabase connection
class SupabaseService implements Disposable {
  final SupabaseClient _client;

  /// Create from existing Supabase client (recommended)
  ///
  /// Use this when Supabase is already initialized globally in main.dart
  SupabaseService.fromClient(this._client);

  /// Get the Supabase client
  ///
  SupabaseClient get client => _client;

  /// Convenience getter for the currently logged-in user's ID
  String? get userId => _client.auth.currentUser?.id;

  @override
  Future<void> dispose() async {
    // Supabase client is managed globally, no disposal needed
    print('Supabase service disposed');
  }
}
