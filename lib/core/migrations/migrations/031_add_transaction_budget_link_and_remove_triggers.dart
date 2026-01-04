import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:persona_codex/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 031 - Add budget_id to transactions and remove trigger-based calculations
///
/// Changes:
/// 1. Add budget_id column to transactions table for direct budget linking
/// 2. Remove automatic trigger-based budget spent calculations
/// 3. Remove spent_amount and fee_spent from budget_categories (will be calculated client-side)
class Migration031AddTransactionBudgetLinkAndRemoveTriggers extends Migration {
  @override
  String get version => '031_add_transaction_budget_link_and_remove_triggers';

  @override
  String get description =>
      'Add budget_id to transactions, remove trigger-based budget calculations, and remove spent_amount/fee_spent from budget_categories';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Step 1: Add budget_id column to transactions
DO \$\$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'transactions' AND column_name = 'budget_id'
  ) THEN
    ALTER TABLE transactions ADD COLUMN budget_id UUID REFERENCES budgets(id) ON DELETE SET NULL;
    CREATE INDEX IF NOT EXISTS idx_transactions_budget_id ON transactions(budget_id);
    COMMENT ON COLUMN transactions.budget_id IS 'Direct link to budget for explicit tracking';
  END IF;
END \$\$;

-- Step 2: Remove trigger-based budget calculation system
DROP TRIGGER IF EXISTS trigger_transaction_update_budget_spent ON transactions;
DROP FUNCTION IF EXISTS trigger_update_budget_spent();
DROP FUNCTION IF EXISTS update_budget_spent_amounts(UUID);
DROP FUNCTION IF EXISTS calculate_budget_category_spent(UUID, UUID, TEXT);

-- Step 3: Remove spent_amount and fee_spent columns from budget_categories
-- These will now be calculated client-side by querying transactions
DO \$\$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'budget_categories' AND column_name = 'spent_amount'
  ) THEN
    ALTER TABLE budget_categories DROP COLUMN spent_amount;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'budget_categories' AND column_name = 'fee_spent'
  ) THEN
    ALTER TABLE budget_categories DROP COLUMN fee_spent;
  END IF;
END \$\$;

-- Note: Existing transactions will have NULL budget_id
-- They will need to be manually linked or will be excluded from budget tracking
''';

    AppLogger.info(
      '  📝 Executing migration 031 - add budget_id to transactions and remove triggers...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Transaction budget link added and triggers removed successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        '  ❌ Failed to add budget_id and remove triggers',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- WARNING: This rollback will:
-- 1. Remove budget_id from transactions
-- 2. Restore spent_amount and fee_spent to budget_categories
-- 3. Restore trigger-based calculations

-- Step 1: Restore spent_amount and fee_spent columns
ALTER TABLE budget_categories
  ADD COLUMN IF NOT EXISTS spent_amount DECIMAL(15, 2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS fee_spent DECIMAL(15, 2) DEFAULT 0;

-- Step 2: Restore calculation functions (from migration 015)
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
  v_start_date := (p_month || '-01')::DATE;
  v_end_date := (v_start_date + INTERVAL '1 month - 1 day')::DATE;

  SELECT COALESCE(SUM(amount), 0)
  INTO v_total
  FROM transactions
  WHERE finance_category_id = p_finance_category_id
    AND date >= v_start_date
    AND date <= v_end_date;

  RETURN ABS(v_total);
END;
\$\$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_budget_spent_amounts(p_budget_id UUID)
RETURNS void AS \$\$
DECLARE
  v_category RECORD;
  v_budget_month TEXT;
BEGIN
  SELECT month INTO v_budget_month
  FROM budgets
  WHERE id = p_budget_id;

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

CREATE OR REPLACE FUNCTION trigger_update_budget_spent()
RETURNS TRIGGER AS \$\$
DECLARE
  v_affected_budgets UUID[];
  v_budget_id UUID;
  v_transaction_month TEXT;
BEGIN
  v_transaction_month := TO_CHAR(COALESCE(NEW.date, OLD.date), 'YYYY-MM');

  SELECT ARRAY_AGG(DISTINCT b.id)
  INTO v_affected_budgets
  FROM budgets b
  INNER JOIN budget_categories bc ON bc.budget_id = b.id
  WHERE b.month = v_transaction_month
    AND bc.finance_category_id = COALESCE(NEW.finance_category_id, OLD.finance_category_id);

  IF v_affected_budgets IS NOT NULL THEN
    FOREACH v_budget_id IN ARRAY v_affected_budgets
    LOOP
      PERFORM update_budget_spent_amounts(v_budget_id);
    END LOOP;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
\$\$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_transaction_update_budget_spent
  AFTER INSERT OR UPDATE OR DELETE ON transactions
  FOR EACH ROW
  EXECUTE FUNCTION trigger_update_budget_spent();

-- Step 3: Remove budget_id column and index
DROP INDEX IF EXISTS idx_transactions_budget_id;
ALTER TABLE transactions DROP COLUMN IF EXISTS budget_id;
''';

    AppLogger.warning(
      '  ⚠️  Rolling back migration 031 - restore triggers and remove budget_id...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Triggers restored and budget_id removed successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        '  ❌ Failed to rollback migration 031',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}
