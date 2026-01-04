import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 032 - Update budget unique constraint to allow separate income and expense budgets per month
class Migration032UpdateBudgetUniqueConstraint extends Migration {
  @override
  String get version => '032_update_budget_unique_constraint';

  @override
  String get description =>
      'Update UNIQUE constraint on budgets to (user_id, month, budget_type) to allow one income and one expense budget per month';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Drop the existing composite unique constraint on (user_id, month)
DO \$\$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'budgets_user_month_unique'
  ) THEN
    ALTER TABLE budgets DROP CONSTRAINT budgets_user_month_unique;
  END IF;
END \$\$;

-- Create a new composite unique constraint on (user_id, month, budget_type)
-- This ensures each user can have one income budget and one expense budget per month
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

    AppLogger.info('  📝 Executing migration 032 - update budget unique constraint...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Budget unique constraint updated successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to update budget unique constraint', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- Drop the composite unique constraint on (user_id, month, budget_type)
ALTER TABLE budgets DROP CONSTRAINT IF EXISTS budgets_user_month_type_unique;

-- Restore the previous composite unique constraint on (user_id, month)
-- Warning: This will fail if there are multiple budgets with the same user_id and month
DO \$\$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'budgets_user_month_unique'
  ) THEN
    ALTER TABLE budgets
    ADD CONSTRAINT budgets_user_month_unique
    UNIQUE (user_id, month);
  END IF;
END \$\$;
''';

    AppLogger.warning(
      '  ⚠️  Rolling back migration 032 - restore previous budget unique constraint...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Budget unique constraint rollback successful');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to rollback budget unique constraint', e, stackTrace);
      rethrow;
    }
  }
}
