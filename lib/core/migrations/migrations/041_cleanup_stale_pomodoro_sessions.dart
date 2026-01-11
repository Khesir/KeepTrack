import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Cleanup stale pomodoro sessions that are stuck in running status
class Migration041CleanupStalePomodoroSessions extends Migration {
  @override
  String get version => '041_cleanup_stale_pomodoro_sessions';

  @override
  String get description => 'Mark old running sessions as canceled';

  @override
  Future<void> up(SupabaseClient client) async {
    AppLogger.info('  📝 Cleaning up stale pomodoro sessions...');

    final sql = '''
      -- Mark sessions older than 24 hours that are still "running" as canceled
      UPDATE pomodoro_sessions
      SET
        status = 'canceled',
        ended_at = started_at + (duration_seconds || ' seconds')::interval
      WHERE
        status = 'running'
        AND started_at < NOW() - INTERVAL '24 hours'
        AND ended_at IS NULL;
    ''';

    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Successfully cleaned up stale sessions');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to cleanup stale sessions', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    AppLogger.info('  📝 Skipping down migration for cleanup');
    // No down migration needed - we don't want to revert cleanup
  }
}
