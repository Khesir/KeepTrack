import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import '../migration.dart';

/// Creates buckets table for task categorization
class Migration043CreateBucketsTable extends Migration {
  @override
  String get version => '043_create_buckets_table';

  @override
  String get description => 'Create buckets table for task categorization';

  @override
  Future<void> up(SupabaseClient client) async {
    AppLogger.info('  🪣 Creating buckets table...');

    final sql = '''
      -- Create buckets table
      CREATE TABLE IF NOT EXISTS buckets (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        name TEXT NOT NULL,
        is_archive BOOLEAN DEFAULT FALSE NOT NULL,
        user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        
        -- Constraints
        CONSTRAINT buckets_name_user_id_unique UNIQUE(name, user_id),
        CONSTRAINT buckets_name_not_empty CHECK (length(trim(name)) > 0),
        CONSTRAINT buckets_name_length CHECK (length(name) <= 100)
      );

      -- Add indexes for performance
      CREATE INDEX IF NOT EXISTS idx_buckets_user_id ON buckets(user_id);
      CREATE INDEX IF NOT EXISTS idx_buckets_is_archive ON buckets(is_archive);
      CREATE INDEX IF NOT EXISTS idx_buckets_user_id_archive ON buckets(user_id, is_archive);

      -- Add RLS policies
      ALTER TABLE buckets ENABLE ROW LEVEL SECURITY;

      -- Users can view their own buckets
      CREATE POLICY "Users can view own buckets" ON buckets
        FOR SELECT USING (auth.uid() = user_id);

      -- Users can insert their own buckets
      CREATE POLICY "Users can insert own buckets" ON buckets
        FOR INSERT WITH CHECK (auth.uid() = user_id);

      -- Users can update their own buckets
      CREATE POLICY "Users can update own buckets" ON buckets
        FOR UPDATE USING (auth.uid() = user_id);

      -- Users can delete their own buckets
      CREATE POLICY "Users can delete own buckets" ON buckets
        FOR DELETE USING (auth.uid() = user_id);

      -- Trigger to update updated_at timestamp
      CREATE OR REPLACE FUNCTION update_buckets_updated_at()
        RETURNS TRIGGER AS \$\$
        BEGIN
          NEW.updated_at = CURRENT_TIMESTAMP;
          RETURN NEW;
        END;
        \$\$ LANGUAGE plpgsql;

      CREATE TRIGGER buckets_updated_at
        BEFORE UPDATE ON buckets
        FOR EACH ROW
        EXECUTE FUNCTION update_buckets_updated_at();
    ''';

    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Successfully created buckets table');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to create buckets table', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> down(SupabaseClient client) async {
    AppLogger.info('  🗑️ Dropping buckets table...');

    final sql = '''
      -- Drop trigger
      DROP TRIGGER IF EXISTS buckets_updated_at ON buckets;
      
      -- Drop function
      DROP FUNCTION IF EXISTS update_buckets_updated_at();
      
      -- Drop indexes
      DROP INDEX IF EXISTS idx_buckets_user_id;
      DROP INDEX IF EXISTS idx_buckets_is_archive;
      DROP INDEX IF EXISTS idx_buckets_user_id_archive;
      
      -- Drop table
      DROP TABLE IF EXISTS buckets;
    ''';

    try {
      await client.rpc('exec_sql', params: {'sql': sql});
      AppLogger.info('  ✅ Successfully dropped buckets table');
    } catch (e, stackTrace) {
      AppLogger.error('  ❌ Failed to drop buckets table', e, stackTrace);
      rethrow;
    }
  }
}