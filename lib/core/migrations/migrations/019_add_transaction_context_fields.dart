import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 019 - Add context fields to transactions table for linking to debts, goals, planned payments, and refunds
class Migration019AddTransactionContextFields extends Migration {
  @override
  String get version => '019_add_transaction_context_fields';

  @override
  String get description =>
      'Add optional foreign key fields (debt_id, goal_id, planned_payment_id, refunded_transaction_id) to transactions table';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Add context metadata columns to transactions table
-- These optional foreign keys link transactions to related entities

-- Add debt_id for debt payment tracking
ALTER TABLE transactions
  ADD COLUMN debt_id UUID REFERENCES debts(id) ON DELETE SET NULL;

-- Add goal_id for goal contribution tracking
ALTER TABLE transactions
  ADD COLUMN goal_id UUID REFERENCES goals(id) ON DELETE SET NULL;

-- Add planned_payment_id for planned payment fulfillment tracking
ALTER TABLE transactions
  ADD COLUMN planned_payment_id UUID REFERENCES planned_payments(id) ON DELETE SET NULL;

-- Add refunded_transaction_id for refund tracking
ALTER TABLE transactions
  ADD COLUMN refunded_transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL;

-- Create indexes for better query performance
CREATE INDEX idx_transactions_debt_id ON transactions(debt_id) WHERE debt_id IS NOT NULL;
CREATE INDEX idx_transactions_goal_id ON transactions(goal_id) WHERE goal_id IS NOT NULL;
CREATE INDEX idx_transactions_planned_payment_id ON transactions(planned_payment_id) WHERE planned_payment_id IS NOT NULL;
CREATE INDEX idx_transactions_refunded_transaction_id ON transactions(refunded_transaction_id) WHERE refunded_transaction_id IS NOT NULL;

-- Add comments for documentation
COMMENT ON COLUMN transactions.debt_id IS 'Link to debt if this transaction is a debt payment';
COMMENT ON COLUMN transactions.goal_id IS 'Link to goal if this transaction is a goal contribution';
COMMENT ON COLUMN transactions.planned_payment_id IS 'Link to planned payment if this transaction fulfills one';
COMMENT ON COLUMN transactions.refunded_transaction_id IS 'Link to original transaction if this is a refund';
''';

    AppLogger.info('  📝 Executing migration 019 - add transaction context fields...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Transaction context fields added successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to add transaction context fields', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- Drop indexes
DROP INDEX IF EXISTS idx_transactions_debt_id;
DROP INDEX IF EXISTS idx_transactions_goal_id;
DROP INDEX IF EXISTS idx_transactions_planned_payment_id;
DROP INDEX IF EXISTS idx_transactions_refunded_transaction_id;

-- Remove context columns
ALTER TABLE transactions DROP COLUMN IF EXISTS debt_id;
ALTER TABLE transactions DROP COLUMN IF EXISTS goal_id;
ALTER TABLE transactions DROP COLUMN IF EXISTS planned_payment_id;
ALTER TABLE transactions DROP COLUMN IF EXISTS refunded_transaction_id;
''';

    AppLogger.warning(
      '  ⚠️  Rolling back migration 019 - remove transaction context fields...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Transaction context fields removed successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to rollback transaction context fields', e, stackTrace);
      rethrow;
    }
  }
}
