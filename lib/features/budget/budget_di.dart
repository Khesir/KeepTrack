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

  // Repositories
  locator.registerFactory<BudgetRepository>(() {
    final dataSource = locator.get<BudgetDataSource>();
    return BudgetRepositoryImpl(dataSource);
  });
}
