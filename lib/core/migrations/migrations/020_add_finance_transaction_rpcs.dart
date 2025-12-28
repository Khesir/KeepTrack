import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:persona_codex/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 020 - Add RPC functions for atomic financial transaction operations
class Migration020AddFinanceTransactionRpcs extends Migration {
  @override
  String get version => '020_add_finance_transaction_rpcs';

  @override
  String get description =>
      'Create RPC functions for atomic transaction operations with goals, debts, and planned payments';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- ============================================================
-- RPC Function: create_goal_payment_transaction
-- ============================================================
-- Creates a transaction linked to a goal and updates goal progress atomically
-- Returns the created transaction
CREATE OR REPLACE FUNCTION create_goal_payment_transaction(
  p_user_id UUID,
  p_account_id UUID,
  p_finance_category_id UUID,
  p_amount DECIMAL,
  p_type transaction_type,
  p_description TEXT,
  p_date TIMESTAMP WITH TIME ZONE,
  p_notes TEXT,
  p_goal_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS \$\$
DECLARE
  v_transaction_id UUID;
  v_goal_target DECIMAL;
  v_goal_current DECIMAL;
  v_new_current DECIMAL;
  v_new_status TEXT;
  v_result JSONB;
BEGIN
  -- Get goal details
  SELECT target_amount, current_amount
  INTO v_goal_target, v_goal_current
  FROM goals
  WHERE id = p_goal_id AND user_id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Goal not found or access denied';
  END IF;

  -- Calculate new goal amount
  v_new_current := v_goal_current + p_amount;

  -- Determine new status
  IF v_new_current >= v_goal_target THEN
    v_new_status := 'completed';
  ELSE
    v_new_status := (SELECT status FROM goals WHERE id = p_goal_id);
  END IF;

  -- Insert transaction with goal link
  INSERT INTO transactions (
    id, user_id, account_id, finance_category_id,
    amount, type, description, date, notes,
    goal_id, created_at, updated_at
  )
  VALUES (
    gen_random_uuid(), p_user_id, p_account_id, p_finance_category_id,
    p_amount, p_type, p_description, COALESCE(p_date, NOW()), p_notes,
    p_goal_id, NOW(), NOW()
  )
  RETURNING id INTO v_transaction_id;

  -- Update goal progress
  UPDATE goals
  SET
    current_amount = v_new_current,
    status = v_new_status,
    completed_at = CASE
      WHEN v_new_status = 'completed' THEN NOW()
      ELSE completed_at
    END,
    updated_at = NOW()
  WHERE id = p_goal_id;

  -- Update account balance based on transaction type
  UPDATE accounts
  SET
    balance = CASE
      WHEN p_type = 'income' THEN balance + p_amount
      WHEN p_type = 'expense' THEN balance - p_amount
      ELSE balance
    END,
    updated_at = NOW()
  WHERE id = p_account_id;

  -- Return result with transaction details
  SELECT jsonb_build_object(
    'transaction_id', v_transaction_id,
    'goal_id', p_goal_id,
    'new_goal_amount', v_new_current,
    'goal_status', v_new_status,
    'success', true
  ) INTO v_result;

  RETURN v_result;
END;
\$\$;

-- ============================================================
-- RPC Function: create_debt_payment_transaction
-- ============================================================
-- Creates a transaction linked to a debt and updates debt remaining amount atomically
CREATE OR REPLACE FUNCTION create_debt_payment_transaction(
  p_user_id UUID,
  p_account_id UUID,
  p_finance_category_id UUID,
  p_amount DECIMAL,
  p_type transaction_type,
  p_description TEXT,
  p_date TIMESTAMP WITH TIME ZONE,
  p_notes TEXT,
  p_debt_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS \$\$
DECLARE
  v_transaction_id UUID;
  v_debt_remaining DECIMAL;
  v_new_remaining DECIMAL;
  v_new_status TEXT;
  v_result JSONB;
BEGIN
  -- Get debt details
  SELECT remaining_amount
  INTO v_debt_remaining
  FROM debts
  WHERE id = p_debt_id AND user_id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Debt not found or access denied';
  END IF;

  -- Calculate new remaining amount
  v_new_remaining := GREATEST(v_debt_remaining - p_amount, 0);

  -- Determine new status
  IF v_new_remaining <= 0 THEN
    v_new_status := 'settled';
  ELSE
    v_new_status := (SELECT status FROM debts WHERE id = p_debt_id);
  END IF;

  -- Insert transaction with debt link
  INSERT INTO transactions (
    id, user_id, account_id, finance_category_id,
    amount, type, description, date, notes,
    debt_id, created_at, updated_at
  )
  VALUES (
    gen_random_uuid(), p_user_id, p_account_id, p_finance_category_id,
    p_amount, p_type, p_description, COALESCE(p_date, NOW()), p_notes,
    p_debt_id, NOW(), NOW()
  )
  RETURNING id INTO v_transaction_id;

  -- Update debt
  UPDATE debts
  SET
    remaining_amount = v_new_remaining,
    status = v_new_status,
    settled_at = CASE
      WHEN v_new_status = 'settled' THEN NOW()
      ELSE settled_at
    END,
    updated_at = NOW()
  WHERE id = p_debt_id;

  -- Update account balance based on transaction type
  UPDATE accounts
  SET
    balance = CASE
      WHEN p_type = 'income' THEN balance + p_amount
      WHEN p_type = 'expense' THEN balance - p_amount
      ELSE balance
    END,
    updated_at = NOW()
  WHERE id = p_account_id;

  -- Return result
  SELECT jsonb_build_object(
    'transaction_id', v_transaction_id,
    'debt_id', p_debt_id,
    'new_remaining_amount', v_new_remaining,
    'debt_status', v_new_status,
    'success', true
  ) INTO v_result;

  RETURN v_result;
END;
\$\$;

-- ============================================================
-- RPC Function: create_planned_payment_transaction
-- ============================================================
-- Creates a transaction for a planned payment and updates payment record atomically
CREATE OR REPLACE FUNCTION create_planned_payment_transaction(
  p_user_id UUID,
  p_account_id UUID,
  p_finance_category_id UUID,
  p_amount DECIMAL,
  p_type transaction_type,
  p_description TEXT,
  p_date TIMESTAMP WITH TIME ZONE,
  p_notes TEXT,
  p_planned_payment_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS \$\$
DECLARE
  v_transaction_id UUID;
  v_payment_frequency TEXT;
  v_current_next_date TIMESTAMP WITH TIME ZONE;
  v_new_next_date TIMESTAMP WITH TIME ZONE;
  v_new_status TEXT;
  v_result JSONB;
BEGIN
  -- Get planned payment details
  SELECT frequency, next_payment_date
  INTO v_payment_frequency, v_current_next_date
  FROM planned_payments
  WHERE id = p_planned_payment_id AND user_id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Planned payment not found or access denied';
  END IF;

  -- Calculate next payment date based on frequency
  CASE v_payment_frequency
    WHEN 'oneTime' THEN
      v_new_next_date := v_current_next_date;
      v_new_status := 'closed';
    WHEN 'daily' THEN
      v_new_next_date := v_current_next_date + INTERVAL '1 day';
      v_new_status := (SELECT status FROM planned_payments WHERE id = p_planned_payment_id);
    WHEN 'weekly' THEN
      v_new_next_date := v_current_next_date + INTERVAL '7 days';
      v_new_status := (SELECT status FROM planned_payments WHERE id = p_planned_payment_id);
    WHEN 'biweekly' THEN
      v_new_next_date := v_current_next_date + INTERVAL '14 days';
      v_new_status := (SELECT status FROM planned_payments WHERE id = p_planned_payment_id);
    WHEN 'monthly' THEN
      v_new_next_date := v_current_next_date + INTERVAL '1 month';
      v_new_status := (SELECT status FROM planned_payments WHERE id = p_planned_payment_id);
    WHEN 'quarterly' THEN
      v_new_next_date := v_current_next_date + INTERVAL '3 months';
      v_new_status := (SELECT status FROM planned_payments WHERE id = p_planned_payment_id);
    WHEN 'yearly' THEN
      v_new_next_date := v_current_next_date + INTERVAL '1 year';
      v_new_status := (SELECT status FROM planned_payments WHERE id = p_planned_payment_id);
    ELSE
      RAISE EXCEPTION 'Unknown payment frequency';
  END CASE;

  -- Insert transaction with planned payment link
  INSERT INTO transactions (
    id, user_id, account_id, finance_category_id,
    amount, type, description, date, notes,
    planned_payment_id, created_at, updated_at
  )
  VALUES (
    gen_random_uuid(), p_user_id, p_account_id, p_finance_category_id,
    p_amount, p_type, p_description, COALESCE(p_date, NOW()), p_notes,
    p_planned_payment_id, NOW(), NOW()
  )
  RETURNING id INTO v_transaction_id;

  -- Update planned payment
  UPDATE planned_payments
  SET
    last_payment_date = NOW(),
    next_payment_date = v_new_next_date,
    status = v_new_status,
    updated_at = NOW()
  WHERE id = p_planned_payment_id;

  -- Update account balance based on transaction type
  UPDATE accounts
  SET
    balance = CASE
      WHEN p_type = 'income' THEN balance + p_amount
      WHEN p_type = 'expense' THEN balance - p_amount
      ELSE balance
    END,
    updated_at = NOW()
  WHERE id = p_account_id;

  -- Return result
  SELECT jsonb_build_object(
    'transaction_id', v_transaction_id,
    'planned_payment_id', p_planned_payment_id,
    'next_payment_date', v_new_next_date,
    'payment_status', v_new_status,
    'success', true
  ) INTO v_result;

  RETURN v_result;
END;
\$\$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION create_goal_payment_transaction TO authenticated;
GRANT EXECUTE ON FUNCTION create_debt_payment_transaction TO authenticated;
GRANT EXECUTE ON FUNCTION create_planned_payment_transaction TO authenticated;
''';

    AppLogger.info('  📝 Executing migration 020 - add finance transaction RPCs...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Finance transaction RPC functions created successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to create finance transaction RPCs', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- Drop RPC functions
DROP FUNCTION IF EXISTS create_goal_payment_transaction;
DROP FUNCTION IF EXISTS create_debt_payment_transaction;
DROP FUNCTION IF EXISTS create_planned_payment_transaction;
''';

    AppLogger.warning(
      '  ⚠️  Rolling back migration 020 - remove finance transaction RPCs...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Finance transaction RPC functions removed successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to rollback finance transaction RPCs', e, stackTrace);
      rethrow;
    }
  }
}