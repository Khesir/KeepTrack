import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:persona_codex/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 008 - Create debts table for tracking lending and borrowing
class Migration008CreateDebtsTable extends Migration {
  @override
  String get version => '008_create_debts_table';

  @override
  String get description => 'Create debts table for tracking money lent out and money owed';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Create debts table
CREATE TABLE IF NOT EXISTS debts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('lending', 'borrowing')),
  person_name TEXT NOT NULL,
  description TEXT DEFAULT '',
  original_amount NUMERIC NOT NULL,
  remaining_amount NUMERIC NOT NULL,
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  due_date TIMESTAMP WITH TIME ZONE,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'overdue', 'settled')),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  settled_at TIMESTAMP WITH TIME ZONE
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_debts_user ON debts(user_id);
CREATE INDEX IF NOT EXISTS idx_debts_type ON debts(type);
CREATE INDEX IF NOT EXISTS idx_debts_status ON debts(status);
CREATE INDEX IF NOT EXISTS idx_debts_due_date ON debts(due_date);

-- Add RLS policies
ALTER TABLE debts ENABLE ROW LEVEL SECURITY;

-- Users can only see their own debts
CREATE POLICY debts_select_policy ON debts
  FOR SELECT USING (auth.uid() = user_id);

-- Users can only insert their own debts
CREATE POLICY debts_insert_policy ON debts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can only update their own debts
CREATE POLICY debts_update_policy ON debts
  FOR UPDATE USING (auth.uid() = user_id);

-- Users can only delete their own debts
CREATE POLICY debts_delete_policy ON debts
  FOR DELETE USING (auth.uid() = user_id);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_debts_updated_at()
RETURNS TRIGGER AS \$\$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
\$\$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_debts_updated_at
  BEFORE UPDATE ON debts
  FOR EACH ROW
  EXECUTE FUNCTION update_debts_updated_at();
''';

    AppLogger.info('  📝 Executing migration 008 - create debts table...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Debts table created successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to create debts table', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- Drop trigger
DROP TRIGGER IF EXISTS trigger_update_debts_updated_at ON debts;
DROP FUNCTION IF EXISTS update_debts_updated_at();

-- Drop policies
DROP POLICY IF EXISTS debts_select_policy ON debts;
DROP POLICY IF EXISTS debts_insert_policy ON debts;
DROP POLICY IF EXISTS debts_update_policy ON debts;
DROP POLICY IF EXISTS debts_delete_policy ON debts;

-- Drop indexes
DROP INDEX IF EXISTS idx_debts_user;
DROP INDEX IF EXISTS idx_debts_type;
DROP INDEX IF EXISTS idx_debts_status;
DROP INDEX IF EXISTS idx_debts_due_date;

-- Drop table
DROP TABLE IF EXISTS debts CASCADE;
''';

    AppLogger.warning('  ⚠️  Rolling back migration 008 - drop debts table...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Debts table dropped successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to rollback debts table', e, stackTrace);
      rethrow;
    }
  }
}
