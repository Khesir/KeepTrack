import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:persona_codex/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 017 - Update transactions table structure
class Migration017UpdateTransactionsStructure extends Migration {
  @override
  String get version => '017_update_transactions_structure';

  @override
  String get description =>
      'Update transactions table: change id and account_id to UUID, replace category_id with finance_category_id';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Drop existing trigger temporarily to avoid conflicts
DROP TRIGGER IF EXISTS trigger_transaction_update_budget_spent ON transactions;

-- Create a new transactions table with correct structure
CREATE TABLE transactions_new (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
  finance_category_id UUID NOT NULL REFERENCES finance_categories(id) ON DELETE RESTRICT,
  amount NUMERIC NOT NULL,
  date DATE NOT NULL,
  description TEXT,
  notes TEXT,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Copy data from old table, converting text IDs to UUIDs
-- Only copy rows where account_id is valid and exists in accounts table
INSERT INTO transactions_new (
  id,
  account_id,
  finance_category_id,
  amount,
  date,
  description,
  notes,
  user_id,
  created_at,
  updated_at
)
SELECT 
  CASE 
    WHEN t.id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\$' 
    THEN t.id::UUID 
    ELSE gen_random_uuid() 
  END as id,
  t.account_id::UUID as account_id,
  t.category_id::UUID as finance_category_id,
  t.amount,
  t.date,
  t.description,
  t.notes,
  t.user_id,
  t.created_at,
  t.updated_at
FROM transactions t
INNER JOIN accounts a ON a.id = t.account_id::UUID
WHERE t.account_id IS NOT NULL 
  AND t.account_id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\$'
  AND t.category_id IS NOT NULL
  AND t.user_id IS NOT NULL;

-- Drop old table and rename new one
DROP TABLE transactions;
ALTER TABLE transactions_new RENAME TO transactions;

-- Create indexes for performance
CREATE INDEX idx_transactions_account_id ON transactions(account_id);
CREATE INDEX idx_transactions_finance_category_id ON transactions(finance_category_id);
CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_date ON transactions(date);

-- Enable Row Level Security
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- Drop old policies if they exist
DROP POLICY IF EXISTS "Users can view their own transactions" ON transactions;
DROP POLICY IF EXISTS "Users can insert their own transactions" ON transactions;
DROP POLICY IF EXISTS "Users can update their own transactions" ON transactions;
DROP POLICY IF EXISTS "Users can delete their own transactions" ON transactions;
DROP POLICY IF EXISTS "Users can view own transactions" ON transactions;
DROP POLICY IF EXISTS "Users can insert own transactions" ON transactions;
DROP POLICY IF EXISTS "Users can update own transactions" ON transactions;
DROP POLICY IF EXISTS "Users can delete own transactions" ON transactions;

-- RLS Policy: Users can only see their own transactions
CREATE POLICY "Users can view own transactions"
  ON transactions
  FOR SELECT
  USING (auth.uid() = user_id);

-- RLS Policy: Users can insert their own transactions
CREATE POLICY "Users can insert own transactions"
  ON transactions
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can update their own transactions
CREATE POLICY "Users can update own transactions"
  ON transactions
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can delete their own transactions
CREATE POLICY "Users can delete own transactions"
  ON transactions
  FOR DELETE
  USING (auth.uid() = user_id);

-- Recreate the budget spent trigger
CREATE TRIGGER trigger_transaction_update_budget_spent
  AFTER INSERT OR UPDATE OR DELETE ON transactions
  FOR EACH ROW
  EXECUTE FUNCTION trigger_update_budget_spent();

-- Create updated_at trigger
DROP TRIGGER IF EXISTS update_transactions_updated_at ON transactions;
CREATE TRIGGER update_transactions_updated_at
  BEFORE UPDATE ON transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
''';

    AppLogger.info(
      '  📝 Executing migration 017 - update transactions structure...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Transactions table updated successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        '  ❌ Failed to update transactions structure',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- Drop triggers
DROP TRIGGER IF EXISTS update_transactions_updated_at ON transactions;
DROP TRIGGER IF EXISTS trigger_transaction_update_budget_spent ON transactions;

-- Create old structure
CREATE TABLE transactions_old (
  id TEXT PRIMARY KEY,
  account_id TEXT,
  category_id UUID,
  amount NUMERIC NOT NULL,
  date DATE NOT NULL,
  description TEXT,
  notes TEXT,
  user_id UUID NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Copy data back
INSERT INTO transactions_old
SELECT 
  id::TEXT,
  account_id::TEXT,
  finance_category_id,
  amount,
  date,
  description,
  notes,
  user_id,
  created_at,
  updated_at
FROM transactions;

-- Drop new table and rename old one
DROP TABLE transactions;
ALTER TABLE transactions_old RENAME TO transactions;

-- Recreate budget trigger
CREATE TRIGGER trigger_transaction_update_budget_spent
  AFTER INSERT OR UPDATE OR DELETE ON transactions
  FOR EACH ROW
  EXECUTE FUNCTION trigger_update_budget_spent();
''';

    AppLogger.warning(
      '  ⚠️  Rolling back migration 017 - revert transactions structure...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Transactions structure reverted successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        '  ❌ Failed to rollback transactions structure',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}
