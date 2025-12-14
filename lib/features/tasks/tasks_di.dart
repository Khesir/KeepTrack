import 'package:persona_codex/shared/infrastructure/supabase/supabase_service.dart';

import '../../core/di/service_locator.dart';
import 'data/datasources/mongodb/task_datasource_supabase.dart';
import 'data/datasources/task_datasource.dart';
import 'data/repositories/task_repository_impl.dart';
import 'domain/repositories/task_repository.dart';

/// Setup task management dependencies
void setupTasksDependencies() {
  // Data sources
  locator.registerFactory<TaskDataSource>(() {
    final supabaseService = locator.get<SupabaseService>();
    return TaskDataSourceSupabase(supabaseService);
  });

  // Repositories
  locator.registerFactory<TaskRepository>(() {
    final dataSource = locator.get<TaskDataSource>();
    return TaskRepositoryImpl(dataSource);
  });
}
