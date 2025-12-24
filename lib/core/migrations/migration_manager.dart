import 'package:persona_codex/core/migrations/migrations/003_create_accounts_table.dart';
import 'package:persona_codex/core/migrations/migrations/012_create_budget_categories_table.dart';
import 'package:persona_codex/core/migrations/migrations/016_update_accounts_to_uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:persona_codex/core/logging/app_logger.dart';
import 'migration.dart';
import 'migrations/001_create_initial_schema.dart';
import 'migrations/002_add_archive_task.dart';
import 'migrations/004_create_transactions_table.dart';
import 'migrations/005_add_user_id_and_auth.dart';
import 'migrations/006_update_accounts_add_fields.dart';
import 'migrations/007_create_goals_table.dart';
import 'migrations/008_create_debts_table.dart';
import 'migrations/009_create_planned_payments_table.dart';
import 'migrations/010_add_task_financial_fields.dart';
import 'migrations/011_create_finance_categories_table.dart';
import 'migrations/013_update_budget_schema.dart';
import 'migrations/014_remove_budget_month_unique.dart';
import 'migrations/015_add_budget_spent_calculation.dart';
import 'migrations/017_update_transactions_structure.dart';
import 'migrations/018_add_transaction_type.dart';

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
      AppLogger.info('🔄 Starting migration check...');

      // Ensure migrations table exists
      await _ensureMigrationsTable();

      // Get applied migrations
      final applied = await _getAppliedMigrations();
      AppLogger.info(
        '📋 Found ${applied.length} previously applied migrations',
      );

      // Run pending migrations
      final pending = _allMigrations
          .where((m) => !applied.contains(m.version))
          .toList();

      if (pending.isEmpty) {
        AppLogger.info('✅ All migrations are up to date');
        return results;
      }

      AppLogger.info('🚀 Running ${pending.length} pending migration(s)...');

      for (var migration in pending) {
        final result = await _runMigration(migration);
        results.add(result);

        if (!result.success) {
          throw Exception(
            'Migration ${migration.version} failed: ${result.error}',
          );
        }
      }

      AppLogger.info('✅ All migrations completed successfully');
      return results;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Migration failed', e, stackTrace);
      rethrow;
    }
  }

  /// Ensure the schema_migrations table exists
  Future<void> _ensureMigrationsTable() async {
    try {
      // Try to query the table
      await client.from('schema_migrations').select('version').limit(1);
      AppLogger.info('✅ schema_migrations table exists');
    } catch (e) {
      // Check if this is a network error first
      if (_isNetworkError(e)) {
        AppLogger.error('Network error while checking migrations table', e);
        rethrow; // Let the main retry logic handle network errors
      }

      // Table doesn't exist, try to create it
      AppLogger.info('📦 Creating schema_migrations table...');

      try {
        await client.rpc(
          'exec_sql',
          params: {
            'sql': '''
            CREATE TABLE IF NOT EXISTS schema_migrations (
              version TEXT PRIMARY KEY,
              applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
              description TEXT
            );

            ALTER TABLE schema_migrations ENABLE ROW LEVEL SECURITY;

            DROP POLICY IF EXISTS "Allow all operations on schema_migrations" ON schema_migrations;

            CREATE POLICY "Allow all operations on schema_migrations"
            ON schema_migrations
            FOR ALL
            USING (true)
            WITH CHECK (true);
          ''',
          },
        );
        AppLogger.info('✅ schema_migrations table created successfully');
      } catch (rpcError) {
        // Check if RPC error is also a network error
        if (_isNetworkError(rpcError)) {
          AppLogger.error(
            'Network error while creating migrations table',
            rpcError,
          );
          rethrow;
        }

        // RPC function doesn't exist - provide bootstrap instructions
        AppLogger.error(
          '❌ ERROR: exec_sql function not found in Supabase',
          rpcError,
        );
        AppLogger.info('═' * 70);
        AppLogger.info('SETUP REQUIRED');
        AppLogger.info('═' * 70);
        AppLogger.info(
          'To enable automatic migrations, you need to run the bootstrap',
        );
        AppLogger.info('script in your Supabase SQL Editor:');
        AppLogger.info('');
        AppLogger.info('1. Open your Supabase project dashboard');
        AppLogger.info('2. Go to SQL Editor → New Query');
        AppLogger.info('3. Copy and paste the contents of:');
        AppLogger.info('   supabase/bootstrap.sql');

        throw Exception(
          'Supabase not bootstrapped. Please run supabase/bootstrap.sql first.',
        );
      }
    }
  }

  /// Check if error is network-related
  bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('unreachable');
  }

  /// Get list of already applied migration versions
  Future<Set<String>> _getAppliedMigrations() async {
    try {
      final response = await client
          .from('schema_migrations')
          .select('version')
          .order('version');

      return (response as List).map((row) => row['version'] as String).toSet();
    } catch (e) {
      AppLogger.warning('⚠️  Could not fetch applied migrations', e);
      return {};
    }
  }

  /// Run a single migration
  Future<MigrationResult> _runMigration(Migration migration) async {
    final startTime = DateTime.now();

    try {
      AppLogger.info(
        '  ⏳ Running: ${migration.version} - ${migration.description}',
      );

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

      AppLogger.info('  ✅ Completed: ${migration.version}');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed: ${migration.version}', e, stackTrace);

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
    Migration002AddArchivedTask(),
    Migration003CreateAccountsTable(),
    Migration004CreateTransactionsTable(),
    Migration005AddUserIdAndAuth(),
    Migration006UpdateAccountsAddFields(),
    Migration007CreateGoalsTable(),
    Migration008CreateDebtsTable(),
    Migration009CreatePlannedPaymentsTable(),
    Migration010AddTaskFinancialFields(),
    Migration011CreateFinanceCategoriesTable(),
    Migration012CreateBudgetCategoriesTable(),
    Migration013UpdateBudgetsTable(),
    Migration014RemoveBudgetMonthUnique(),
    Migration015AddBudgetSpentCalculation(),
    Migration016UpdateAccountsToUUID(),
    Migration017UpdateTransactionsStructure(),
    Migration018AddTransactionType(),
    // Add new migrations here:
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
