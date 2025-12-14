# Personal Codex - Setup Guide

This guide will help you get Personal Codex up and running.

## Prerequisites

- Flutter SDK (3.9.2 or higher)
- A Supabase account (free tier works great!)

## Setup Steps

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Set Up Supabase

1. **Create a Supabase project:**
   - Go to https://supabase.com
   - Click "New Project"
   - Fill in your project details
   - Wait for the project to be created (~2 minutes)

2. **Get your credentials:**
   - Go to Project Settings → API
   - Copy your **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - Copy your **anon/public key** (long string starting with `eyJ...`)

3. **Update credentials in code:**
   - Open `lib/main.dart`
   - Replace the URL and key in the `Supabase.initialize()` call (lines 36-39)

### 3. Set Up Database Schema

The app uses automatic migrations, but you need to run the initial schema setup first.

1. **Go to your Supabase Dashboard**
   - Navigate to SQL Editor
   - Click "New Query"

2. **Copy and paste this SQL:**

```sql
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
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

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
```

3. **Click "Run"** to execute the SQL

4. **Verify the tables were created:**
   - Go to Table Editor in your Supabase dashboard
   - You should see: `tasks`, `projects`, `budgets`, `schema_migrations`

### 4. Run the App

```bash
# For Android
flutter run

# For iOS
flutter run -d ios

# For Web
flutter run -d chrome

# For Desktop
flutter run -d windows  # or macos/linux
```

## What Happens on First Run

When you run the app for the first time:

1. ✅ Supabase is initialized with your credentials
2. 🔄 Migration system checks for pending migrations
3. ✅ Migration `001_create_initial_schema` is recorded (tables already exist)
4. 🚀 App dependencies are set up
5. 🎉 App launches successfully!

You should see output like:
```
🚀 Initializing Supabase...
✅ Supabase initialized

🔄 Starting migration check...
📋 Found 0 previously applied migrations
🚀 Running 1 pending migration(s)...
  ⏳ Running: 001_create_initial_schema - Create initial schema for tasks, projects, and budgets
  ✅ Completed: 001_create_initial_schema
✅ All migrations completed successfully
```

## Troubleshooting

### "Unable to execute SQL directly from Flutter"

This is expected! The migration system will show you the SQL to run. Just:
1. Copy the SQL from the console output
2. Paste it into Supabase SQL Editor
3. Run it
4. Restart the app

### "Required tables do not exist"

You forgot to run the SQL in Supabase. Follow step 3 above.

### "Supabase initialization failed"

Check that:
- Your URL and anon key are correct in `main.dart`
- You have an internet connection
- Your Supabase project is active

### "Migration failed"

Check the console output for specific errors. Usually means:
- Tables don't exist yet (run the SQL)
- Network issue (check connection)
- Wrong credentials (update main.dart)

## Next Steps

Once the app is running:

1. **Try creating a task** - Click the + button on Tasks screen
2. **Create a project** - Switch to Projects tab, add a project
3. **Set up a budget** - Go to Budget tab, create a monthly budget

## Database Migrations

Personal Codex uses automatic database migrations. Learn more:
- Read `lib/core/migrations/README.md` for detailed documentation
- See how to create new migrations
- Understand the migration system

## Features

- ✅ Task Management with status, priority, tags, due dates
- ✅ Project Organization with color coding
- ✅ Budget Tracking with categories and records
- ✅ Automatic database migrations
- ✅ Cross-platform (iOS, Android, Web, Desktop)
- ✅ Offline-ready (with Supabase local caching)

## Support

If you run into issues:
1. Check the troubleshooting section above
2. Review the migration documentation
3. Check Supabase logs in your dashboard
4. Verify your database schema in Table Editor

Happy organizing! 🎉
