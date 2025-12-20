import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:persona_codex/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 009 - Create planned_payments table for recurring payments
class Migration009CreatePlannedPaymentsTable extends Migration {
  @override
  String get version => '009_create_planned_payments_table';

  @override
  String get description => 'Create planned_payments table for tracking recurring and scheduled payments';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Create planned_payments table
CREATE TABLE IF NOT EXISTS planned_payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  payee TEXT NOT NULL,
  amount NUMERIC NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('bills', 'subscriptions', 'insurance', 'loan', 'rent', 'utilities', 'other')),
  frequency TEXT NOT NULL CHECK (frequency IN ('daily', 'weekly', 'biweekly', 'monthly', 'quarterly', 'yearly')),
  next_payment_date TIMESTAMP WITH TIME ZONE NOT NULL,
  last_payment_date TIMESTAMP WITH TIME ZONE,
  account_id TEXT REFERENCES accounts(id) ON DELETE SET NULL,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'paused', 'cancelled')),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_planned_payments_user ON planned_payments(user_id);
CREATE INDEX IF NOT EXISTS idx_planned_payments_account ON planned_payments(account_id);
CREATE INDEX IF NOT EXISTS idx_planned_payments_status ON planned_payments(status);
CREATE INDEX IF NOT EXISTS idx_planned_payments_next_date ON planned_payments(next_payment_date);
CREATE INDEX IF NOT EXISTS idx_planned_payments_category ON planned_payments(category);

-- Add RLS policies
ALTER TABLE planned_payments ENABLE ROW LEVEL SECURITY;

-- Users can only see their own planned payments
CREATE POLICY planned_payments_select_policy ON planned_payments
  FOR SELECT USING (auth.uid() = user_id);

-- Users can only insert their own planned payments
CREATE POLICY planned_payments_insert_policy ON planned_payments
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can only update their own planned payments
CREATE POLICY planned_payments_update_policy ON planned_payments
  FOR UPDATE USING (auth.uid() = user_id);

-- Users can only delete their own planned payments
CREATE POLICY planned_payments_delete_policy ON planned_payments
  FOR DELETE USING (auth.uid() = user_id);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_planned_payments_updated_at()
RETURNS TRIGGER AS \$\$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
\$\$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_planned_payments_updated_at
  BEFORE UPDATE ON planned_payments
  FOR EACH ROW
  EXECUTE FUNCTION update_planned_payments_updated_at();
''';

    AppLogger.info('  📝 Executing migration 009 - create planned_payments table...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Planned payments table created successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to create planned_payments table', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- Drop trigger
DROP TRIGGER IF EXISTS trigger_update_planned_payments_updated_at ON planned_payments;
DROP FUNCTION IF EXISTS update_planned_payments_updated_at();

-- Drop policies
DROP POLICY IF EXISTS planned_payments_select_policy ON planned_payments;
DROP POLICY IF EXISTS planned_payments_insert_policy ON planned_payments;
DROP POLICY IF EXISTS planned_payments_update_policy ON planned_payments;
DROP POLICY IF EXISTS planned_payments_delete_policy ON planned_payments;

-- Drop indexes
DROP INDEX IF EXISTS idx_planned_payments_user;
DROP INDEX IF EXISTS idx_planned_payments_account;
DROP INDEX IF EXISTS idx_planned_payments_status;
DROP INDEX IF EXISTS idx_planned_payments_next_date;
DROP INDEX IF EXISTS idx_planned_payments_category;

-- Drop table
DROP TABLE IF EXISTS planned_payments CASCADE;
''';

    AppLogger.warning('  ⚠️  Rolling back migration 009 - drop planned_payments table...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Planned payments table dropped successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to rollback planned_payments table', e, stackTrace);
      rethrow;
    }
  }
}
