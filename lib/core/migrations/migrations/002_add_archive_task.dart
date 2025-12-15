import 'package:supabase_flutter/supabase_flutter.dart';
import '../migration.dart';

/// Migration 002 - Add archived column to tasks
class Migration002AddArchivedTask extends Migration {
  @override
  String get version => '002_add_archived_task';

  @override
  String get description =>
      'Add archived column to tasks table for soft deletes';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Add archived column
ALTER TABLE tasks
ADD COLUMN IF NOT EXISTS archived BOOLEAN DEFAULT FALSE;

-- Index for faster queries on archived tasks
CREATE INDEX IF NOT EXISTS idx_tasks_archived ON tasks(archived);
''';

    print('  📝 Executing migration 002 - add archived column to tasks...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      print('  ✅ Archived column added successfully');
    } catch (e) {
      print('  ❌ Failed to add archived column: $e');
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- Remove archived column
ALTER TABLE tasks
DROP COLUMN IF EXISTS archived;

-- Remove index
DROP INDEX IF EXISTS idx_tasks_archived;
''';

    print('  ⚠️  Rolling back migration 002 - remove archived column...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      print('  ✅ Archived column removed successfully');
    } catch (e) {
      print('  ❌ Failed to rollback archived column: $e');
      rethrow;
    }
  }
}
