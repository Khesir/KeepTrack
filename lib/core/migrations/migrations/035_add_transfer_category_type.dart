import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Migration 035 - Allow transfer category type
class Migration035AddTransferCategoryType extends Migration {
  @override
  String get version => '035_add_transfer_category_type';

  @override
  String get description =>
      'Extend finance_categories.type CHECK constraint to allow transfer';

  @override
  Future<void> up(SupabaseClient client) async {
    final sql = '''
-- Drop existing CHECK constraint
ALTER TABLE finance_categories
DROP CONSTRAINT IF EXISTS finance_categories_type_check;

-- Recreate CHECK constraint with transfer included
ALTER TABLE finance_categories
ADD CONSTRAINT finance_categories_type_check
CHECK (
  type = ANY (
    ARRAY[
      'income'::text,
      'expense'::text,
      'investment'::text,
      'savings'::text,
      'transfer'::text
    ]
  )
);
''';

    AppLogger.info(
      '  📝 Executing migration 035 - add transfer category type...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ transfer category type added successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        '  ❌ Failed to add transfer category type',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    final sql = '''
-- Rollback: remove transfer from CHECK constraint
ALTER TABLE finance_categories
DROP CONSTRAINT IF EXISTS finance_categories_type_check;

ALTER TABLE finance_categories
ADD CONSTRAINT finance_categories_type_check
CHECK (
  type = ANY (
    ARRAY[
      'income'::text,
      'expense'::text,
      'investment'::text,
      'savings'::text
    ]
  )
);
''';

    AppLogger.warning(
      '  ⚠️  Rolling back migration 035 - remove transfer category type...',
    );
    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ transfer category type removed successfully');
    } catch (e, stackTrace) {
      AppLogger.error(
        '  ❌ Failed to rollback transfer category type',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}
