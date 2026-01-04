import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 024 - Add fee fields to transactions table
///
/// Adds support for transaction fees (taxes, service charges, transfer fees)
///
/// Examples:
/// - Expense: 2000 + 154 tax fee = 2154 total cost (impacts budget)
/// - Transfer: Account1 -2018 (2000 transfer + 18 fee), Account2 +2000
class Migration024AddTransactionFeeFields extends Migration {
  @override
  String get version => '024_add_transaction_fee_fields';

  @override
  String get description =>
      'Add fee and fee_description fields to transactions table for tracking taxes, service charges, and transfer fees';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Add fee fields to transactions table
-- fee: The additional cost/charge (tax, service fee, transfer fee, etc.)
-- fee_description: Description of what the fee is for (e.g., "Tax", "Service Charge", "Transfer Fee")

ALTER TABLE transactions
  ADD COLUMN fee DECIMAL(12, 2) DEFAULT 0 NOT NULL,
  ADD COLUMN fee_description TEXT;

-- Add comments for documentation
COMMENT ON COLUMN transactions.fee IS 'Additional fee/charge amount (tax, service charge, transfer fee, etc.). For budgets, total cost = amount + fee';
COMMENT ON COLUMN transactions.fee_description IS 'Description of the fee (e.g., "Tax", "Service Charge", "Transfer Fee")';

-- Create index for querying transactions with fees
CREATE INDEX idx_transactions_with_fees ON transactions(fee) WHERE fee > 0;
''';

    AppLogger.info('  📝 Executing migration 024 - add transaction fee fields...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Transaction fee fields added successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to add transaction fee fields', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- Drop index
DROP INDEX IF EXISTS idx_transactions_with_fees;

-- Remove fee columns
ALTER TABLE transactions
  DROP COLUMN IF EXISTS fee,
  DROP COLUMN IF EXISTS fee_description;
''';

    AppLogger.warning(
      '  ⚠️  Rolling back migration 024 - remove transaction fee fields...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Transaction fee fields removed successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to rollback transaction fee fields', e, stackTrace);
      rethrow;
    }
  }
}
