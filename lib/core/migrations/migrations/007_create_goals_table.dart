import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 007 - Create goals table for financial goals
class Migration007CreateGoalsTable extends Migration {
  @override
  String get version => '007_create_goals_table';

  @override
  String get description => 'Create goals table for tracking financial savings goals';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Create goals table
CREATE TABLE IF NOT EXISTS goals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT DEFAULT '',
  target_amount NUMERIC NOT NULL,
  current_amount NUMERIC DEFAULT 0,
  target_date TIMESTAMP WITH TIME ZONE,
  color_hex TEXT,
  icon_code_point TEXT,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'paused')),
  monthly_contribution NUMERIC DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  completed_at TIMESTAMP WITH TIME ZONE
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_goals_user ON goals(user_id);
CREATE INDEX IF NOT EXISTS idx_goals_status ON goals(status);
CREATE INDEX IF NOT EXISTS idx_goals_target_date ON goals(target_date);

-- Add RLS policies
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;

-- Users can only see their own goals
CREATE POLICY goals_select_policy ON goals
  FOR SELECT USING (auth.uid() = user_id);

-- Users can only insert their own goals
CREATE POLICY goals_insert_policy ON goals
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can only update their own goals
CREATE POLICY goals_update_policy ON goals
  FOR UPDATE USING (auth.uid() = user_id);

-- Users can only delete their own goals
CREATE POLICY goals_delete_policy ON goals
  FOR DELETE USING (auth.uid() = user_id);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_goals_updated_at()
RETURNS TRIGGER AS \$\$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
\$\$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_goals_updated_at
  BEFORE UPDATE ON goals
  FOR EACH ROW
  EXECUTE FUNCTION update_goals_updated_at();
''';

    AppLogger.info('  📝 Executing migration 007 - create goals table...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Goals table created successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to create goals table', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- Drop trigger
DROP TRIGGER IF EXISTS trigger_update_goals_updated_at ON goals;
DROP FUNCTION IF EXISTS update_goals_updated_at();

-- Drop policies
DROP POLICY IF EXISTS goals_select_policy ON goals;
DROP POLICY IF EXISTS goals_insert_policy ON goals;
DROP POLICY IF EXISTS goals_update_policy ON goals;
DROP POLICY IF EXISTS goals_delete_policy ON goals;

-- Drop indexes
DROP INDEX IF EXISTS idx_goals_user;
DROP INDEX IF EXISTS idx_goals_status;
DROP INDEX IF EXISTS idx_goals_target_date;

-- Drop table
DROP TABLE IF EXISTS goals CASCADE;
''';

    AppLogger.warning('  ⚠️  Rolling back migration 007 - drop goals table...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Goals table dropped successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to rollback goals table', e, stackTrace);
      rethrow;
    }
  }
}
