import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 010 - Add financial integration fields to tasks table
class Migration010AddTaskFinancialFields extends Migration {
  @override
  String get version => '010_add_task_financial_fields';

  @override
  String get description => 'Add financial integration fields to tasks table for money-related tasks';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Add financial integration columns to tasks table
ALTER TABLE tasks
  ADD COLUMN IF NOT EXISTS is_money_related BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS expected_amount NUMERIC,
  ADD COLUMN IF NOT EXISTS transaction_type TEXT CHECK (transaction_type IN ('income', 'expense')),
  ADD COLUMN IF NOT EXISTS finance_category_id UUID,
  ADD COLUMN IF NOT EXISTS actual_transaction_id UUID;

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_tasks_is_money_related ON tasks(is_money_related);
CREATE INDEX IF NOT EXISTS idx_tasks_finance_category_id ON tasks(finance_category_id);
CREATE INDEX IF NOT EXISTS idx_tasks_actual_transaction_id ON tasks(actual_transaction_id);
''';

    AppLogger.info('  📝 Executing migration 010 - add financial fields to tasks...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Financial fields added to tasks table successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to add financial fields to tasks', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- Remove indexes
DROP INDEX IF EXISTS idx_tasks_is_money_related;
DROP INDEX IF EXISTS idx_tasks_finance_category_id;
DROP INDEX IF EXISTS idx_tasks_actual_transaction_id;

-- Remove financial integration columns from tasks table
ALTER TABLE tasks
  DROP COLUMN IF EXISTS is_money_related,
  DROP COLUMN IF EXISTS expected_amount,
  DROP COLUMN IF EXISTS transaction_type,
  DROP COLUMN IF EXISTS finance_category_id,
  DROP COLUMN IF EXISTS actual_transaction_id;
''';

    AppLogger.warning('  ⚠️  Rolling back migration 010 - remove financial fields from tasks...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Financial fields removed from tasks table successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to rollback financial fields from tasks', e, stackTrace);
      rethrow;
    }
  }
}
