
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 049 - Create month_plans table
///
/// Adds a parent container table that groups all budget records for a given
/// YYYY-MM month. One row per user per month. Budgets remain linked to their
/// month via the existing [budgets.month] text field (no FK needed — the
/// MonthPlan query fetches budgets by matching month strings).
class Migration049CreateMonthPlansTable extends Migration {
  @override
  String get version => '049_create_month_plans_table';

  @override
  String get description =>
      'Create month_plans table as a parent container for budget groups per month';

  @override
  Future<void> up(dynamic client) async {
    final sql = '''
-- Create month_plans table
CREATE TABLE IF NOT EXISTS month_plans (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  month       TEXT NOT NULL,
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  account_id  UUID,
  notes       TEXT,
  created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- One plan per user per month
CREATE UNIQUE INDEX IF NOT EXISTS idx_month_plans_user_month
  ON month_plans (user_id, month);

-- Fast lookup by user
CREATE INDEX IF NOT EXISTS idx_month_plans_user_id
  ON month_plans (user_id);

-- Enable RLS
ALTER TABLE month_plans ENABLE ROW LEVEL SECURITY;

-- Users can only see and modify their own plans
DROP POLICY IF EXISTS "Users can manage their own month plans" ON month_plans;

CREATE POLICY "Users can manage their own month plans"
  ON month_plans
  FOR ALL
  USING  (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
''';

    AppLogger.info('  📝 Executing migration 049 - create month_plans table...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ month_plans table created successfully');
      AppLogger.info('     - Unique constraint: one plan per (user_id, month)');
      AppLogger.info('     - RLS enabled: users see only their own plans');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to create month_plans table', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> down(dynamic client) async {
    final sql = '''
DROP POLICY IF EXISTS "Users can manage their own month plans" ON month_plans;
DROP INDEX IF EXISTS idx_month_plans_user_month;
DROP INDEX IF EXISTS idx_month_plans_user_id;
DROP TABLE IF EXISTS month_plans;
''';

    AppLogger.warning('  ⚠️  Rolling back migration 049 - drop month_plans table...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ month_plans table dropped successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to rollback migration 049', e, stackTrace);
      rethrow;
    }
  }
}
