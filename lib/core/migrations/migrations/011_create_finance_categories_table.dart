import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 011 - Create finance_categories table
class Migration011CreateFinanceCategoriesTable extends Migration {
  @override
  String get version => '010_create_finance_categories_table';

  @override
  String get description =>
      'Create finance_categories table for user-defined and system finance categories';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Create finance_categories table
CREATE TABLE IF NOT EXISTS finance_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- NULL user_id means system-defined category
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,

  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (
    type IN ('income', 'expense', 'investment', 'savings')
  ),

  is_archive BOOLEAN NOT NULL DEFAULT FALSE,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),

  -- Prevent duplicate category names per user + type
  CONSTRAINT unique_category_per_user UNIQUE (user_id, name, type)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_finance_categories_user
  ON finance_categories(user_id);

CREATE INDEX IF NOT EXISTS idx_finance_categories_type
  ON finance_categories(type);

CREATE INDEX IF NOT EXISTS idx_finance_categories_archive
  ON finance_categories(is_archive);

-- Enable RLS
ALTER TABLE finance_categories ENABLE ROW LEVEL SECURITY;

-- SELECT: users can read their own categories + system categories
CREATE POLICY finance_categories_select_policy
  ON finance_categories
  FOR SELECT
  USING (
    user_id = auth.uid()
    OR user_id IS NULL
  );

-- INSERT: users can only create their own categories
CREATE POLICY finance_categories_insert_policy
  ON finance_categories
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- UPDATE: users can only update their own categories
CREATE POLICY finance_categories_update_policy
  ON finance_categories
  FOR UPDATE
  USING (auth.uid() = user_id);

-- DELETE: users can only delete their own categories
CREATE POLICY finance_categories_delete_policy
  ON finance_categories
  FOR DELETE
  USING (auth.uid() = user_id);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_finance_categories_updated_at()
RETURNS TRIGGER AS \$\$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
\$\$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_finance_categories_updated_at
  BEFORE UPDATE ON finance_categories
  FOR EACH ROW
  EXECUTE FUNCTION update_finance_categories_updated_at();
''';

    AppLogger.info(
      '  📝 Executing migration 010 - create finance_categories table...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Finance categories table created successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        '  ❌ Failed to create finance_categories table',
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
DROP TRIGGER IF EXISTS trigger_update_finance_categories_updated_at
  ON finance_categories;
DROP FUNCTION IF EXISTS update_finance_categories_updated_at();

-- Drop policies
DROP POLICY IF EXISTS finance_categories_select_policy
  ON finance_categories;
DROP POLICY IF EXISTS finance_categories_insert_policy
  ON finance_categories;
DROP POLICY IF EXISTS finance_categories_update_policy
  ON finance_categories;
DROP POLICY IF EXISTS finance_categories_delete_policy
  ON finance_categories;

-- Drop indexes
DROP INDEX IF EXISTS idx_finance_categories_user;
DROP INDEX IF EXISTS idx_finance_categories_type;
DROP INDEX IF EXISTS idx_finance_categories_archive;

-- Drop table
DROP TABLE IF EXISTS finance_categories CASCADE;
''';

    AppLogger.warning(
      '  ⚠️  Rolling back migration 010 - drop finance_categories table...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Finance categories table dropped successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        '  ❌ Failed to rollback finance_categories table',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}
