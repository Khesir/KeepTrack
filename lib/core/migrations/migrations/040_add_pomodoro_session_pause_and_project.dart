import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Adds pause tracking and project relation to pomodoro_sessions table
class Migration040AddPomodoroSessionPauseAndProject extends Migration {
  @override
  String get version => '040_add_pomodoro_session_pause_and_project';

  @override
  String get description => 'Add pause tracking and project relation to pomodoro_sessions';

  @override
  Future<void> up(SupabaseClient client) async {
    AppLogger.info('  📝 Adding pause and project fields to pomodoro_sessions...');

    final sql = '''
      -- Add new columns to pomodoro_sessions table
      ALTER TABLE pomodoro_sessions
        ADD COLUMN IF NOT EXISTS project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
        ADD COLUMN IF NOT EXISTS paused_at TIMESTAMPTZ,
        ADD COLUMN IF NOT EXISTS elapsed_seconds_before_pause INTEGER DEFAULT 0;

      -- Update status check constraint to include 'paused'
      ALTER TABLE pomodoro_sessions DROP CONSTRAINT IF EXISTS pomodoro_sessions_status_check;
      ALTER TABLE pomodoro_sessions
        ADD CONSTRAINT pomodoro_sessions_status_check
        CHECK (status IN ('running', 'paused', 'completed', 'canceled'));

      -- Create index for project lookups
      CREATE INDEX IF NOT EXISTS idx_pomodoro_sessions_project_id
        ON pomodoro_sessions(project_id)
        WHERE project_id IS NOT NULL;
    ''';

    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Successfully added pause and project fields');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to add fields to pomodoro_sessions', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    AppLogger.info('  📝 Removing pause and project fields from pomodoro_sessions...');

    final sql = '''
      -- Remove added columns
      ALTER TABLE pomodoro_sessions
        DROP COLUMN IF EXISTS project_id,
        DROP COLUMN IF EXISTS paused_at,
        DROP COLUMN IF EXISTS elapsed_seconds_before_pause;

      -- Restore original status check constraint
      ALTER TABLE pomodoro_sessions DROP CONSTRAINT IF EXISTS pomodoro_sessions_status_check;
      ALTER TABLE pomodoro_sessions
        ADD CONSTRAINT pomodoro_sessions_status_check
        CHECK (status IN ('running', 'completed', 'canceled'));

      -- Drop index
      DROP INDEX IF EXISTS idx_pomodoro_sessions_project_id;
    ''';

    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Successfully removed pause and project fields');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to remove fields from pomodoro_sessions', e, stackTrace);
      rethrow;
    }
  }
}
