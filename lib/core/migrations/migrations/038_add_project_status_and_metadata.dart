import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 038 - Add status and metadata fields to projects table
class Migration038AddProjectStatusAndMetadata extends Migration {
  @override
  String get version => '038_add_project_status_and_metadata';

  @override
  String get description => 'Add status and metadata columns to projects table';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Add status column to projects table (active, postponed, closed)
ALTER TABLE projects
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active';

-- Add metadata column to projects table (dynamic JSON key-value pairs)
ALTER TABLE projects
  ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;

-- Add check constraint for status values
DO \$\$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'projects_status_check'
  ) THEN
    ALTER TABLE projects
      ADD CONSTRAINT projects_status_check
      CHECK (status IN ('active', 'postponed', 'closed'));
  END IF;
END \$\$;

-- Create index for status filtering
CREATE INDEX IF NOT EXISTS idx_projects_status ON projects(status);

-- Create GIN index for metadata JSONB queries
CREATE INDEX IF NOT EXISTS idx_projects_metadata ON projects USING GIN (metadata);

-- Add comments to document the columns
COMMENT ON COLUMN projects.status IS 'Project status: active, postponed, or closed';
COMMENT ON COLUMN projects.metadata IS 'Dynamic metadata as JSON (e.g., project links, ERD links, etc.)';
''';

    AppLogger.info('  📝 Executing migration 038 - add status and metadata to projects...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ status and metadata columns added to projects table successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to add status and metadata to projects', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- Remove indexes
DROP INDEX IF EXISTS idx_projects_status;
DROP INDEX IF EXISTS idx_projects_metadata;

-- Remove check constraint
ALTER TABLE projects
  DROP CONSTRAINT IF EXISTS projects_status_check;

-- Remove status and metadata columns from projects table
ALTER TABLE projects
  DROP COLUMN IF EXISTS status,
  DROP COLUMN IF EXISTS metadata;
''';

    AppLogger.warning('  ⚠️  Rolling back migration 038 - remove status and metadata from projects...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ status and metadata columns removed from projects table successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to rollback status and metadata from projects', e, stackTrace);
      rethrow;
    }
  }
}
