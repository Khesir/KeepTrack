import 'package:supabase_flutter/supabase_flutter.dart';
import '../migration.dart';

class Migration005AddUserIdAndAuth extends Migration {
  @override
  String get version => '005_add_user_id_and_auth';

  @override
  String get description =>
      'Add user_id columns to all tables and update RLS policies for proper authentication';

  @override
  Future<void> up(SupabaseClient client) async {
    // Add user_id column to tasks table
    await client.rpc('exec_sql', params: {
      'sql': '''
        -- Add user_id to tasks
        ALTER TABLE tasks ADD COLUMN IF NOT EXISTS user_id UUID;

        -- Add foreign key constraint
        ALTER TABLE tasks
          ADD CONSTRAINT tasks_user_id_fkey
          FOREIGN KEY (user_id)
          REFERENCES auth.users(id)
          ON DELETE CASCADE;

        -- Create index for better query performance
        CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON tasks(user_id);
      '''
    });

    // Add user_id column to projects table
    await client.rpc('exec_sql', params: {
      'sql': '''
        -- Add user_id to projects
        ALTER TABLE projects ADD COLUMN IF NOT EXISTS user_id UUID;

        -- Add foreign key constraint
        ALTER TABLE projects
          ADD CONSTRAINT projects_user_id_fkey
          FOREIGN KEY (user_id)
          REFERENCES auth.users(id)
          ON DELETE CASCADE;

        -- Create index for better query performance
        CREATE INDEX IF NOT EXISTS idx_projects_user_id ON projects(user_id);
      '''
    });

    // Add user_id column to budgets table
    await client.rpc('exec_sql', params: {
      'sql': '''
        -- Add user_id to budgets
        ALTER TABLE budgets ADD COLUMN IF NOT EXISTS user_id UUID;

        -- Add foreign key constraint
        ALTER TABLE budgets
          ADD CONSTRAINT budgets_user_id_fkey
          FOREIGN KEY (user_id)
          REFERENCES auth.users(id)
          ON DELETE CASCADE;

        -- Create index for better query performance
        CREATE INDEX IF NOT EXISTS idx_budgets_user_id ON budgets(user_id);
      '''
    });

    // Add user_id column to accounts table
    await client.rpc('exec_sql', params: {
      'sql': '''
        -- Add user_id to accounts
        ALTER TABLE accounts ADD COLUMN IF NOT EXISTS user_id UUID;

        -- Add foreign key constraint
        ALTER TABLE accounts
          ADD CONSTRAINT accounts_user_id_fkey
          FOREIGN KEY (user_id)
          REFERENCES auth.users(id)
          ON DELETE CASCADE;

        -- Create index for better query performance
        CREATE INDEX IF NOT EXISTS idx_accounts_user_id ON accounts(user_id);
      '''
    });

    // Add user_id column to transactions table
    await client.rpc('exec_sql', params: {
      'sql': '''
        -- Add user_id to transactions
        ALTER TABLE transactions ADD COLUMN IF NOT EXISTS user_id UUID;

        -- Add foreign key constraint
        ALTER TABLE transactions
          ADD CONSTRAINT transactions_user_id_fkey
          FOREIGN KEY (user_id)
          REFERENCES auth.users(id)
          ON DELETE CASCADE;

        -- Create index for better query performance
        CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
      '''
    });

    // Update RLS policies for tasks
    await client.rpc('exec_sql', params: {
      'sql': '''
        -- Drop old permissive policy
        DROP POLICY IF EXISTS "Allow all for now" ON tasks;

        -- Create user-specific policies for tasks
        CREATE POLICY "Users can view their own tasks"
          ON tasks FOR SELECT
          USING (auth.uid() = user_id);

        CREATE POLICY "Users can insert their own tasks"
          ON tasks FOR INSERT
          WITH CHECK (auth.uid() = user_id);

        CREATE POLICY "Users can update their own tasks"
          ON tasks FOR UPDATE
          USING (auth.uid() = user_id)
          WITH CHECK (auth.uid() = user_id);

        CREATE POLICY "Users can delete their own tasks"
          ON tasks FOR DELETE
          USING (auth.uid() = user_id);
      '''
    });

    // Update RLS policies for projects
    await client.rpc('exec_sql', params: {
      'sql': '''
        -- Drop old permissive policy
        DROP POLICY IF EXISTS "Allow all for now" ON projects;

        -- Create user-specific policies for projects
        CREATE POLICY "Users can view their own projects"
          ON projects FOR SELECT
          USING (auth.uid() = user_id);

        CREATE POLICY "Users can insert their own projects"
          ON projects FOR INSERT
          WITH CHECK (auth.uid() = user_id);

        CREATE POLICY "Users can update their own projects"
          ON projects FOR UPDATE
          USING (auth.uid() = user_id)
          WITH CHECK (auth.uid() = user_id);

        CREATE POLICY "Users can delete their own projects"
          ON projects FOR DELETE
          USING (auth.uid() = user_id);
      '''
    });

    // Update RLS policies for budgets
    await client.rpc('exec_sql', params: {
      'sql': '''
        -- Drop old permissive policy
        DROP POLICY IF EXISTS "Allow all for now" ON budgets;

        -- Create user-specific policies for budgets
        CREATE POLICY "Users can view their own budgets"
          ON budgets FOR SELECT
          USING (auth.uid() = user_id);

        CREATE POLICY "Users can insert their own budgets"
          ON budgets FOR INSERT
          WITH CHECK (auth.uid() = user_id);

        CREATE POLICY "Users can update their own budgets"
          ON budgets FOR UPDATE
          USING (auth.uid() = user_id)
          WITH CHECK (auth.uid() = user_id);

        CREATE POLICY "Users can delete their own budgets"
          ON budgets FOR DELETE
          USING (auth.uid() = user_id);
      '''
    });

    // Update RLS policies for accounts
    await client.rpc('exec_sql', params: {
      'sql': '''
        -- Drop old permissive policy (if exists)
        DROP POLICY IF EXISTS "Allow all for now" ON accounts;
        DROP POLICY IF EXISTS "Users can manage their own accounts" ON accounts;

        -- Create user-specific policies for accounts
        CREATE POLICY "Users can view their own accounts"
          ON accounts FOR SELECT
          USING (auth.uid() = user_id);

        CREATE POLICY "Users can insert their own accounts"
          ON accounts FOR INSERT
          WITH CHECK (auth.uid() = user_id);

        CREATE POLICY "Users can update their own accounts"
          ON accounts FOR UPDATE
          USING (auth.uid() = user_id)
          WITH CHECK (auth.uid() = user_id);

        CREATE POLICY "Users can delete their own accounts"
          ON accounts FOR DELETE
          USING (auth.uid() = user_id);
      '''
    });

    // Update RLS policies for transactions
    await client.rpc('exec_sql', params: {
      'sql': '''
        -- Drop old permissive policy (if exists)
        DROP POLICY IF EXISTS "Allow all for now" ON transactions;
        DROP POLICY IF EXISTS "Users can manage their own transactions" ON transactions;

        -- Create user-specific policies for transactions
        CREATE POLICY "Users can view their own transactions"
          ON transactions FOR SELECT
          USING (auth.uid() = user_id);

        CREATE POLICY "Users can insert their own transactions"
          ON transactions FOR INSERT
          WITH CHECK (auth.uid() = user_id);

        CREATE POLICY "Users can update their own transactions"
          ON transactions FOR UPDATE
          USING (auth.uid() = user_id)
          WITH CHECK (auth.uid() = user_id);

        CREATE POLICY "Users can delete their own transactions"
          ON transactions FOR DELETE
          USING (auth.uid() = user_id);
      '''
    });
  }
}
