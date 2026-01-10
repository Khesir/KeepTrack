import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Creates pomodoro_sessions table for tracking focus timer sessions
class Migration039CreatePomodoroSessionsTable extends Migration {
  @override
  String get version => '039_create_pomodoro_sessions_table';

  @override
  String get description => 'Create pomodoro_sessions table for timer tracking';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = _getPomodoroSessionsTableSql();

    AppLogger.info('  📝 Creating pomodoro_sessions table...');

    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ pomodoro_sessions table created successfully');

      // Verify table was created
      await _checkTableExists(client);
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to create pomodoro_sessions table', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _checkTableExists(SupabaseClient client) async {
    try {
      await client.from('pomodoro_sessions').select('id').limit(1);
      AppLogger.info('  ✅ Verified: pomodoro_sessions table is accessible');
    } catch (e) {
      AppLogger.warning('  ⚠️  Could not verify table (might be RLS): $e');
    }
  }

  String _getPomodoroSessionsTableSql() {
    return '''
      -- Create pomodoro_sessions table
      CREATE TABLE IF NOT EXISTS pomodoro_sessions (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        user_id UUID NOT NULL,
        type TEXT NOT NULL CHECK (type IN ('pomodoro', 'short', 'long')),
        duration_seconds INTEGER NOT NULL,
        started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        ended_at TIMESTAMPTZ,
        status TEXT NOT NULL CHECK (status IN ('running', 'completed', 'canceled')),
        tasks_cleared TEXT[] DEFAULT '{}',
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );

      -- Create indexes for better query performance
      CREATE INDEX IF NOT EXISTS idx_pomodoro_sessions_user_id
        ON pomodoro_sessions(user_id);

      CREATE INDEX IF NOT EXISTS idx_pomodoro_sessions_started_at
        ON pomodoro_sessions(started_at DESC);

      CREATE INDEX IF NOT EXISTS idx_pomodoro_sessions_status
        ON pomodoro_sessions(status)
        WHERE status = 'running';

      CREATE INDEX IF NOT EXISTS idx_pomodoro_sessions_user_started
        ON pomodoro_sessions(user_id, started_at DESC);

      -- Add updated_at trigger
      CREATE OR REPLACE FUNCTION update_pomodoro_sessions_updated_at()
      RETURNS TRIGGER AS \$\$
      BEGIN
        NEW.updated_at = NOW();
        RETURN NEW;
      END;
      \$\$ LANGUAGE plpgsql;

      DROP TRIGGER IF EXISTS update_pomodoro_sessions_updated_at_trigger
        ON pomodoro_sessions;

      CREATE TRIGGER update_pomodoro_sessions_updated_at_trigger
        BEFORE UPDATE ON pomodoro_sessions
        FOR EACH ROW
        EXECUTE FUNCTION update_pomodoro_sessions_updated_at();

      -- Enable Row Level Security
      ALTER TABLE pomodoro_sessions ENABLE ROW LEVEL SECURITY;

      -- Drop existing policies if any
      DROP POLICY IF EXISTS "Users can view their own pomodoro sessions"
        ON pomodoro_sessions;
      DROP POLICY IF EXISTS "Users can insert their own pomodoro sessions"
        ON pomodoro_sessions;
      DROP POLICY IF EXISTS "Users can update their own pomodoro sessions"
        ON pomodoro_sessions;
      DROP POLICY IF EXISTS "Users can delete their own pomodoro sessions"
        ON pomodoro_sessions;

      -- Create RLS policies
      CREATE POLICY "Users can view their own pomodoro sessions"
        ON pomodoro_sessions FOR SELECT
        USING (auth.uid() = user_id);

      CREATE POLICY "Users can insert their own pomodoro sessions"
        ON pomodoro_sessions FOR INSERT
        WITH CHECK (auth.uid() = user_id);

      CREATE POLICY "Users can update their own pomodoro sessions"
        ON pomodoro_sessions FOR UPDATE
        USING (auth.uid() = user_id)
        WITH CHECK (auth.uid() = user_id);

      CREATE POLICY "Users can delete their own pomodoro sessions"
        ON pomodoro_sessions FOR DELETE
        USING (auth.uid() = user_id);

      -- Grant permissions
      GRANT ALL ON pomodoro_sessions TO authenticated;
      GRANT ALL ON pomodoro_sessions TO service_role;
    ''';
  }

  @override
  Future<void> down(SupabaseClient client) async {
    AppLogger.info('  📝 Dropping pomodoro_sessions table...');

    final sql = '''
      DROP TRIGGER IF EXISTS update_pomodoro_sessions_updated_at_trigger
        ON pomodoro_sessions;
      DROP FUNCTION IF EXISTS update_pomodoro_sessions_updated_at();
      DROP TABLE IF EXISTS pomodoro_sessions CASCADE;
    ''';

    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ pomodoro_sessions table dropped successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to drop pomodoro_sessions table', e, stackTrace);
      rethrow;
    }
  }
}
