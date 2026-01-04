import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Initial database schema migration
///
/// Creates the following tables:
/// - tasks: Task management
/// - projects: Project organization
/// - budgets: Budget tracking
///
/// Also creates indexes for better query performance.
class Migration001CreateInitialSchema extends Migration {
  @override
  String get version => '001_create_initial_schema';

  @override
  String get description => 'Create initial schema for tasks, projects, and budgets';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = _getInitialSchemaSql();

    AppLogger.info('  📝 Executing initial schema migration...');

    try {
      // Execute the SQL using the exec_sql RPC function
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Initial schema created successfully');

      // Optionally verify tables were created (non-fatal)
      await _checkTablesExist(client);
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to create initial schema', e, stackTrace);
      rethrow;
    }
  }

  /// Check if the required tables exist
  Future<void> _checkTablesExist(SupabaseClient client) async {
    try {
      // Try to query each table - this is just a sanity check
      // If RLS is enabled, this might fail even if tables exist, so we don't throw
      await client.from('tasks').select('id').limit(1);
      await client.from('projects').select('id').limit(1);
      await client.from('budgets').select('id').limit(1);

      AppLogger.info('  ✅ Verified: All tables are accessible');
    } catch (e) {
      // Tables might exist but RLS might be blocking access
      // This is OK - the exec_sql already succeeded
      AppLogger.info('  ℹ️  Note: Tables created but access check failed (this is normal with RLS)');
      AppLogger.info('     Error: $e');
    }
  }

  String _getInitialSchemaSql() {
    return '''
-- ============================================================
-- PERSONAL CODEX - INITIAL SCHEMA
-- ============================================================

-- ============================================================
-- PROJECTS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS projects (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  color TEXT,
  is_archived BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- TASKS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS tasks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL,
  priority TEXT NOT NULL,
  project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
  tags TEXT[],
  due_date TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- BUDGETS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS budgets (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  month TEXT NOT NULL UNIQUE,
  categories JSONB DEFAULT '[]'::jsonb,
  records JSONB DEFAULT '[]'::jsonb,
  status TEXT NOT NULL,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  closed_at TIMESTAMP WITH TIME ZONE
);

-- ============================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================

-- Tasks indexes
CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks(priority);
CREATE INDEX IF NOT EXISTS idx_tasks_project_id ON tasks(project_id);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date ON tasks(due_date);
CREATE INDEX IF NOT EXISTS idx_tasks_created_at ON tasks(created_at);

-- Projects indexes
CREATE INDEX IF NOT EXISTS idx_projects_is_archived ON projects(is_archived);
CREATE INDEX IF NOT EXISTS idx_projects_created_at ON projects(created_at);

-- Budgets indexes
CREATE INDEX IF NOT EXISTS idx_budgets_month ON budgets(month);
CREATE INDEX IF NOT EXISTS idx_budgets_status ON budgets(status);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;

-- For now, allow all operations (we'll add proper auth later)
-- WARNING: In production, replace these with proper user-based policies

DROP POLICY IF EXISTS "Allow all for now" ON tasks;
CREATE POLICY "Allow all for now" ON tasks
  FOR ALL
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all for now" ON projects;
CREATE POLICY "Allow all for now" ON projects
  FOR ALL
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "Allow all for now" ON budgets;
CREATE POLICY "Allow all for now" ON budgets
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- ============================================================
-- UPDATED_AT TRIGGERS
-- ============================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS \$\$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
\$\$ language 'plpgsql';

-- Apply trigger to tasks
DROP TRIGGER IF EXISTS update_tasks_updated_at ON tasks;
CREATE TRIGGER update_tasks_updated_at
  BEFORE UPDATE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Apply trigger to projects
DROP TRIGGER IF EXISTS update_projects_updated_at ON projects;
CREATE TRIGGER update_projects_updated_at
  BEFORE UPDATE ON projects
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Apply trigger to budgets
DROP TRIGGER IF EXISTS update_budgets_updated_at ON budgets;
CREATE TRIGGER update_budgets_updated_at
  BEFORE UPDATE ON budgets
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- COMPLETE!
-- ============================================================
''';
  }

  @override
  Future<void> down(SupabaseClient client) async {
    // WARNING: This will delete all data!
    final sql = '''
      DROP TABLE IF EXISTS tasks CASCADE;
      DROP TABLE IF EXISTS projects CASCADE;
      DROP TABLE IF EXISTS budgets CASCADE;
      DROP TABLE IF EXISTS schema_migrations CASCADE;
      DROP FUNCTION IF EXISTS update_updated_at_column CASCADE;
    ''';

    AppLogger.warning('⚠️  Rolling back initial schema - this will delete all data!');
    await client.rpc('exec_sql', params: {'sql': sql});
  }
}
