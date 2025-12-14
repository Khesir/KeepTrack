import 'package:supabase_flutter/supabase_flutter.dart';
import 'migration.dart';
import 'migrations/001_create_initial_schema.dart';

/// Manages database migrations
///
/// This class handles:
/// - Creating the migrations tracking table
/// - Checking which migrations have been applied
/// - Running pending migrations in order
/// - Recording successful migrations
class MigrationManager {
  final SupabaseClient client;

  MigrationManager(this.client);

  /// Run all pending migrations
  ///
  /// This method:
  /// 1. Ensures the migrations table exists
  /// 2. Gets list of applied migrations
  /// 3. Runs any pending migrations in order
  ///
  /// Throws an exception if any migration fails.
  Future<List<MigrationResult>> runMigrations() async {
    final results = <MigrationResult>[];

    try {
      print('🔄 Starting migration check...');

      // Ensure migrations table exists
      await _ensureMigrationsTable();

      // Get applied migrations
      final applied = await _getAppliedMigrations();
      print('📋 Found ${applied.length} previously applied migrations');

      // Run pending migrations
      final pending = _allMigrations
          .where((m) => !applied.contains(m.version))
          .toList();

      if (pending.isEmpty) {
        print('✅ All migrations are up to date');
        return results;
      }

      print('🚀 Running ${pending.length} pending migration(s)...');

      for (var migration in pending) {
        final result = await _runMigration(migration);
        results.add(result);

        if (!result.success) {
          throw Exception('Migration ${migration.version} failed: ${result.error}');
        }
      }

      print('✅ All migrations completed successfully');
      return results;
    } catch (e) {
      print('❌ Migration failed: $e');
      rethrow;
    }
  }

  /// Ensure the schema_migrations table exists
  Future<void> _ensureMigrationsTable() async {
    try {
      // Try to query the table
      await client.from('schema_migrations').select('version').limit(1);
    } catch (e) {
      // Table doesn't exist, create it
      print('📦 Creating schema_migrations table...');

      await client.rpc('exec_sql', params: {
        'sql': '''
          CREATE TABLE IF NOT EXISTS schema_migrations (
            version TEXT PRIMARY KEY,
            applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            description TEXT
          );
        '''
      }).catchError((_) async {
        // If RPC doesn't exist, we need to use SQL Editor manually
        // For now, we'll check if the error is about the table not existing
        print('⚠️  Cannot auto-create migrations table.');
        print('   Please run this SQL in your Supabase SQL Editor:');
        print('');
        print('   CREATE TABLE IF NOT EXISTS schema_migrations (');
        print('     version TEXT PRIMARY KEY,');
        print('     applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),');
        print('     description TEXT');
        print('   );');
        print('');
        throw Exception('schema_migrations table does not exist. Please create it manually.');
      });
    }
  }

  /// Get list of already applied migration versions
  Future<Set<String>> _getAppliedMigrations() async {
    try {
      final response = await client
          .from('schema_migrations')
          .select('version')
          .order('version');

      return (response as List)
          .map((row) => row['version'] as String)
          .toSet();
    } catch (e) {
      print('⚠️  Could not fetch applied migrations: $e');
      return {};
    }
  }

  /// Run a single migration
  Future<MigrationResult> _runMigration(Migration migration) async {
    final startTime = DateTime.now();

    try {
      print('  ⏳ Running: ${migration.version} - ${migration.description}');

      // Execute the migration
      await migration.up(client);

      // Record the migration
      await client.from('schema_migrations').insert({
        'version': migration.version,
        'description': migration.description,
        'applied_at': startTime.toIso8601String(),
      });

      final result = MigrationResult(
        version: migration.version,
        success: true,
        appliedAt: startTime,
      );

      print('  ✅ Completed: ${migration.version}');
      return result;
    } catch (e) {
      print('  ❌ Failed: ${migration.version} - $e');

      return MigrationResult(
        version: migration.version,
        success: false,
        error: e.toString(),
        appliedAt: startTime,
      );
    }
  }

  /// List of all migrations in order
  ///
  /// ⚠️ IMPORTANT: Add new migrations to the end of this list
  /// Never reorder or remove migrations that have been applied
  List<Migration> get _allMigrations => [
        Migration001CreateInitialSchema(),
        // Add new migrations here:
        // Migration002AddEstimatedHours(),
        // Migration003CreateIndexes(),
      ];

  /// Get migration status (for debugging)
  Future<Map<String, dynamic>> getStatus() async {
    final applied = await _getAppliedMigrations();
    final total = _allMigrations.length;
    final pending = _allMigrations
        .where((m) => !applied.contains(m.version))
        .toList();

    return {
      'total': total,
      'applied': applied.length,
      'pending': pending.length,
      'pending_migrations': pending.map((m) => m.version).toList(),
    };
  }
}
