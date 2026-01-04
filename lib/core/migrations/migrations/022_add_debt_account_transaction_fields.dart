import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 022 - Add account_id and transaction_id to debts table
class Migration022AddDebtAccountTransactionFields extends Migration {
  @override
  String get version => '022_add_debt_account_transaction_fields';

  @override
  String get description =>
      'Add account_id and transaction_id columns to debts table for automatic transaction creation';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Add account_id column to debts table
ALTER TABLE debts
  ADD COLUMN IF NOT EXISTS account_id UUID REFERENCES accounts(id) ON DELETE SET NULL;

-- Add transaction_id column to debts table
ALTER TABLE debts
  ADD COLUMN IF NOT EXISTS transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL;

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_debts_account_id ON debts(account_id);
CREATE INDEX IF NOT EXISTS idx_debts_transaction_id ON debts(transaction_id);

-- Add comments to document the column purposes
COMMENT ON COLUMN debts.account_id IS 'Reference to the account/wallet this debt is associated with';
COMMENT ON COLUMN debts.transaction_id IS 'Reference to the initial transaction created when the debt was recorded';
''';

    AppLogger.info(
      '  📝 Executing migration 022 - add account_id and transaction_id to debts...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Debt columns added successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to add debt columns', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- Drop indexes
DROP INDEX IF EXISTS idx_debts_account_id;
DROP INDEX IF EXISTS idx_debts_transaction_id;

-- Drop columns
ALTER TABLE debts
  DROP COLUMN IF EXISTS account_id,
  DROP COLUMN IF EXISTS transaction_id;
''';

    AppLogger.warning(
      '  ⚠️  Rolling back migration 022 - remove debt columns...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Debt columns removed successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to rollback debt columns', e, stackTrace);
      rethrow;
    }
  }
}
