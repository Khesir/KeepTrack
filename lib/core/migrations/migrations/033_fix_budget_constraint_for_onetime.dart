import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 033 - Fix budget unique constraint to allow one-time budgets
class Migration033FixBudgetConstraintForOnetime extends Migration {
  @override
  String get version => '033_fix_budget_constraint_for_onetime';

  @override
  String get description =>
      'Update budget constraint to allow multiple one-time budgets per month while keeping monthly budgets unique';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Drop the existing composite unique constraint
DO \$\$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'budgets_user_month_type_unique'
  ) THEN
    ALTER TABLE budgets DROP CONSTRAINT budgets_user_month_type_unique;
  END IF;
END \$\$;

-- Create a partial unique index for monthly budgets only
-- This allows only one monthly budget per (user_id, month, budget_type)
-- but allows unlimited one-time budgets
DROP INDEX IF EXISTS budgets_monthly_unique_idx;

CREATE UNIQUE INDEX budgets_monthly_unique_idx
ON budgets (user_id, month, budget_type)
WHERE period_type = 'monthly';

-- Create a regular index for one-time budgets to improve query performance
DROP INDEX IF EXISTS budgets_onetime_idx;

CREATE INDEX budgets_onetime_idx
ON budgets (user_id, month, budget_type, period_type)
WHERE period_type = 'one_time';
''';

    AppLogger.info('  📝 Executing migration 033 - fix budget constraint for one-time budgets...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Budget constraint updated successfully');
      AppLogger.info('     - Monthly budgets: 1 per user/month/type');
      AppLogger.info('     - One-time budgets: unlimited per user/month/type');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to update budget constraint', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- Drop the partial unique indexes
DROP INDEX IF EXISTS budgets_monthly_unique_idx;
DROP INDEX IF EXISTS budgets_onetime_idx;

-- Restore the previous composite unique constraint on (user_id, month, budget_type)
-- Warning: This will fail if there are one-time budgets
DO \$\$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'budgets_user_month_type_unique'
  ) THEN
    ALTER TABLE budgets
    ADD CONSTRAINT budgets_user_month_type_unique
    UNIQUE (user_id, month, budget_type);
  END IF;
END \$\$;
''';

    AppLogger.warning(
      '  ⚠️  Rolling back migration 033 - restore previous budget constraint...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Budget constraint rollback successful');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to rollback budget constraint', e, stackTrace);
      rethrow;
    }
  }
}
