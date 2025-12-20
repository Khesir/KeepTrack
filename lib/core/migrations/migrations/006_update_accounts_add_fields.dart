import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:persona_codex/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 006 - Add new fields to accounts table
class Migration006UpdateAccountsAddFields extends Migration {
  @override
  String get version => '006_update_accounts_add_fields';

  @override
  String get description => 'Add account_type, color_hex, icon_code_point, and is_active fields to accounts table';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Add new columns to accounts table
ALTER TABLE accounts
  ADD COLUMN IF NOT EXISTS account_type TEXT,
  ADD COLUMN IF NOT EXISTS color_hex TEXT,
  ADD COLUMN IF NOT EXISTS icon_code_point TEXT,
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;

-- Rename old color column to color_hex if it exists
DO \$\$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'accounts' AND column_name = 'color'
  ) THEN
    -- Migrate data from old color column to color_hex
    UPDATE accounts SET color_hex = color WHERE color IS NOT NULL;
    -- Drop old column
    ALTER TABLE accounts DROP COLUMN color;
  END IF;
END \$\$;

-- Create index for account type
CREATE INDEX IF NOT EXISTS idx_accounts_type ON accounts(account_type);
CREATE INDEX IF NOT EXISTS idx_accounts_active ON accounts(is_active);
''';

    AppLogger.info('  📝 Executing migration 006 - update accounts table...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Accounts table updated successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to update accounts table', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- Remove new columns from accounts table
ALTER TABLE accounts
  DROP COLUMN IF EXISTS account_type,
  DROP COLUMN IF EXISTS color_hex,
  DROP COLUMN IF EXISTS icon_code_point,
  DROP COLUMN IF EXISTS is_active;

-- Drop indexes
DROP INDEX IF EXISTS idx_accounts_type;
DROP INDEX IF EXISTS idx_accounts_active;
''';

    AppLogger.warning('  ⚠️  Rolling back migration 006...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Accounts table rollback successful');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to rollback accounts update', e, stackTrace);
      rethrow;
    }
  }
}
