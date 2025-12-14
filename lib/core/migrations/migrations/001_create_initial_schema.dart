import 'package:supabase_flutter/supabase_flutter.dart';
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
    // Note: Supabase client doesn't support direct DDL execution from Flutter
    // We need to execute this SQL in the Supabase SQL Editor
    // This migration serves as documentation and a checkpoint

    final sql = _getInitialSchemaSql();

    // Try to execute via RPC if available
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
    } catch (e) {
      // RPC not available, provide instructions
      print('');
      print('⚠️  Unable to execute SQL directly from Flutter.');
      print('   Please run the following SQL in your Supabase SQL Editor:');
      print('');
      print('   Dashboard → SQL Editor → New Query → Paste the SQL below');
      print('');
      print('=' * 80);
      print(sql);
      print('=' * 80);
      print('');
      print('   After running the SQL, the migration will be recorded automatically.');
      print('');

      // For now, we'll assume the user will run this manually
      // In production, you might want to fail here or check if tables exist
      await _checkTablesExist(client);
    }
  }

  /// Check if the required tables exist
  Future<void> _checkTablesExist(SupabaseClient client) async {
    try {
      // Try to query each table
      await client.from('tasks').select('id').limit(1);
      await client.from('projects').select('id').limit(1);
      await client.from('budgets').select('id').limit(1);

      print('✅ All required tables exist');
    } catch (e) {
      throw Exception(
        'Required tables do not exist. Please run the SQL schema in Supabase SQL Editor first.\n'
        'See the SQL output above.',
      );
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

CREATE POLICY IF NOT EXISTS "Allow all for now" ON tasks
  FOR ALL
  USING (true)
  WITH CHECK (true);

CREATE POLICY IF NOT EXISTS "Allow all for now" ON projects
  FOR ALL
  USING (true)
  WITH CHECK (true);

CREATE POLICY IF NOT EXISTS "Allow all for now" ON budgets
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
-- SCHEMA MIGRATIONS TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS schema_migrations (
  version TEXT PRIMARY KEY,
  applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  description TEXT
);

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

    print('⚠️  Rolling back initial schema - this will delete all data!');
    await client.rpc('exec_sql', params: {'sql': sql});
  }
}
