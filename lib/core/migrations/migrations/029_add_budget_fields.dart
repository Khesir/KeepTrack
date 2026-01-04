import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 029 - Add title, budget_type, and period_type to budgets
///
/// Adds support for:
/// - User-defined budget titles
/// - Budget types (income vs expense)
/// - Period types (monthly vs one-time)
/// - Removes unique constraint on (user_id, month) to allow multiple budgets per month
class Migration029AddBudgetFields extends Migration {
  @override
  String get version => '029_add_budget_fields';

  @override
  String get description =>
      'Add title, budget_type, and period_type fields to budgets table and remove month uniqueness constraint';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Add title column for user-defined budget names
DO \$\$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'budgets' AND column_name = 'title'
  ) THEN
    ALTER TABLE budgets ADD COLUMN title TEXT;
    COMMENT ON COLUMN budgets.title IS 'User-defined budget title (optional for monthly, recommended for one-time budgets)';
  END IF;
END \$\$;

-- Add budget_type column to distinguish income vs expense budgets
DO \$\$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'budgets' AND column_name = 'budget_type'
  ) THEN
    ALTER TABLE budgets ADD COLUMN budget_type TEXT NOT NULL DEFAULT 'expense';
    COMMENT ON COLUMN budgets.budget_type IS 'Type of budget: income or expense';
  END IF;
END \$\$;

-- Add period_type column to distinguish monthly vs one-time budgets
DO \$\$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'budgets' AND column_name = 'period_type'
  ) THEN
    ALTER TABLE budgets ADD COLUMN period_type TEXT NOT NULL DEFAULT 'monthly';
    COMMENT ON COLUMN budgets.period_type IS 'Period type: monthly (recurring) or oneTime (one-off event/project)';
  END IF;
END \$\$;

-- Add check constraint for budget_type
DO \$\$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'budgets_budget_type_check'
  ) THEN
    ALTER TABLE budgets
    ADD CONSTRAINT budgets_budget_type_check
    CHECK (budget_type IN ('income', 'expense'));
  END IF;
END \$\$;

-- Add check constraint for period_type
DO \$\$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'budgets_period_type_check'
  ) THEN
    ALTER TABLE budgets
    ADD CONSTRAINT budgets_period_type_check
    CHECK (period_type IN ('monthly', 'oneTime'));
  END IF;
END \$\$;

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_budgets_budget_type ON budgets(budget_type);
CREATE INDEX IF NOT EXISTS idx_budgets_period_type ON budgets(period_type);
CREATE INDEX IF NOT EXISTS idx_budgets_user_month ON budgets(user_id, month);

-- Drop the unique constraint on (user_id, month) if it exists
-- This allows users to create multiple budgets per month
DO \$\$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'budgets_user_id_month_key'
  ) THEN
    ALTER TABLE budgets DROP CONSTRAINT budgets_user_id_month_key;
  END IF;
END \$\$;

-- Also check for alternative constraint names
DO \$\$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'unique_user_month'
  ) THEN
    ALTER TABLE budgets DROP CONSTRAINT unique_user_month;
  END IF;
END \$\$;
''';

    AppLogger.info(
      '  📝 Executing migration 029 - add budget fields...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Budget fields added successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        '  ❌ Failed to add budget fields',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- WARNING: This will delete title, budget_type, and period_type data!
-- Make sure to backup your data before running this rollback.

-- Drop indexes
DROP INDEX IF EXISTS idx_budgets_budget_type;
DROP INDEX IF EXISTS idx_budgets_period_type;
DROP INDEX IF EXISTS idx_budgets_user_month;

-- Remove check constraints
ALTER TABLE budgets DROP CONSTRAINT IF EXISTS budgets_budget_type_check;
ALTER TABLE budgets DROP CONSTRAINT IF EXISTS budgets_period_type_check;

-- Remove columns
ALTER TABLE budgets DROP COLUMN IF EXISTS title;
ALTER TABLE budgets DROP COLUMN IF EXISTS budget_type;
ALTER TABLE budgets DROP COLUMN IF EXISTS period_type;

-- Restore the unique constraint on (user_id, month) if desired
-- Note: This will fail if there are multiple budgets for the same user/month
-- ALTER TABLE budgets
-- ADD CONSTRAINT budgets_user_id_month_key UNIQUE (user_id, month);
''';

    AppLogger.warning(
      '  ⚠️  Rolling back migration 029 - remove budget fields...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Budget fields removed successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        '  ❌ Failed to rollback budget fields',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}
