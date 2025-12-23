import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:persona_codex/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 013 - Update budgets table schema
class Migration013UpdateBudgetsTable extends Migration {
  @override
  String get version => '002_update_budgets_table';

  @override
  String get description =>
      'Update budgets table: add user_id and account_id, remove JSONB columns';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Add user_id column
DO \$\$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'budgets' AND column_name = 'user_id'
  ) THEN
    ALTER TABLE budgets ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END \$\$;

-- Add account_id column
DO \$\$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'budgets' AND column_name = 'account_id'
  ) THEN
    ALTER TABLE budgets ADD COLUMN account_id UUID;
  END IF;
END \$\$;

-- Drop the records JSONB column (transactions stored separately)
ALTER TABLE budgets DROP COLUMN IF EXISTS records;

-- Drop the categories JSONB column (now a separate table)
ALTER TABLE budgets DROP COLUMN IF EXISTS categories;

-- Add check constraint to ensure status is valid
DO \$\$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'budgets_status_check'
  ) THEN
    ALTER TABLE budgets 
    ADD CONSTRAINT budgets_status_check 
    CHECK (status IN ('active', 'closed'));
  END IF;
END \$\$;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_budgets_user_id ON budgets(user_id);
CREATE INDEX IF NOT EXISTS idx_budgets_account_id ON budgets(account_id);

-- Update RLS policies
DROP POLICY IF EXISTS "Allow all for now" ON budgets;
DROP POLICY IF EXISTS "Allow all operations" ON budgets;

-- SELECT: users can read their own budgets
CREATE POLICY budgets_select_policy
  ON budgets
  FOR SELECT
  USING (
    user_id = auth.uid()
    OR user_id IS NULL
  );

-- INSERT: users can only insert their own budgets
CREATE POLICY budgets_insert_policy
  ON budgets
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- UPDATE: users can only update their own budgets
CREATE POLICY budgets_update_policy
  ON budgets
  FOR UPDATE
  USING (auth.uid() = user_id);

-- DELETE: users can only delete their own budgets
CREATE POLICY budgets_delete_policy
  ON budgets
  FOR DELETE
  USING (auth.uid() = user_id);
''';

    AppLogger.info('  📝 Executing migration 002 - update budgets table...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Budgets table updated successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to update budgets table', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- Drop policies
DROP POLICY IF EXISTS budgets_select_policy ON budgets;
DROP POLICY IF EXISTS budgets_insert_policy ON budgets;
DROP POLICY IF EXISTS budgets_update_policy ON budgets;
DROP POLICY IF EXISTS budgets_delete_policy ON budgets;

-- Restore original policy
CREATE POLICY "Allow all for now" ON budgets
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Drop indexes
DROP INDEX IF EXISTS idx_budgets_user_id;
DROP INDEX IF EXISTS idx_budgets_account_id;

-- Remove status check constraint
ALTER TABLE budgets DROP CONSTRAINT IF EXISTS budgets_status_check;

-- Add back categories JSONB column
ALTER TABLE budgets ADD COLUMN IF NOT EXISTS categories JSONB DEFAULT '[]'::jsonb;

-- Add back records JSONB column
ALTER TABLE budgets ADD COLUMN IF NOT EXISTS records JSONB DEFAULT '[]'::jsonb;

-- Remove account_id column
ALTER TABLE budgets DROP COLUMN IF EXISTS account_id;

-- Remove user_id column
ALTER TABLE budgets DROP COLUMN IF EXISTS user_id;
''';

    AppLogger.warning(
      '  ⚠️  Rolling back migration 002 - restore budgets table...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Budgets table rollback successful');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to rollback budgets table', e, stackTrace);
      rethrow;
    }
  }
}
