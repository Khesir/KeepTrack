import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Adds management and withdrawal fee percentage fields to goals table
class Migration047AddGoalFeeFields extends Migration {
  @override
  String get version => '047_add_goal_fee_fields';

  @override
  String get description =>
      'Add management fee percent and withdrawal fee percent to goals';

  @override
  Future<void> up(SupabaseClient client) async {
    AppLogger.info('  Adding fee fields to goals table...');

    final sql = '''
      -- Add management fee percent field (0-100)
      ALTER TABLE goals
        ADD COLUMN IF NOT EXISTS management_fee_percent DECIMAL(5,2) DEFAULT 0;

      -- Add withdrawal fee percent field (0-100)
      ALTER TABLE goals
        ADD COLUMN IF NOT EXISTS withdrawal_fee_percent DECIMAL(5,2) DEFAULT 0;

      -- Add check constraints for fee percentages
      DO \$\$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM pg_constraint
          WHERE conname = 'goals_management_fee_percent_check'
        ) THEN
          ALTER TABLE goals
            ADD CONSTRAINT goals_management_fee_percent_check
            CHECK (management_fee_percent >= 0 AND management_fee_percent <= 100);
        END IF;

        IF NOT EXISTS (
          SELECT 1 FROM pg_constraint
          WHERE conname = 'goals_withdrawal_fee_percent_check'
        ) THEN
          ALTER TABLE goals
            ADD CONSTRAINT goals_withdrawal_fee_percent_check
            CHECK (withdrawal_fee_percent >= 0 AND withdrawal_fee_percent <= 100);
        END IF;
      END \$\$;
    ''';

    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  Added fee fields to goals table');
    } catch (e, stackTrace) {
      AppLogger.error('  Failed to add fee fields to goals', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    AppLogger.info('  Removing fee fields from goals table...');

    final sql = '''
      -- Remove check constraints
      ALTER TABLE goals
        DROP CONSTRAINT IF EXISTS goals_management_fee_percent_check,
        DROP CONSTRAINT IF EXISTS goals_withdrawal_fee_percent_check;

      -- Remove columns
      ALTER TABLE goals
        DROP COLUMN IF EXISTS management_fee_percent,
        DROP COLUMN IF EXISTS withdrawal_fee_percent;
    ''';

    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  Removed fee fields from goals table');
    } catch (e, stackTrace) {
      AppLogger.error(
        '  Failed to remove fee fields from goals',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}
