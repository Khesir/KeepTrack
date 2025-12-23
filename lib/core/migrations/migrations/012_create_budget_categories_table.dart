import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:persona_codex/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 012 - Create budget_categories table
class Migration012CreateBudgetCategoriesTable extends Migration {
  @override
  String get version => '012_create_budget_categories_table';

  @override
  String get description =>
      'Create budget_categories table with user reference, RLS, and triggers for timestamps';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Create budget_categories table
CREATE TABLE IF NOT EXISTS budget_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  budget_id UUID NOT NULL REFERENCES budgets(id) ON DELETE CASCADE,
  finance_category_id UUID NOT NULL REFERENCES finance_categories(id) ON DELETE RESTRICT,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,

  target_amount NUMERIC NOT NULL,
  spent_amount NUMERIC DEFAULT 0,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_budget_categories_budget
  ON budget_categories(budget_id);

CREATE INDEX IF NOT EXISTS idx_budget_categories_user
  ON budget_categories(user_id);

-- Enable RLS
ALTER TABLE budget_categories ENABLE ROW LEVEL SECURITY;

-- SELECT: users can read their own categories for their budgets
CREATE POLICY budget_categories_select_policy
  ON budget_categories
  FOR SELECT
  USING (
    user_id = auth.uid()
    OR user_id IS NULL
  );

-- INSERT: users can only insert categories for their budgets
CREATE POLICY budget_categories_insert_policy
  ON budget_categories
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- UPDATE: users can only update their own categories
CREATE POLICY budget_categories_update_policy
  ON budget_categories
  FOR UPDATE
  USING (auth.uid() = user_id);

-- DELETE: users can only delete their own categories
CREATE POLICY budget_categories_delete_policy
  ON budget_categories
  FOR DELETE
  USING (auth.uid() = user_id);

-- Trigger to auto-update updated_at
CREATE OR REPLACE FUNCTION update_budget_categories_updated_at()
RETURNS TRIGGER AS \$\$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
\$\$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_budget_categories_updated_at
  BEFORE UPDATE ON budget_categories
  FOR EACH ROW
  EXECUTE FUNCTION update_budget_categories_updated_at();
''';

    AppLogger.info(
      '  📝 Executing migration 012 - create budget_categories table...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Budget categories table created successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        '  ❌ Failed to create budget_categories table',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- Drop trigger and function
DROP TRIGGER IF EXISTS trigger_update_budget_categories_updated_at
  ON budget_categories;
DROP FUNCTION IF EXISTS update_budget_categories_updated_at();

-- Drop policies
DROP POLICY IF EXISTS budget_categories_select_policy
  ON budget_categories;
DROP POLICY IF EXISTS budget_categories_insert_policy
  ON budget_categories;
DROP POLICY IF EXISTS budget_categories_update_policy
  ON budget_categories;
DROP POLICY IF EXISTS budget_categories_delete_policy
  ON budget_categories;

-- Drop indexes
DROP INDEX IF EXISTS idx_budget_categories_budget;
DROP INDEX IF EXISTS idx_budget_categories_user;

-- Drop table
DROP TABLE IF EXISTS budget_categories CASCADE;
''';

    AppLogger.warning(
      '  ⚠️  Rolling back migration 012 - drop budget_categories table...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Budget categories table dropped successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        '  ❌ Failed to rollback budget_categories table',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}
