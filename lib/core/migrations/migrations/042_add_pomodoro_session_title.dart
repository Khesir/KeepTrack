import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Adds title field to pomodoro_sessions table
class Migration042AddPomodoroSessionTitle extends Migration {
  @override
  String get version => '042_add_pomodoro_session_title';

  @override
  String get description => 'Add title field to pomodoro_sessions';

  @override
  Future<void> up(SupabaseClient client) async {
    AppLogger.info('  📝 Adding title field to pomodoro_sessions...');

    final sql = '''
      -- Add title column
      ALTER TABLE pomodoro_sessions
        ADD COLUMN IF NOT EXISTS title TEXT;

      -- Set default titles for existing sessions based on type
      UPDATE pomodoro_sessions
      SET title = CASE
        WHEN type = 'pomodoro' THEN 'Pomodoro Session'
        WHEN type = 'short' THEN 'Short Break'
        WHEN type = 'long' THEN 'Long Break'
        ELSE 'Pomodoro Session'
      END
      WHERE title IS NULL;

      -- Make title NOT NULL after setting defaults
      ALTER TABLE pomodoro_sessions
        ALTER COLUMN title SET NOT NULL;
    ''';

    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Successfully added title field');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to add title field to pomodoro_sessions', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    AppLogger.info('  📝 Removing title field from pomodoro_sessions...');

    final sql = '''
      -- Remove title column
      ALTER TABLE pomodoro_sessions
        DROP COLUMN IF EXISTS title;
    ''';

    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Successfully removed title field');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to remove title field from pomodoro_sessions', e, stackTrace);
      rethrow;
    }
  }
}
