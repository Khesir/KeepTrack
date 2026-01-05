import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 034 - Add to_account_id field for transfer transactions
class Migration034AddTransferAccountField extends Migration {
  @override
  String get version => '034_add_transfer_account_field';

  @override
  String get description =>
      'Add to_account_id field to transactions table to support account transfers';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Add to_account_id field for transfer transactions
-- For transfer transactions: account_id is the source, to_account_id is the destination
ALTER TABLE transactions
ADD COLUMN to_account_id UUID REFERENCES accounts(id) ON DELETE CASCADE;

-- Create index for performance
CREATE INDEX idx_transactions_to_account_id ON transactions(to_account_id);

-- Add comment explaining the field
COMMENT ON COLUMN transactions.to_account_id IS
  'Destination account for transfer transactions. NULL for income/expense transactions.
   For transfers: account_id = source account, to_account_id = destination account.';
''';

    AppLogger.info('  📝 Executing migration 034 - add to_account_id field...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ to_account_id field added successfully');
      AppLogger.info('     - Transfer transactions now support source and destination accounts');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to add to_account_id field', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- Remove to_account_id field
DROP INDEX IF EXISTS idx_transactions_to_account_id;
ALTER TABLE transactions DROP COLUMN IF EXISTS to_account_id;
''';

    AppLogger.warning(
      '  ⚠️  Rolling back migration 034 - remove to_account_id field...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ to_account_id field removed successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to rollback to_account_id field', e, stackTrace);
      rethrow;
    }
  }
}
