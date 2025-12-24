import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:persona_codex/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 018 - Add type column to transactions table
class Migration018AddTransactionType extends Migration {
  @override
  String get version => '018_add_transaction_type';

  @override
  String get description =>
      'Add type column (income/expense/transfer) to transactions table';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Create enum type for transaction types
CREATE TYPE transaction_type AS ENUM ('income', 'expense', 'transfer');

-- Add type column to transactions table
-- Set default to 'expense' for existing rows
ALTER TABLE transactions
  ADD COLUMN type transaction_type NOT NULL DEFAULT 'expense';

-- Create index for transaction type queries
CREATE INDEX idx_transactions_type ON transactions(type);
''';

    AppLogger.info('  📝 Executing migration 018 - add transaction type...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Transaction type column added successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to add transaction type', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- Drop index
DROP INDEX IF EXISTS idx_transactions_type;

-- Remove type column
ALTER TABLE transactions DROP COLUMN IF EXISTS type;

-- Drop enum type
DROP TYPE IF EXISTS transaction_type;
''';

    AppLogger.warning(
      '  ⚠️  Rolling back migration 018 - remove transaction type...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Transaction type removed successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to rollback transaction type', e, stackTrace);
      rethrow;
    }
  }
}
