import 'package:supabase_flutter/supabase_flutter.dart';

/// Base class for database migrations
///
/// Each migration should extend this class and implement the [up] method.
/// Migrations run in order based on their version number.
abstract class Migration {
  /// Unique version identifier (e.g., "001_create_initial_schema")
  /// Format: NNN_description_in_snake_case
  String get version;

  /// Description of what this migration does
  String get description;

  /// Execute the migration
  ///
  /// This method should contain the SQL or logic to apply the migration.
  /// Throw an exception if the migration fails.
  Future<void> up(SupabaseClient client);

  /// Rollback the migration (optional)
  ///
  /// This method should undo the changes made by [up].
  /// Not all migrations can be rolled back.
  Future<void> down(SupabaseClient client) async {
    // Default: no rollback
    throw UnimplementedError('Rollback not implemented for $version');
  }

  @override
  String toString() => '$version: $description';
}

/// Result of a migration operation
class MigrationResult {
  final String version;
  final bool success;
  final String? error;
  final DateTime appliedAt;

  MigrationResult({
    required this.version,
    required this.success,
    this.error,
    required this.appliedAt,
  });

  @override
  String toString() {
    if (success) {
      return '✓ $version (applied at $appliedAt)';
    } else {
      return '✗ $version failed: $error';
    }
  }
}
