import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:persona_codex/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 025 - Add fee tracking to budget categories
///
/// Adds fee_spent column to track fees separately from the main amount
/// Updates budget spent calculation to include fees
class Migration025AddBudgetCategoryFeeTracking extends Migration {
  @override
  String get version => '025_add_budget_category_fee_tracking';

  @override
  String get description =>
      'Add fee_spent column to budget_categories and update spent calculation to include fees';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Add fee_spent column to budget_categories
ALTER TABLE budget_categories
  ADD COLUMN fee_spent DECIMAL(12, 2) DEFAULT 0 NOT NULL;

COMMENT ON COLUMN budget_categories.fee_spent IS 'Total fees/taxes paid for this category (tracked separately for transparency)';

-- Drop the existing function first (from migration 015)
-- We need to drop it because we're changing the return type
DROP FUNCTION IF EXISTS calculate_budget_category_spent(UUID, UUID, TEXT);

-- Recreate the budget spent calculation function to include fees
-- This replaces the function from migration 015 with a new signature
CREATE OR REPLACE FUNCTION calculate_budget_category_spent(
  p_budget_id UUID,
  p_finance_category_id UUID,
  p_month TEXT
)
RETURNS TABLE(amount_spent NUMERIC, fee_spent NUMERIC) AS \$\$
DECLARE
  v_start_date DATE;
  v_end_date DATE;
  v_amount_total NUMERIC;
  v_fee_total NUMERIC;
BEGIN
  -- Parse the month string (format: 'YYYY-MM')
  v_start_date := (p_month || '-01')::DATE;
  v_end_date := (v_start_date + INTERVAL '1 month - 1 day')::DATE;

  -- Sum transaction amounts for this category within the budget month
  SELECT COALESCE(SUM(amount), 0)
  INTO v_amount_total
  FROM transactions
  WHERE finance_category_id = p_finance_category_id
    AND date >= v_start_date
    AND date <= v_end_date;

  -- Sum transaction fees for this category within the budget month
  SELECT COALESCE(SUM(fee), 0)
  INTO v_fee_total
  FROM transactions
  WHERE finance_category_id = p_finance_category_id
    AND date >= v_start_date
    AND date <= v_end_date;

  -- Return both amounts
  RETURN QUERY SELECT ABS(v_amount_total), ABS(v_fee_total);
END;
\$\$ LANGUAGE plpgsql;

-- Drop the existing update function (from migration 015)
DROP FUNCTION IF EXISTS update_budget_spent_amounts(UUID);

-- Recreate the function that updates all budget spent amounts
CREATE OR REPLACE FUNCTION update_budget_spent_amounts(p_budget_id UUID)
RETURNS void AS \$\$
DECLARE
  v_category RECORD;
  v_budget_month TEXT;
  v_spent RECORD;
BEGIN
  -- Get the budget month
  SELECT month INTO v_budget_month
  FROM budgets
  WHERE id = p_budget_id;

  -- Update each category's spent amount and fee
  FOR v_category IN
    SELECT id, finance_category_id
    FROM budget_categories
    WHERE budget_id = p_budget_id
  LOOP
    -- Get the spent amounts (amount + fee)
    SELECT * INTO v_spent
    FROM calculate_budget_category_spent(
      p_budget_id,
      v_category.finance_category_id,
      v_budget_month
    );

    -- Update the budget category with both values
    UPDATE budget_categories
    SET
      spent_amount = v_spent.amount_spent,
      fee_spent = v_spent.fee_spent
    WHERE id = v_category.id;
  END LOOP;
END;
\$\$ LANGUAGE plpgsql;

-- Initial calculation: Update fee_spent for all existing budgets
DO \$\$
DECLARE
  v_budget RECORD;
BEGIN
  FOR v_budget IN SELECT id FROM budgets
  LOOP
    PERFORM update_budget_spent_amounts(v_budget.id);
  END LOOP;
END \$\$;
''';

    AppLogger.info(
      '  📝 Executing migration 025 - add budget category fee tracking...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Budget category fee tracking added successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        '  ❌ Failed to add budget category fee tracking',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- Restore original calculate_budget_category_spent function (without fees)
CREATE OR REPLACE FUNCTION calculate_budget_category_spent(
  p_budget_id UUID,
  p_finance_category_id UUID,
  p_month TEXT
)
RETURNS NUMERIC AS \$\$
DECLARE
  v_start_date DATE;
  v_end_date DATE;
  v_total NUMERIC;
BEGIN
  -- Parse the month string (format: 'YYYY-MM')
  v_start_date := (p_month || '-01')::DATE;
  v_end_date := (v_start_date + INTERVAL '1 month - 1 day')::DATE;

  -- Sum transactions for this category within the budget month
  SELECT COALESCE(SUM(amount), 0)
  INTO v_total
  FROM transactions
  WHERE finance_category_id = p_finance_category_id
    AND date >= v_start_date
    AND date <= v_end_date;

  RETURN ABS(v_total);
END;
\$\$ LANGUAGE plpgsql;

-- Restore original update_budget_spent_amounts function
CREATE OR REPLACE FUNCTION update_budget_spent_amounts(p_budget_id UUID)
RETURNS void AS \$\$
DECLARE
  v_category RECORD;
  v_budget_month TEXT;
BEGIN
  -- Get the budget month
  SELECT month INTO v_budget_month
  FROM budgets
  WHERE id = p_budget_id;

  -- Update each category's spent amount
  FOR v_category IN
    SELECT id, finance_category_id
    FROM budget_categories
    WHERE budget_id = p_budget_id
  LOOP
    UPDATE budget_categories
    SET spent_amount = calculate_budget_category_spent(
      p_budget_id,
      v_category.finance_category_id,
      v_budget_month
    )
    WHERE id = v_category.id;
  END LOOP;
END;
\$\$ LANGUAGE plpgsql;

-- Remove fee_spent column
ALTER TABLE budget_categories DROP COLUMN IF EXISTS fee_spent;
''';

    AppLogger.warning(
      '  ⚠️  Rolling back migration 025 - remove budget category fee tracking...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Budget category fee tracking removed successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        '  ❌ Failed to rollback budget category fee tracking',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}
