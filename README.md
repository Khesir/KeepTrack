# Personal Codex

A personal productivity app built with Flutter and Supabase featuring tasks, projects, and budget management.

## Features

- **Task Management**: Create, organize, and track tasks with priorities and due dates
- **Project Organization**: Group related tasks into projects
- **Budget Tracking**: Manage personal budgets with categories and records
- **Clean Architecture**: Feature-based organization with DI and state management
- **Automatic Migrations**: Database schema updates run automatically on app start

## Setup

### Prerequisites

- Flutter SDK (3.0+)
- A Supabase account (free tier works great)

### 1. Clone the repository

```bash
git clone <your-repo-url>
cd personal_codex
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Set up Supabase

#### Create a Supabase project

1. Go to https://supabase.com
2. Create a new project
3. Wait for the project to be ready

#### Run the bootstrap script

This is a ONE-TIME setup that enables automatic migrations:

1. Open your Supabase project dashboard
2. Navigate to **SQL Editor** in the sidebar
3. Click **New Query**
4. Copy and paste the entire contents of `supabase/bootstrap.sql`
5. Click **Run** (or press Cmd/Ctrl + Enter)

The bootstrap script creates:
- The `exec_sql` function (allows automatic migrations from Flutter)
- The `schema_migrations` table (tracks applied migrations)

### 4. Configure your app

Update `lib/main.dart` with your Supabase credentials:

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_PROJECT_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

You can find these values in your Supabase project settings under **API**.

### 5. Run the app

```bash
flutter run
```

The app will automatically:
1. Connect to Supabase
2. Run all pending migrations
3. Set up the database schema
4. Start the app

## Database Migrations

This project uses **automatic database migrations**. When you start the app:

1. Migration manager checks which migrations have been applied
2. Pending migrations are executed automatically via the `exec_sql` RPC function
3. Successful migrations are recorded in the `schema_migrations` table

No manual SQL execution needed after the initial bootstrap!

See `lib/core/migrations/README.md` for more details.

## Architecture

- **Clean Architecture** with separation of concerns
- **Custom DI System** for dependency injection
- **Custom State Management** using `StreamState`
- **Feature-based organization**:
  - `lib/features/tasks/` - Task management
  - `lib/features/projects/` - Project organization
  - `lib/features/budget/` - Budget tracking
  - `lib/core/` - Shared utilities and infrastructure
  - `lib/shared/` - Cross-feature shared code

## Troubleshooting

### App fails to start with "exec_sql function not found"

**Solution:** You need to run the bootstrap script. See step 3 in Setup above.

### Migrations fail

Check that:
1. Your Supabase credentials are correct
2. The bootstrap script was run successfully
3. Your internet connection is working

### Want to reset the database

1. Go to Supabase SQL Editor
2. Run: `DROP SCHEMA public CASCADE; CREATE SCHEMA public;`
3. Re-run the bootstrap script from `supabase/bootstrap.sql`
4. Restart your app - migrations will run from scratch

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Supabase Documentation](https://supabase.com/docs)
- [Migration System Guide](lib/core/migrations/README.md)
