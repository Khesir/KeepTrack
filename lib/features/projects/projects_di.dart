import '../../core/di/service_locator.dart';
import '../../shared/infrastructure/supabase/supabase_service.dart';
import 'data/datasources/supabase/project_datasource_supabase.dart';
import 'data/datasources/project_datasource.dart';
import 'data/repositories/project_repository_impl.dart';
import 'domain/repositories/project_repository.dart';

/// Setup project management dependencies
void setupProjectsDependencies() {
  // Data sources (uses shared Supabase service)
  locator.registerFactory<ProjectDataSource>(() {
    final supabaseService = locator.get<SupabaseService>();
    return ProjectDataSourceSupabase(supabaseService);
  });

  // Repositories
  locator.registerFactory<ProjectRepository>(() {
    final dataSource = locator.get<ProjectDataSource>();
    return ProjectRepositoryImpl(dataSource);
  });
}
