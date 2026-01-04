import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 003 - Create accounts table
class Migration003CreateAccountsTable extends Migration {
  @override
  String get version => '003_create_accounts_table';

  @override
  String get description => 'Create accounts table with soft delete support';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Create accounts table
CREATE TABLE IF NOT EXISTS accounts (
  id TEXT PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  balance NUMERIC DEFAULT 0,
  color TEXT,
  bank_account_number TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  is_archived BOOLEAN DEFAULT FALSE
);

-- Index for faster queries on archived accounts
CREATE INDEX IF NOT EXISTS idx_accounts_archived ON accounts(is_archived);
''';

    AppLogger.info('  📝 Executing migration 003 - create accounts table...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Accounts table created successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to create accounts table', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- Drop accounts table
DROP TABLE IF EXISTS accounts CASCADE;

-- Remove index
DROP INDEX IF EXISTS idx_accounts_archived;
''';

    AppLogger.warning(
      '  ⚠️  Rolling back migration 003 - drop accounts table...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Accounts table dropped successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to rollback accounts table', e, stackTrace);
      rethrow;
    }
  }
}
