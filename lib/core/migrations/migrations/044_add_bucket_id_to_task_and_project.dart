import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Adds bucket_id foreign key to tasks and projects tables
class Migration044AddBucketIdToTaskAndProject extends Migration {
  @override
  String get version => '044_add_bucket_id_to_task_and_project';

  @override
  String get description => 'Add bucket_id foreign key to tasks and projects tables';

  @override
  Future<void> up(SupabaseClient client) async {
    AppLogger.info('  🔗 Adding bucket_id to tasks and projects tables...');

    final sql = '''
      -- Add bucket_id column to tasks table
      ALTER TABLE tasks 
      ADD COLUMN IF NOT EXISTS bucket_id UUID REFERENCES buckets(id) ON DELETE SET NULL;
      
      -- Add bucket_id column to projects table  
      ALTER TABLE projects 
      ADD COLUMN IF NOT EXISTS bucket_id UUID REFERENCES buckets(id) ON DELETE SET NULL;
      
      -- Add indexes for bucket_id columns for better query performance
      CREATE INDEX IF NOT EXISTS idx_tasks_bucket_id ON tasks(bucket_id);
      CREATE INDEX IF NOT EXISTS idx_projects_bucket_id ON projects(bucket_id);
      
      -- Add composite indexes for common queries
      CREATE INDEX IF NOT EXISTS idx_tasks_bucket_id_status ON tasks(bucket_id, status);
      CREATE INDEX IF NOT EXISTS idx_projects_bucket_id_archived ON projects(bucket_id, is_archived);
    ''';

    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Successfully added bucket_id to tasks and projects tables');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to add bucket_id to tables', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    AppLogger.info('  🗑️ Removing bucket_id from tasks and projects tables...');

    final sql = '''
      -- Drop indexes
      DROP INDEX IF EXISTS idx_tasks_bucket_id;
      DROP INDEX IF EXISTS idx_projects_bucket_id;
      DROP INDEX IF EXISTS idx_tasks_bucket_id_status;
      DROP INDEX IF EXISTS idx_projects_bucket_id_archived;
      
      -- Remove bucket_id columns
      ALTER TABLE tasks DROP COLUMN IF EXISTS bucket_id;
      ALTER TABLE projects DROP COLUMN IF EXISTS bucket_id;
    ''';

    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Successfully removed bucket_id from tasks and projects tables');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to remove bucket_id from tables', e, stackTrace);
      rethrow;
    }
  }
}