import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 021 - Add parent_task_id to tasks table for subtask support
class Migration021AddTaskParentTaskId extends Migration {
  @override
  String get version => '021_add_task_parent_task_id';

  @override
  String get description => 'Add parent_task_id column to tasks table to support subtasks';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Add parent_task_id column to tasks table for subtask support
ALTER TABLE tasks
  ADD COLUMN IF NOT EXISTS parent_task_id UUID REFERENCES tasks(id) ON DELETE CASCADE;

-- Create index for better query performance when fetching subtasks
CREATE INDEX IF NOT EXISTS idx_tasks_parent_task_id ON tasks(parent_task_id);

-- Add comment to document the column purpose
COMMENT ON COLUMN tasks.parent_task_id IS 'Reference to parent task for subtasks. NULL for main tasks.';
''';

    AppLogger.info('  📝 Executing migration 021 - add parent_task_id to tasks...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ parent_task_id column added to tasks table successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to add parent_task_id to tasks', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- Remove index
DROP INDEX IF EXISTS idx_tasks_parent_task_id;

-- Remove parent_task_id column from tasks table
ALTER TABLE tasks
  DROP COLUMN IF EXISTS parent_task_id;
''';

    AppLogger.warning('  ⚠️  Rolling back migration 021 - remove parent_task_id from tasks...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ parent_task_id column removed from tasks table successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to rollback parent_task_id from tasks', e, stackTrace);
      rethrow;
    }
  }
}
