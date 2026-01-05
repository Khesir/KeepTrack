import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 036 - Add trigger to handle transfer transactions
class Migration036AddTransferTransactionTrigger extends Migration {
  @override
  String get version => '036_add_transfer_transaction_trigger';

  @override
  String get description =>
      'Add trigger to handle transfer transactions - add amount to to_account_id';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Function to handle transfer transaction balance updates
CREATE OR REPLACE FUNCTION handle_transfer_transaction()
RETURNS TRIGGER AS \$\$
BEGIN
  -- Only process transfer transactions
  IF NEW.type = 'transfer' THEN
    -- Validate that both accounts exist
    IF NEW.account_id IS NULL OR NEW.to_account_id IS NULL THEN
      RAISE EXCEPTION 'Transfer transactions require both account_id and to_account_id';
    END IF;

    -- Validate accounts are different
    IF NEW.account_id = NEW.to_account_id THEN
      RAISE EXCEPTION 'Cannot transfer to the same account';
    END IF;

    -- Add to destination account (amount only)
    UPDATE accounts
    SET balance = balance + NEW.amount,
        updated_at = NOW()
    WHERE id = NEW.to_account_id;
  END IF;

  RETURN NEW;
END;
\$\$ LANGUAGE plpgsql;

-- Create trigger for INSERT
CREATE TRIGGER trigger_handle_transfer_transaction
  AFTER INSERT ON transactions
  FOR EACH ROW
  EXECUTE FUNCTION handle_transfer_transaction();
''';

    AppLogger.info(
      '  📝 Executing migration 036 - add transfer transaction trigger...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Transfer transaction trigger added successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        '  ❌ Failed to add transfer transaction trigger',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
DROP TRIGGER IF EXISTS trigger_handle_transfer_transaction ON transactions;
DROP FUNCTION IF EXISTS handle_transfer_transaction();
''';

    AppLogger.warning(
      '  ⚠️  Rolling back migration 036 - remove transfer transaction trigger...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Transfer transaction trigger removed successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        '  ❌ Failed to rollback transfer transaction trigger',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}
