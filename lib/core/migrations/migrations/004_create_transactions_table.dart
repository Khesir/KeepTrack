import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 004 - Create transactions table
class Migration004CreateTransactionsTable extends Migration {
  @override
  String get version => '004_create_transactions_table';

  @override
  String get description =>
      'Create transactions table for independent financial transactions';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Create transactions table
CREATE TABLE IF NOT EXISTS transactions (
  id TEXT PRIMARY KEY DEFAULT uuid_generate_v4(),
  account_id TEXT REFERENCES accounts(id) ON DELETE SET NULL,
  category_id TEXT,
  budget_id TEXT,
  amount NUMERIC NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('income', 'expense', 'transfer')),
  description TEXT,
  date TIMESTAMP WITH TIME ZONE NOT NULL,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_transactions_account_id ON transactions(account_id);
CREATE INDEX IF NOT EXISTS idx_transactions_budget_id ON transactions(budget_id);
CREATE INDEX IF NOT EXISTS idx_transactions_category_id ON transactions(category_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type);

-- Composite index for date range queries
CREATE INDEX IF NOT EXISTS idx_transactions_date_type ON transactions(date DESC, type);
''';

    AppLogger.info(
      '  📝 Executing migration 004 - create transactions table...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Transactions table created successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        '  ❌ Failed to create transactions table',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- Drop transactions table
DROP TABLE IF EXISTS transactions CASCADE;

-- Remove indexes (CASCADE handles these, but being explicit)
DROP INDEX IF EXISTS idx_transactions_account_id;
DROP INDEX IF EXISTS idx_transactions_budget_id;
DROP INDEX IF EXISTS idx_transactions_category_id;
DROP INDEX IF EXISTS idx_transactions_date;
DROP INDEX IF EXISTS idx_transactions_type;
DROP INDEX IF EXISTS idx_transactions_date_type;
''';

    AppLogger.warning(
      '  ⚠️  Rolling back migration 004 - drop transactions table...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Transactions table dropped successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        '  ❌ Failed to rollback transactions table',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}
