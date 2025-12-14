# Database Migrations

This folder contains the database migration system for Personal Codex.

## Overview

Migrations are **automatic** and run when the app starts. They ensure your Supabase database schema is up-to-date.

## How It Works

1. **App starts** → `main.dart` calls migration manager
2. **Migration manager** checks which migrations have been applied
3. **Pending migrations** are executed in order
4. **Migration tracking** table records successful migrations

## Quick Start

### Initial Setup

1. **Create your Supabase project** at https://supabase.com

2. **Run the initial migration SQL** in Supabase SQL Editor:
   - Go to your Supabase Dashboard
   - Navigate to SQL Editor
   - Click "New Query"
   - Copy the SQL from `migrations/001_create_initial_schema.dart`
   - Run the query

3. **Update your credentials** in `lib/main.dart`:
   ```dart
   SupabaseService(
     supabaseUrl: 'YOUR_PROJECT_URL',
     supabaseAnonKey: 'YOUR_ANON_KEY',
   )
   ```

4. **Run your app** - migrations will run automatically!

## Creating a New Migration

### Example: Adding a new field to tasks

**Step 1: Create the migration file**

Create `lib/core/migrations/migrations/002_add_estimated_hours.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../migration.dart';

class Migration002AddEstimatedHours extends Migration {
  @override
  String get version => '002_add_estimated_hours';

  @override
  String get description => 'Add estimated_hours field to tasks table';

  @override
  Future<void> up(SupabaseClient client) async {
    // Run this SQL in Supabase SQL Editor first!
    print('''
      Please run this SQL in Supabase SQL Editor:

      ALTER TABLE tasks
      ADD COLUMN estimated_hours INTEGER;

      CREATE INDEX idx_tasks_estimated_hours
      ON tasks(estimated_hours);
    ''');

    // Check if column exists
    await client.from('tasks').select('estimated_hours').limit(1);
  }

  @override
  Future<void> down(SupabaseClient client) async {
    // Rollback: remove the column
    print('Rolling back: DROP COLUMN estimated_hours');
  }
}
```

**Step 2: Register the migration**

Add it to `migration_manager.dart`:

```dart
List<Migration> get _allMigrations => [
  Migration001CreateInitialSchema(),
  Migration002AddEstimatedHours(),  // ← Add here
  // Add new migrations below
];
```

**Step 3: Update your models**

Update `lib/features/tasks/domain/entities/task.dart`:

```dart
class Task {
  final int? estimatedHours;  // Add field

  Task({
    // ...
    this.estimatedHours,
  });

  // Update copyWith, toJson, fromJson
}
```

**Step 4: Run the SQL**

Before running the app:
1. Go to Supabase SQL Editor
2. Run the ALTER TABLE command
3. Now run your app - migration will be recorded

**Step 5: Run your app**

The migration will be detected and recorded automatically!

## Migration Naming Convention

Format: `NNN_description_in_snake_case.dart`

Examples:
- `001_create_initial_schema.dart`
- `002_add_estimated_hours.dart`
- `003_create_user_preferences_table.dart`
- `004_add_indexes_for_search.dart`

## Migration Workflow

```
┌─────────────────────────────────────────────────────────┐
│                     App Starts                          │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│          MigrationManager.runMigrations()               │
│                                                         │
│  1. Check schema_migrations table                      │
│  2. Get list of applied migrations                     │
│  3. Find pending migrations                            │
│  4. Run each pending migration                         │
│  5. Record successful migrations                       │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│              App Continues Normally                     │
└─────────────────────────────────────────────────────────┘
```

## Best Practices

### ✅ DO

- **Run SQL manually first** in Supabase SQL Editor
- **Test migrations** on a development database
- **Keep migrations small** - one logical change per migration
- **Add migrations to the end** of the list
- **Include indexes** for frequently queried fields
- **Add descriptions** explaining what the migration does

### ❌ DON'T

- **Never modify** an applied migration
- **Never reorder** migrations
- **Never delete** old migrations
- **Don't skip** the SQL Editor step
- **Don't run** destructive migrations in production without backups

## Migration Examples

### Adding a Table

```dart
class Migration003CreateNotifications extends Migration {
  @override
  String get version => '003_create_notifications';

  @override
  String get description => 'Create notifications table';

  @override
  Future<void> up(SupabaseClient client) async {
    // SQL to run in Supabase SQL Editor:
    final sql = '''
      CREATE TABLE notifications (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        user_id UUID NOT NULL,
        title TEXT NOT NULL,
        message TEXT,
        read BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );

      CREATE INDEX idx_notifications_user_id ON notifications(user_id);
      CREATE INDEX idx_notifications_read ON notifications(read);
    ''';

    print('Run this SQL:\n$sql');

    // Verify table exists
    await client.from('notifications').select('id').limit(1);
  }
}
```

### Adding an Index

```dart
class Migration004AddSearchIndexes extends Migration {
  @override
  String get version => '004_add_search_indexes';

  @override
  String get description => 'Add full-text search indexes';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
      -- Add GIN index for full-text search on tasks
      CREATE INDEX idx_tasks_search
      ON tasks
      USING gin(to_tsvector('english', title || ' ' || COALESCE(description, '')));
    ''';

    print('Run this SQL:\n$sql');
  }
}
```

### Data Migration

```dart
class Migration005MigrateOldStatuses extends Migration {
  @override
  String get version => '005_migrate_old_statuses';

  @override
  String get description => 'Migrate old status values to new format';

  @override
  Future<void> up(SupabaseClient client) async {
    // This can run from Flutter since it's data, not schema
    final oldTasks = await client
        .from('tasks')
        .select()
        .eq('status', 'done');

    for (var task in oldTasks) {
      await client
          .from('tasks')
          .update({'status': 'completed'})
          .eq('id', task['id']);
    }

    print('Migrated ${oldTasks.length} tasks');
  }
}
```

## Troubleshooting

### Migration fails with "table doesn't exist"

**Solution:** Run the SQL in Supabase SQL Editor first, then restart the app.

### Migration runs but data isn't there

**Solution:** Check Supabase Dashboard → Table Editor to verify the schema.

### Want to reset everything

1. Go to Supabase SQL Editor
2. Run: `DROP SCHEMA public CASCADE; CREATE SCHEMA public;`
3. Run the initial migration SQL
4. Delete and reinstall the app

### Check migration status

```dart
final manager = MigrationManager(supabaseClient);
final status = await manager.getStatus();
print(status); // { total: 3, applied: 2, pending: 1, ... }
```

## Schema Migrations Table

The system tracks migrations in the `schema_migrations` table:

| Column      | Type      | Description                    |
|-------------|-----------|--------------------------------|
| version     | TEXT      | Migration version (PRIMARY KEY)|
| applied_at  | TIMESTAMP | When migration was applied     |
| description | TEXT      | What the migration does        |

## Architecture

```
lib/core/migrations/
├── README.md                           ← You are here
├── migration.dart                      ← Base Migration class
├── migration_manager.dart              ← Migration orchestrator
└── migrations/
    ├── 001_create_initial_schema.dart  ← Initial schema
    ├── 002_add_estimated_hours.dart    ← Example migration
    └── ...                             ← Future migrations
```

## Integration with Main App

See `lib/main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // Run migrations BEFORE setting up dependencies
  final migrationManager = MigrationManager(Supabase.instance.client);
  await migrationManager.runMigrations();

  // Now setup app dependencies
  _setupDependencies();

  runApp(const PersonalCodexApp());
}
```

## Further Reading

- [Supabase Migrations Guide](https://supabase.com/docs/guides/database/migrations)
- [PostgreSQL ALTER TABLE](https://www.postgresql.org/docs/current/sql-altertable.html)
- [Supabase Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
