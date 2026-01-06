import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 037 - Update planned payment RPCs to support fees and skip functionality
class Migration037UpdatePlannedPaymentRpcs extends Migration {
  @override
  String get version => '037_update_planned_payment_rpcs';

  @override
  String get description =>
      'Update create_planned_payment_transaction to support fees and add skip_planned_payment function';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Drop the old function first (since we're changing the signature)
DROP FUNCTION IF EXISTS create_planned_payment_transaction(UUID, UUID, UUID, DECIMAL, transaction_type, TEXT, TIMESTAMP WITH TIME ZONE, TEXT, UUID);

-- Create new function with fee parameters
CREATE OR REPLACE FUNCTION create_planned_payment_transaction(
  p_user_id UUID,
  p_account_id UUID,
  p_finance_category_id UUID,
  p_amount DECIMAL,
  p_type transaction_type,
  p_description TEXT,
  p_date TIMESTAMP WITH TIME ZONE,
  p_notes TEXT,
  p_planned_payment_id UUID,
  p_fee DECIMAL DEFAULT 0,
  p_fee_description TEXT DEFAULT NULL
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
  v_total_cost DECIMAL;
BEGIN
  -- Get planned payment details
  SELECT frequency, next_payment_date
  INTO v_payment_frequency, v_current_next_date
  FROM planned_payments
  WHERE id = p_planned_payment_id AND user_id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Planned payment not found or access denied';
  END IF;

  -- Calculate total cost (amount + fee for expenses)
  v_total_cost := p_amount + COALESCE(p_fee, 0);

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

  -- Insert transaction with planned payment link and fee fields
  INSERT INTO transactions (
    id, user_id, account_id, finance_category_id,
    amount, type, description, date, notes,
    fee, fee_description,
    planned_payment_id, created_at, updated_at
  )
  VALUES (
    gen_random_uuid(), p_user_id, p_account_id, p_finance_category_id,
    p_amount, p_type, p_description, COALESCE(p_date, NOW()), p_notes,
    COALESCE(p_fee, 0), p_fee_description,
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

  -- Update account balance based on transaction type (including fee)
  UPDATE accounts
  SET
    balance = CASE
      WHEN p_type = 'income' THEN balance + (p_amount - COALESCE(p_fee, 0))
      WHEN p_type = 'expense' THEN balance - v_total_cost
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

-- Create skip_planned_payment function
CREATE OR REPLACE FUNCTION skip_planned_payment(
  p_user_id UUID,
  p_planned_payment_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS \$\$
DECLARE
  v_payment_frequency TEXT;
  v_current_next_date TIMESTAMP WITH TIME ZONE;
  v_new_next_date TIMESTAMP WITH TIME ZONE;
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
      RAISE EXCEPTION 'Cannot skip one-time payment';
    WHEN 'daily' THEN
      v_new_next_date := v_current_next_date + INTERVAL '1 day';
    WHEN 'weekly' THEN
      v_new_next_date := v_current_next_date + INTERVAL '7 days';
    WHEN 'biweekly' THEN
      v_new_next_date := v_current_next_date + INTERVAL '14 days';
    WHEN 'monthly' THEN
      v_new_next_date := v_current_next_date + INTERVAL '1 month';
    WHEN 'quarterly' THEN
      v_new_next_date := v_current_next_date + INTERVAL '3 months';
    WHEN 'yearly' THEN
      v_new_next_date := v_current_next_date + INTERVAL '1 year';
    ELSE
      RAISE EXCEPTION 'Unknown payment frequency';
  END CASE;

  -- Update planned payment to skip to next payment date
  UPDATE planned_payments
  SET
    next_payment_date = v_new_next_date,
    updated_at = NOW()
  WHERE id = p_planned_payment_id;

  -- Return result
  SELECT jsonb_build_object(
    'planned_payment_id', p_planned_payment_id,
    'next_payment_date', v_new_next_date,
    'success', true
  ) INTO v_result;

  RETURN v_result;
END;
\$\$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION create_planned_payment_transaction TO authenticated;
GRANT EXECUTE ON FUNCTION skip_planned_payment TO authenticated;
''';

    AppLogger.info(
      '  📝 Executing migration 037 - update planned payment RPCs...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Planned payment RPCs updated successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        '  ❌ Failed to update planned payment RPCs',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- Revert create_planned_payment_transaction to original version
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

-- Drop skip_planned_payment function
DROP FUNCTION IF EXISTS skip_planned_payment;
''';

    AppLogger.warning(
      '  ⚠️  Rolling back migration 037 - revert planned payment RPCs...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Planned payment RPCs reverted successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        '  ❌ Failed to rollback planned payment RPCs',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}
