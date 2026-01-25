import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Adds monthly payment tracking fields to debts table
class Migration046AddDebtMonthlyPaymentFields extends Migration {
  @override
  String get version => '046_add_debt_monthly_payment_fields';

  @override
  String get description =>
      'Add monthly payment amount, fee, next payment date, and payment frequency to debts';

  @override
  Future<void> up(SupabaseClient client) async {
    AppLogger.info('  Adding monthly payment fields to debts table...');

    final sql = '''
      -- Add monthly payment amount field
      ALTER TABLE debts
        ADD COLUMN IF NOT EXISTS monthly_payment_amount DECIMAL(12,2) DEFAULT 0;

      -- Add fee amount field
      ALTER TABLE debts
        ADD COLUMN IF NOT EXISTS fee_amount DECIMAL(12,2) DEFAULT 0;

      -- Add next payment date field
      ALTER TABLE debts
        ADD COLUMN IF NOT EXISTS next_payment_date TIMESTAMP WITH TIME ZONE;

      -- Add payment frequency field with check constraint
      ALTER TABLE debts
        ADD COLUMN IF NOT EXISTS payment_frequency TEXT DEFAULT 'monthly';

      -- Add check constraint for payment frequency values
      DO \$\$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM pg_constraint
          WHERE conname = 'debts_payment_frequency_check'
        ) THEN
          ALTER TABLE debts
            ADD CONSTRAINT debts_payment_frequency_check
            CHECK (payment_frequency IN ('weekly', 'biweekly', 'monthly', 'quarterly'));
        END IF;
      END \$\$;
    ''';

    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  Added monthly payment fields to debts table');
    } catch (e, stackTrace) {
      AppLogger.error(
        '  Failed to add monthly payment fields to debts',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    AppLogger.info('  Removing monthly payment fields from debts table...');

    final sql = '''
      -- Remove check constraint
      ALTER TABLE debts
        DROP CONSTRAINT IF EXISTS debts_payment_frequency_check;

      -- Remove columns
      ALTER TABLE debts
        DROP COLUMN IF EXISTS monthly_payment_amount,
        DROP COLUMN IF EXISTS fee_amount,
        DROP COLUMN IF EXISTS next_payment_date,
        DROP COLUMN IF EXISTS payment_frequency;
    ''';

    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  Removed monthly payment fields from debts table');
    } catch (e, stackTrace) {
      AppLogger.error(
        '  Failed to remove monthly payment fields from debts',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}
