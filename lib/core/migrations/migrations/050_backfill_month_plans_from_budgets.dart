import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 050 - Backfill month_plans for existing budget data
///
/// Existing budgets were created before the month_plans table existed.
/// This migration creates one month_plans row per distinct (user_id, month)
/// combination already present in the budgets table, so all historical
/// budget groups have a parent MonthPlan.
///
/// Uses ON CONFLICT DO NOTHING so it is safe to re-run.
class Migration050BackfillMonthPlansFromBudgets extends Migration {
  @override
  String get version => '050_backfill_month_plans_from_budgets';

  @override
  String get description =>
      'Backfill month_plans rows for every distinct (user_id, month) that exists in budgets';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Insert one month_plan per distinct (user_id, month) found in budgets.
-- account_id is taken from the first budget row for that user+month (arbitrary
-- but consistent — all budgets in the same month share the same account).
-- ON CONFLICT DO NOTHING ensures re-running is safe.
INSERT INTO month_plans (month, user_id, account_id, created_at, updated_at)
SELECT DISTINCT ON (user_id, month)
  month,
  user_id,
  account_id,
  MIN(created_at) OVER (PARTITION BY user_id, month),
  NOW()
FROM budgets
WHERE user_id IS NOT NULL
ON CONFLICT (user_id, month) DO NOTHING;
''';

    AppLogger.info(
      '  📝 Executing migration 050 - backfill month_plans from existing budgets...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info(
        '  ✅ month_plans backfill complete — one plan per (user_id, month)',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '  ❌ Failed to backfill month_plans',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    // Removing backfilled rows is safe only if no plans were created after
    // migration 049. We delete plans whose created_at matches what this
    // migration would have inserted (i.e., plans with no manually-set notes).
    // In practice, a full rollback is only needed in development.
    AppLogger.warning(
      '  ⚠️  Rolling back migration 050 — deleting backfilled month_plans...',
    );
    final sql = '''
DELETE FROM month_plans
WHERE id IN (
  SELECT mp.id
  FROM month_plans mp
  INNER JOIN budgets b
    ON b.user_id = mp.user_id AND b.month = mp.month
  WHERE mp.notes IS NULL
);
''';
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Backfilled month_plans removed');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to rollback migration 050', e, stackTrace);
      rethrow;
    }
  }
}
