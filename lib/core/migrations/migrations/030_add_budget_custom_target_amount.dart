import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 030 - Add custom_target_amount to budgets
///
/// Adds support for:
/// - Custom budget target amount that overrides the sum of category targets
/// - Allows users to set a different overall budget limit than the sum of categories
class Migration030AddBudgetCustomTargetAmount extends Migration {
  @override
  String get version => '030_add_budget_custom_target_amount';

  @override
  String get description =>
      'Add custom_target_amount column to budgets table to allow custom budget targets';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Add custom_target_amount column for custom budget targets
DO \$\$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'budgets' AND column_name = 'custom_target_amount'
  ) THEN
    ALTER TABLE budgets ADD COLUMN custom_target_amount DECIMAL(15, 2);
    COMMENT ON COLUMN budgets.custom_target_amount IS 'Optional custom budget target amount (overrides calculated sum from categories)';
  END IF;
END \$\$;

-- Add check constraint to ensure custom_target_amount is non-negative if set
DO \$\$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'budgets_custom_target_amount_check'
  ) THEN
    ALTER TABLE budgets
    ADD CONSTRAINT budgets_custom_target_amount_check
    CHECK (custom_target_amount IS NULL OR custom_target_amount >= 0);
  END IF;
END \$\$;
''';

    AppLogger.info(
      '  📝 Executing migration 030 - add custom_target_amount...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Custom target amount column added successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        '  ❌ Failed to add custom_target_amount column',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- WARNING: This will delete custom_target_amount data!
-- Make sure to backup your data before running this rollback.

-- Remove check constraint
ALTER TABLE budgets DROP CONSTRAINT IF EXISTS budgets_custom_target_amount_check;

-- Remove column
ALTER TABLE budgets DROP COLUMN IF EXISTS custom_target_amount;
''';

    AppLogger.warning(
      '  ⚠️  Rolling back migration 030 - remove custom_target_amount...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Custom target amount column removed successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        '  ❌ Failed to rollback custom_target_amount column',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}
