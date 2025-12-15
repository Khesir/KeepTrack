# Getting Started with Automatic Migrations

This guide will help you set up your Personal Codex app with fully automatic database migrations.

## What You Need to Do (One-Time Setup)

### Step 1: Run the Bootstrap Script

1. Open your **Supabase Project Dashboard**
2. Click **SQL Editor** in the sidebar
3. Click **New Query**
4. Open the file `supabase/bootstrap.sql` in this project
5. Copy and paste the **entire contents** into the Supabase SQL Editor
6. Click **Run** (or press Cmd/Ctrl + Enter)

You should see: "Success. No rows returned"

### Step 2: Update Your App Credentials

Open `lib/main.dart` and update these lines (around line 36):

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_PROJECT_URL',      // ← Replace this
  anonKey: 'YOUR_SUPABASE_ANON_KEY',     // ← Replace this
);
```

Find your credentials in Supabase:
- Go to **Project Settings** → **API**
- Copy the **Project URL** and **anon/public key**

### Step 3: Run Your App

```bash
flutter run
```

That's it! The app will now:
1. Connect to Supabase
2. Automatically run all pending migrations
3. Set up your database schema
4. Start the app

## What the Bootstrap Script Does

The bootstrap script creates two things:

### 1. The `exec_sql` Function
This PostgreSQL function allows your Flutter app to execute SQL DDL statements (CREATE TABLE, ALTER TABLE, etc.) remotely. This is what makes automatic migrations possible!

### 2. The `schema_migrations` Table
This table keeps track of which migrations have been applied to your database, preventing duplicate migrations.

## What Happens When You Start the App

```
App Start
   ↓
Connect to Supabase
   ↓
Migration Manager Runs
   ├── Check schema_migrations table
   ├── Find pending migrations
   ├── Execute each migration via exec_sql()
   └── Record successful migrations
   ↓
App Ready to Use!
```

## Adding New Migrations

In the future, when you want to add new database changes:

1. Create a new migration file (e.g., `002_add_new_feature.dart`)
2. Add it to the migration list in `migration_manager.dart`
3. Run your app - the migration executes automatically!

No manual SQL needed!

## Troubleshooting

### Error: "exec_sql function not found"

**Problem:** The bootstrap script wasn't run or didn't execute successfully.

**Solution:**
1. Go back to Step 1 above
2. Make sure you copy the **entire** `bootstrap.sql` file
3. Run it in Supabase SQL Editor
4. Restart your app

### Error: "Permission denied"

**Problem:** The `exec_sql` function doesn't have proper permissions.

**Solution:** Re-run the bootstrap script - it includes the necessary GRANT statements.

### Want to Start Fresh?

If you need to reset everything:

```sql
-- Run this in Supabase SQL Editor
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
```

Then:
1. Re-run `bootstrap.sql`
2. Restart your app
3. All migrations will run from scratch

## Security Note

The `exec_sql` function is designed for personal projects where you control both the app and the database. It's protected by Supabase's authentication, but for production apps with multiple users, consider:

- Using Supabase CLI for migrations
- Creating more granular migration functions
- Implementing additional security checks

For personal use, the current setup is perfectly fine!

## Need Help?

See the detailed migration guide: `lib/core/migrations/README.md`
