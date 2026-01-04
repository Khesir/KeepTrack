import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 016 - Update accounts table id to UUID
class Migration016UpdateAccountsToUUID extends Migration {
  @override
  String get version => '016_update_accounts_to_uuid';

  @override
  String get description =>
      'Update accounts table: change id from TEXT to UUID';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Create a new accounts table with UUID id
CREATE TABLE accounts_new (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  balance NUMERIC DEFAULT 0,
  bank_account_number TEXT,
  account_type TEXT,
  color_hex TEXT,
  icon_code_point TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_archived BOOLEAN DEFAULT FALSE
);

-- Copy data from old table, converting text IDs to UUIDs
INSERT INTO accounts_new (
  id,
  name,
  balance,
  bank_account_number,
  account_type,
  color_hex,
  icon_code_point,
  is_active,
  user_id,
  created_at,
  updated_at,
  is_archived
)
SELECT 
  CASE 
    WHEN id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\$' 
    THEN id::UUID 
    ELSE gen_random_uuid() 
  END as id,
  name,
  balance,
  bank_account_number,
  account_type,
  color_hex,
  icon_code_point,
  COALESCE(is_active, TRUE) as is_active,
  user_id,
  created_at,
  updated_at,
  is_archived
FROM accounts
WHERE user_id IS NOT NULL;

-- Drop old table and rename new one
DROP TABLE accounts CASCADE;
ALTER TABLE accounts_new RENAME TO accounts;

-- Recreate indexes
CREATE INDEX idx_accounts_archived ON accounts(is_archived);
CREATE INDEX idx_accounts_user_id ON accounts(user_id);
CREATE INDEX idx_accounts_type ON accounts(account_type);
CREATE INDEX idx_accounts_active ON accounts(is_active);

-- Enable Row Level Security
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;

-- Drop old policies if they exist
DROP POLICY IF EXISTS "Users can view their own accounts" ON accounts;
DROP POLICY IF EXISTS "Users can insert their own accounts" ON accounts;
DROP POLICY IF EXISTS "Users can update their own accounts" ON accounts;
DROP POLICY IF EXISTS "Users can delete their own accounts" ON accounts;

-- RLS Policy: Users can only see their own accounts
CREATE POLICY "Users can view their own accounts"
  ON accounts
  FOR SELECT
  USING (auth.uid() = user_id);

-- RLS Policy: Users can insert their own accounts
CREATE POLICY "Users can insert their own accounts"
  ON accounts
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can update their own accounts
CREATE POLICY "Users can update their own accounts"
  ON accounts
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can delete their own accounts
CREATE POLICY "Users can delete their own accounts"
  ON accounts
  FOR DELETE
  USING (auth.uid() = user_id);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS \$\$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
\$\$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_accounts_updated_at ON accounts;
CREATE TRIGGER update_accounts_updated_at
  BEFORE UPDATE ON accounts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
''';

    AppLogger.info('  📝 Executing migration 016 - update accounts to UUID...');
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Accounts table updated to UUID successfully');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to update accounts to UUID', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- Drop trigger
DROP TRIGGER IF EXISTS update_accounts_updated_at ON accounts;

-- Create old structure
CREATE TABLE accounts_old (
  id TEXT PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  balance NUMERIC DEFAULT 0,
  bank_account_number TEXT,
  account_type TEXT,
  color_hex TEXT,
  icon_code_point TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  user_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_archived BOOLEAN DEFAULT FALSE
);

-- Copy data back
INSERT INTO accounts_old
SELECT 
  id::TEXT,
  name,
  balance,
  bank_account_number,
  account_type,
  color_hex,
  icon_code_point,
  is_active,
  user_id,
  created_at,
  updated_at,
  is_archived
FROM accounts;

-- Drop new table and rename old one
DROP TABLE accounts CASCADE;
ALTER TABLE accounts_old RENAME TO accounts;

-- Recreate indexes
CREATE INDEX idx_accounts_archived ON accounts(is_archived);
CREATE INDEX idx_accounts_user_id ON accounts(user_id);
CREATE INDEX idx_accounts_type ON accounts(account_type);
CREATE INDEX idx_accounts_active ON accounts(is_active);
''';

    AppLogger.warning(
      '  ⚠️  Rolling back migration 016 - revert accounts structure...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Accounts structure reverted successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        '  ❌ Failed to rollback accounts structure',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}
