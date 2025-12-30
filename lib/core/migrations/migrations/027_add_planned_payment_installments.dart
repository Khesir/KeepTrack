import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:persona_codex/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 027 - Add installment tracking to planned payments
///
/// Adds total_installments and remaining_installments columns
/// to track fixed-term payment plans (e.g., 12-month installments)
///
/// Use cases:
/// - Phone/laptop installment plans
/// - Fixed-term subscriptions
/// - Auto-closing after all installments are paid
class Migration027AddPlannedPaymentInstallments extends Migration {
  @override
  String get version => '027_add_planned_payment_installments';

  @override
  String get description =>
      'Add installment tracking fields to planned_payments table';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Add installment tracking columns to planned_payments table
ALTER TABLE planned_payments
  ADD COLUMN total_installments INTEGER,
  ADD COLUMN remaining_installments INTEGER;

-- Add comments
COMMENT ON COLUMN planned_payments.total_installments IS 'Total number of installments for fixed-term plans (null for recurring)';
COMMENT ON COLUMN planned_payments.remaining_installments IS 'Remaining installments to pay (null for recurring)';

-- Add constraint: if total_installments is set, remaining_installments must be <= total
ALTER TABLE planned_payments
  ADD CONSTRAINT check_installments_valid
  CHECK (
    (total_installments IS NULL AND remaining_installments IS NULL)
    OR
    (total_installments IS NOT NULL AND remaining_installments IS NOT NULL AND remaining_installments <= total_installments AND remaining_installments >= 0)
  );
''';

    AppLogger.info('  📝 Executing migration 027 - add planned payment installments...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Installment columns added to planned_payments table');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to add installment columns', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- Remove installment tracking columns
ALTER TABLE planned_payments
  DROP CONSTRAINT IF EXISTS check_installments_valid,
  DROP COLUMN IF EXISTS total_installments,
  DROP COLUMN IF EXISTS remaining_installments;
''';

    AppLogger.warning(
      '  ⚠️  Rolling back migration 027 - remove planned payment installments...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Installment columns removed from planned_payments table');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to remove installment columns', e, stackTrace);
      rethrow;
    }
  }
}
