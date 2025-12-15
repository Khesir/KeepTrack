-- ============================================================
-- SUPABASE BOOTSTRAP SCRIPT
-- ============================================================
-- This script needs to be run ONCE in Supabase SQL Editor
-- to enable automatic migrations from the Flutter app.
--
-- How to run:
-- 1. Go to your Supabase project dashboard
-- 2. Click on "SQL Editor" in the sidebar
-- 3. Click "New Query"
-- 4. Paste this entire script
-- 5. Click "Run" (or press Cmd/Ctrl + Enter)
--
-- After running this script, your Flutter app will be able to
-- run migrations automatically without manual SQL execution.
-- ============================================================

-- ============================================================
-- 1. CREATE EXEC_SQL FUNCTION
-- ============================================================
-- This function allows the Flutter app to execute SQL DDL
-- statements (CREATE TABLE, ALTER TABLE, etc.) remotely.
--
-- ⚠️  SECURITY NOTE: This is intended for personal projects.
-- For production apps, consider more granular migration functions
-- or use Supabase CLI for migrations.
-- ============================================================

CREATE OR REPLACE FUNCTION exec_sql(sql TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER -- Runs with the privileges of the function owner
AS $$
BEGIN
  -- Execute the provided SQL
  EXECUTE sql;

  -- Return success message
  RETURN 'SQL executed successfully';
EXCEPTION
  WHEN OTHERS THEN
    -- Re-raise the error with details
    RAISE EXCEPTION 'SQL execution failed: %', SQLERRM;
END;
$$;

-- Grant execute permission to authenticated users
-- For personal projects, you can use anon role if needed
GRANT EXECUTE ON FUNCTION exec_sql(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION exec_sql(TEXT) TO anon;

-- ============================================================
-- 2. CREATE SCHEMA MIGRATIONS TABLE
-- ============================================================
-- This table tracks which migrations have been applied
-- ============================================================

CREATE TABLE IF NOT EXISTS schema_migrations (
  version TEXT PRIMARY KEY,
  applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  description TEXT
);

-- Allow app to read/write migrations
ALTER TABLE schema_migrations ENABLE ROW LEVEL SECURITY;

-- Drop the policy if it exists, then create it
DROP POLICY IF EXISTS "Allow all operations on schema_migrations" ON schema_migrations;

CREATE POLICY "Allow all operations on schema_migrations"
ON schema_migrations
FOR ALL
USING (true)
WITH CHECK (true);

-- ============================================================
-- BOOTSTRAP COMPLETE!
-- ============================================================
-- You can now run your Flutter app and it will automatically
-- apply all pending migrations.
-- ============================================================
