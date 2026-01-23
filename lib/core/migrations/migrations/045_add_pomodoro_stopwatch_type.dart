import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Adds 'stopwatch' to the allowed pomodoro session types
class Migration045AddPomodoroStopwatchType extends Migration {
  @override
  String get version => '045_add_pomodoro_stopwatch_type';

  @override
  String get description => 'Add stopwatch type to pomodoro_sessions table';

  @override
  Future<void> up(SupabaseClient client) async {
    AppLogger.info('  Updating pomodoro_sessions type constraint...');

    final sql = '''
      -- Drop the existing check constraint on type column
      ALTER TABLE pomodoro_sessions
        DROP CONSTRAINT IF EXISTS pomodoro_sessions_type_check;

      -- Add new check constraint that includes 'stopwatch'
      ALTER TABLE pomodoro_sessions
        ADD CONSTRAINT pomodoro_sessions_type_check
        CHECK (type IN ('pomodoro', 'short', 'long', 'stopwatch'));
    ''';

    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  Added stopwatch type to pomodoro_sessions');
    } catch (e, stackTrace) {
      AppLogger.error('  Failed to update type constraint', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    AppLogger.info('  Reverting pomodoro_sessions type constraint...');

    final sql = '''
      -- Drop the constraint with stopwatch
      ALTER TABLE pomodoro_sessions
        DROP CONSTRAINT IF EXISTS pomodoro_sessions_type_check;

      -- Restore original constraint (without stopwatch)
      ALTER TABLE pomodoro_sessions
        ADD CONSTRAINT pomodoro_sessions_type_check
        CHECK (type IN ('pomodoro', 'short', 'long'));
    ''';

    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  Reverted type constraint');
    } catch (e, stackTrace) {
      AppLogger.error('  Failed to revert type constraint', e, stackTrace);
      rethrow;
    }
  }
}
