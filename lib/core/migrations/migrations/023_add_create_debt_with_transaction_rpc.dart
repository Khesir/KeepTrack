import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 023 - Add RPC function for creating debt with initial transaction
class Migration023AddCreateDebtWithTransactionRpc extends Migration {
  @override
  String get version => '023_add_create_debt_with_transaction_rpc';

  @override
  String get description =>
      'Create RPC function for atomically creating a debt with its initial transaction';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- ============================================================
-- RPC Function: create_debt_with_initial_transaction
-- ============================================================
-- Creates a new debt and its initial transaction atomically
-- Lending: money lent out -> expense transaction (reduces account balance)
-- Borrowing: money owed -> income transaction (increases account balance)
-- Returns the created debt with transaction details
CREATE OR REPLACE FUNCTION create_debt_with_initial_transaction(
  p_user_id UUID,
  p_account_id UUID,
  p_finance_category_id UUID,
  p_debt_type TEXT,
  p_person_name TEXT,
  p_description TEXT,
  p_original_amount DECIMAL,
  p_start_date TIMESTAMP WITH TIME ZONE,
  p_due_date TIMESTAMP WITH TIME ZONE,
  p_status TEXT,
  p_notes TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS \$\$
DECLARE
  v_debt_id UUID;
  v_transaction_id UUID;
  v_transaction_type transaction_type;
  v_transaction_desc TEXT;
  v_result JSONB;
BEGIN
  -- Validate debt type
  IF p_debt_type NOT IN ('lending', 'borrowing') THEN
    RAISE EXCEPTION 'Invalid debt type. Must be "lending" or "borrowing"';
  END IF;

  -- Determine transaction type and description based on debt type
  IF p_debt_type = 'lending' THEN
    v_transaction_type := 'expense';  -- Money going out
    v_transaction_desc := 'Debt lent to ' || p_person_name;
  ELSE
    v_transaction_type := 'income';   -- Money coming in
    v_transaction_desc := 'Debt borrowed from ' || p_person_name;
  END IF;

  -- Insert transaction first
  INSERT INTO transactions (
    id, user_id, account_id, finance_category_id,
    amount, type, description, date, notes,
    created_at, updated_at
  )
  VALUES (
    gen_random_uuid(), p_user_id, p_account_id, p_finance_category_id,
    p_original_amount, v_transaction_type, v_transaction_desc,
    COALESCE(p_start_date, NOW()), p_description,
    NOW(), NOW()
  )
  RETURNING id INTO v_transaction_id;

  -- Create the debt with transaction reference
  INSERT INTO debts (
    id, user_id, account_id, transaction_id,
    type, person_name, description,
    original_amount, remaining_amount,
    start_date, due_date, status, notes,
    created_at, updated_at
  )
  VALUES (
    gen_random_uuid(), p_user_id, p_account_id, v_transaction_id,
    p_debt_type, p_person_name, p_description,
    p_original_amount, p_original_amount,
    COALESCE(p_start_date, NOW()), p_due_date,
    COALESCE(p_status, 'active'), p_notes,
    NOW(), NOW()
  )
  RETURNING id INTO v_debt_id;

  -- Update transaction with debt reference
  UPDATE transactions
  SET debt_id = v_debt_id, updated_at = NOW()
  WHERE id = v_transaction_id;

  -- Update account balance based on transaction type
  UPDATE accounts
  SET
    balance = CASE
      WHEN v_transaction_type = 'income' THEN balance + p_original_amount
      WHEN v_transaction_type = 'expense' THEN balance - p_original_amount
      ELSE balance
    END,
    updated_at = NOW()
  WHERE id = p_account_id;

  -- Return result with debt and transaction details
  SELECT jsonb_build_object(
    'debt_id', v_debt_id,
    'transaction_id', v_transaction_id,
    'transaction_type', v_transaction_type,
    'amount', p_original_amount,
    'success', true
  ) INTO v_result;

  RETURN v_result;
END;
\$\$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION create_debt_with_initial_transaction TO authenticated;
''';

    AppLogger.info(
      '  📝 Executing migration 023 - add create_debt_with_initial_transaction RPC...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ create_debt_with_initial_transaction RPC function created successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to create create_debt_with_initial_transaction RPC', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- Drop RPC function
DROP FUNCTION IF EXISTS create_debt_with_initial_transaction;
''';

    AppLogger.warning(
      '  ⚠️  Rolling back migration 023 - remove create_debt_with_initial_transaction RPC...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ create_debt_with_initial_transaction RPC function removed successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to rollback create_debt_with_initial_transaction RPC', e, stackTrace);
      rethrow;
    }
  }
}
