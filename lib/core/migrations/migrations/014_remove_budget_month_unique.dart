import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 014 - Remove UNIQUE constraint from budgets.month
class Migration014RemoveBudgetMonthUnique extends Migration {
  @override
  String get version => '003_remove_budget_month_unique';

  @override
  String get description =>
      'Remove UNIQUE constraint from budgets.month to allow multiple users to have budgets for the same month';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Drop the existing UNIQUE constraint on month column
-- This allows multiple users to create budgets for the same month
DO \$\$
BEGIN
  -- Drop the unique constraint if it exists
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'budgets_month_key'
  ) THEN
    ALTER TABLE budgets DROP CONSTRAINT budgets_month_key;
  END IF;
END \$\$;

-- Create a composite unique constraint on (user_id, month) instead
-- This ensures each user can only have one budget per month
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

    AppLogger.info('  📝 Executing migration 003 - remove budget month unique constraint...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Budget month unique constraint removed successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to remove budget month unique constraint', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- Drop the composite unique constraint
ALTER TABLE budgets DROP CONSTRAINT IF EXISTS budgets_user_month_unique;

-- Restore the original UNIQUE constraint on month
-- Warning: This will fail if there are multiple budgets with the same month
ALTER TABLE budgets ADD CONSTRAINT budgets_month_key UNIQUE (month);
''';

    AppLogger.warning(
      '  ⚠️  Rolling back migration 003 - restore budget month unique constraint...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Budget month unique constraint rollback successful');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to rollback budget month unique constraint', e, stackTrace);
      rethrow;
    }
  }
}
