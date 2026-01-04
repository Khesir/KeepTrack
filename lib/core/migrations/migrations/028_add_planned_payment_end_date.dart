import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 028 - Add end date to planned payments
///
/// Adds end_date column to allow payments to auto-close after a specific date
///
/// Use cases:
/// - Fixed-term subscriptions (e.g., 12-month gym membership)
/// - Time-limited payment plans
/// - Auto-closing after end date is reached
class Migration028AddPlannedPaymentEndDate extends Migration {
  @override
  String get version => '028_add_planned_payment_end_date';

  @override
  String get description => 'Add end_date column to planned_payments table';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Add end_date column to planned_payments
ALTER TABLE planned_payments
  ADD COLUMN end_date TIMESTAMPTZ;

-- Add comment
COMMENT ON COLUMN planned_payments.end_date IS 'Optional end date - payment will auto-close when this date is reached';

-- Add check constraint to ensure end_date is after next_payment_date if set
ALTER TABLE planned_payments
  ADD CONSTRAINT check_end_date_after_next_payment
  CHECK (
    end_date IS NULL
    OR end_date >= next_payment_date
  );
''';

    AppLogger.info('  📝 Executing migration 028 - add planned payment end date...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ end_date column added to planned_payments table');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to add end_date column', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- Drop check constraint
ALTER TABLE planned_payments
  DROP CONSTRAINT IF EXISTS check_end_date_after_next_payment;

-- Drop end_date column
ALTER TABLE planned_payments
  DROP COLUMN IF EXISTS end_date;
''';

    AppLogger.warning(
      '  ⚠️  Rolling back migration 028 - remove planned payment end date...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ end_date column removed from planned_payments table');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to remove end_date column', e, stackTrace);
      rethrow;
    }
  }
}
