import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 015 - Add function to calculate and update budget spent amounts
class Migration015AddBudgetSpentCalculation extends Migration {
  @override
  String get version => '015_add_budget_spent_calculation';

  @override
  String get description =>
      'Add function and trigger to automatically calculate spent amounts for budget categories based on transactions';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Function to calculate spent amount for a budget category
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

  RETURN ABS(v_total); -- Return absolute value for expenses
END;
\$\$ LANGUAGE plpgsql;

-- Function to update spent amounts for all categories in a budget
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

-- Trigger function to update budget spent amounts when transactions change
CREATE OR REPLACE FUNCTION trigger_update_budget_spent()
RETURNS TRIGGER AS \$\$
DECLARE
  v_affected_budgets UUID[];
  v_budget_id UUID;
  v_transaction_month TEXT;
BEGIN
  -- Get the month from the transaction date (format: 'YYYY-MM')
  v_transaction_month := TO_CHAR(COALESCE(NEW.date, OLD.date), 'YYYY-MM');

  -- Find budgets that might be affected by this transaction
  SELECT ARRAY_AGG(DISTINCT b.id)
  INTO v_affected_budgets
  FROM budgets b
  INNER JOIN budget_categories bc ON bc.budget_id = b.id
  WHERE b.month = v_transaction_month
    AND bc.finance_category_id = COALESCE(NEW.finance_category_id, OLD.finance_category_id);

  -- Update each affected budget
  IF v_affected_budgets IS NOT NULL THEN
    FOREACH v_budget_id IN ARRAY v_affected_budgets
    LOOP
      PERFORM update_budget_spent_amounts(v_budget_id);
    END LOOP;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
\$\$ LANGUAGE plpgsql;

-- Create trigger on transactions table
DROP TRIGGER IF EXISTS trigger_transaction_update_budget_spent ON transactions;
CREATE TRIGGER trigger_transaction_update_budget_spent
  AFTER INSERT OR UPDATE OR DELETE ON transactions
  FOR EACH ROW
  EXECUTE FUNCTION trigger_update_budget_spent();

-- Initial calculation: Update spent amounts for all existing budgets
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
      '  📝 Executing migration 015 - add budget spent calculation...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Budget spent calculation added successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        '  ❌ Failed to add budget spent calculation',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- Drop trigger
DROP TRIGGER IF EXISTS trigger_transaction_update_budget_spent ON transactions;

-- Drop functions
DROP FUNCTION IF EXISTS trigger_update_budget_spent();
DROP FUNCTION IF EXISTS update_budget_spent_amounts(UUID);
DROP FUNCTION IF EXISTS calculate_budget_category_spent(UUID, UUID, TEXT);

-- Reset spent amounts to 0
UPDATE budget_categories SET spent_amount = 0;
''';

    AppLogger.warning(
      '  ⚠️  Rolling back migration 015 - remove budget spent calculation...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Budget spent calculation removed successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        '  ❌ Failed to rollback budget spent calculation',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}
