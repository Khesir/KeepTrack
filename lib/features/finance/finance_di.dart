import 'package:persona_codex/features/finance/data/datasources/account_datasource.dart';
import 'package:persona_codex/features/finance/data/datasources/supabase/account_datasource_supabase.dart';
import 'package:persona_codex/features/finance/data/repositories/account_repository_impl.dart';
import 'package:persona_codex/features/finance/domain/repositories/account_repository.dart';

import '../../core/di/service_locator.dart';
import '../../shared/infrastructure/supabase/supabase_service.dart';
import 'data/datasources/budget_datasource.dart';
import 'data/datasources/supabase/budget_datasource_supabase.dart';
import 'data/repositories/budget_repository_impl.dart';
import 'domain/repositories/budget_repository.dart';

/// Setup budget management dependencies
void setupBudgetDependencies() {
  // Data sources (uses shared Supabase service)
  locator.registerFactory<BudgetDataSource>(() {
    final supabaseService = locator.get<SupabaseService>();
    return BudgetDataSourceSupabase(supabaseService);
  });
  locator.registerFactory<AccountDataSource>(() {
    final supabaseService = locator.get<SupabaseService>();
    return AccountDataSourceSupabase(supabaseService);
  });

  // Repositories
  locator.registerFactory<BudgetRepository>(() {
    final dataSource = locator.get<BudgetDataSource>();
    return BudgetRepositoryImpl(dataSource);
  });
  locator.registerFactory<AccountRepository>(() {
    final dataSource = locator.get<AccountDataSource>();
    return AccountRepositoryImpl(dataSource);
  });
}
