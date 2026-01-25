import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Adds optional fee parameter to goal and debt payment RPC functions
class Migration048AddFeeToPaymentRpcs extends Migration {
  @override
  String get version => '048_add_fee_to_payment_rpcs';

  @override
  String get description =>
      'Add optional fee parameter to create_goal_payment_transaction and create_debt_payment_transaction';

  @override
  Future<void> up(SupabaseClient client) async {
    AppLogger.info('  Updating payment RPC functions with fee support...');

    final sql = '''
-- Drop existing functions first to avoid overload conflicts
DROP FUNCTION IF EXISTS create_goal_payment_transaction(UUID, UUID, UUID, DECIMAL, transaction_type, TEXT, TIMESTAMP WITH TIME ZONE, TEXT, UUID);
DROP FUNCTION IF EXISTS create_debt_payment_transaction(UUID, UUID, UUID, DECIMAL, transaction_type, TEXT, TIMESTAMP WITH TIME ZONE, TEXT, UUID);

-- ============================================================
-- RPC Function: create_goal_payment_transaction (updated with fee)
-- ============================================================
CREATE OR REPLACE FUNCTION create_goal_payment_transaction(
  p_user_id UUID,
  p_account_id UUID,
  p_finance_category_id UUID,
  p_amount DECIMAL,
  p_type transaction_type,
  p_description TEXT,
  p_date TIMESTAMP WITH TIME ZONE,
  p_notes TEXT,
  p_goal_id UUID,
  p_fee DECIMAL DEFAULT 0
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
  v_total_deduction DECIMAL;
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

  -- Calculate total deduction from account (amount + fee)
  v_total_deduction := p_amount + COALESCE(p_fee, 0);

  -- Determine new status
  IF v_new_current >= v_goal_target THEN
    v_new_status := 'completed';
  ELSE
    v_new_status := (SELECT status FROM goals WHERE id = p_goal_id);
  END IF;

  -- Insert transaction with goal link and fee
  INSERT INTO transactions (
    id, user_id, account_id, finance_category_id,
    amount, type, description, date, notes,
    goal_id, fee, created_at, updated_at
  )
  VALUES (
    gen_random_uuid(), p_user_id, p_account_id, p_finance_category_id,
    p_amount, p_type, p_description, COALESCE(p_date, NOW()), p_notes,
    p_goal_id, COALESCE(p_fee, 0), NOW(), NOW()
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

  -- Update account balance (deduct amount + fee for expenses)
  UPDATE accounts
  SET
    balance = CASE
      WHEN p_type = 'income' THEN balance + p_amount
      WHEN p_type = 'expense' THEN balance - v_total_deduction
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
    'fee', COALESCE(p_fee, 0),
    'success', true
  ) INTO v_result;

  RETURN v_result;
END;
\$\$;

-- ============================================================
-- RPC Function: create_debt_payment_transaction (updated with fee)
-- ============================================================
CREATE OR REPLACE FUNCTION create_debt_payment_transaction(
  p_user_id UUID,
  p_account_id UUID,
  p_finance_category_id UUID,
  p_amount DECIMAL,
  p_type transaction_type,
  p_description TEXT,
  p_date TIMESTAMP WITH TIME ZONE,
  p_notes TEXT,
  p_debt_id UUID,
  p_fee DECIMAL DEFAULT 0
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
  v_total_amount DECIMAL;
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

  -- Calculate total amount including fee
  v_total_amount := p_amount + COALESCE(p_fee, 0);

  -- Determine new status
  IF v_new_remaining <= 0 THEN
    v_new_status := 'settled';
  ELSE
    v_new_status := (SELECT status FROM debts WHERE id = p_debt_id);
  END IF;

  -- Insert transaction with debt link and fee
  INSERT INTO transactions (
    id, user_id, account_id, finance_category_id,
    amount, type, description, date, notes,
    debt_id, fee, created_at, updated_at
  )
  VALUES (
    gen_random_uuid(), p_user_id, p_account_id, p_finance_category_id,
    p_amount, p_type, p_description, COALESCE(p_date, NOW()), p_notes,
    p_debt_id, COALESCE(p_fee, 0), NOW(), NOW()
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

  -- Update account balance (include fee in the total)
  UPDATE accounts
  SET
    balance = CASE
      WHEN p_type = 'income' THEN balance + p_amount
      WHEN p_type = 'expense' THEN balance - v_total_amount
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
    'fee', COALESCE(p_fee, 0),
    'success', true
  ) INTO v_result;

  RETURN v_result;
END;
\$\$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION create_goal_payment_transaction TO authenticated;
GRANT EXECUTE ON FUNCTION create_debt_payment_transaction TO authenticated;
    ''';

    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  Added fee support to payment RPC functions');
    } catch (e, stackTrace) {
      AppLogger.error(
        '  Failed to add fee support to payment RPCs',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    // Reverting would restore the original functions without fee parameter
    // This is handled by re-running migration 020
    AppLogger.info('  Rollback not implemented - run migration 020 to restore');
  }
}
