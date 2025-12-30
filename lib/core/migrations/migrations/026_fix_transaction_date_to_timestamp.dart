import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:persona_codex/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 026 - Fix transaction date column to store time
///
/// Changes the 'date' column from DATE to TIMESTAMP WITH TIME ZONE
/// to preserve the time component of transactions.
///
/// Previously: Transactions saved at 12:00 AM only (date without time)
/// After: Transactions save with full date and time
class Migration026FixTransactionDateToTimestamp extends Migration {
  @override
  String get version => '026_fix_transaction_date_to_timestamp';

  @override
  String get description =>
      'Change transaction date column from DATE to TIMESTAMP WITH TIME ZONE to preserve time';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Change the date column from DATE to TIMESTAMP WITH TIME ZONE
-- This allows transactions to store the time component, not just the date

ALTER TABLE transactions
  ALTER COLUMN date TYPE TIMESTAMP WITH TIME ZONE USING date::TIMESTAMP WITH TIME ZONE;

-- Add comment
COMMENT ON COLUMN transactions.date IS 'Transaction date and time (with timezone)';

-- Recreate index on date column (PostgreSQL drops it during ALTER)
DROP INDEX IF EXISTS idx_transactions_date;
CREATE INDEX idx_transactions_date ON transactions(date);
''';

    AppLogger.info('  📝 Executing migration 026 - fix transaction date to timestamp...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Transaction date column updated to TIMESTAMP WITH TIME ZONE');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to update transaction date column', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- Revert back to DATE (loses time component)
ALTER TABLE transactions
  ALTER COLUMN date TYPE DATE USING date::DATE;

-- Recreate index
DROP INDEX IF EXISTS idx_transactions_date;
CREATE INDEX idx_transactions_date ON transactions(date);
''';

    AppLogger.warning(
      '  ⚠️  Rolling back migration 026 - revert transaction date to DATE...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Transaction date column reverted to DATE');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to rollback transaction date column', e, stackTrace);
      rethrow;
    }
  }
}
