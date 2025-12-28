/// Setup task management dependencies
/// Only registers data layer (datasources and repositories)
/// Use cases and controllers are instantiated directly without DI
library;

import 'package:persona_codex/features/tasks/presentation/state/task_controller.dart';
import 'package:persona_codex/shared/infrastructure/supabase/supabase_service.dart';

import '../../core/di/service_locator.dart';
import 'modules/tasks/data/datasources/mongodb/task_datasource_supabase.dart';
import 'modules/tasks/data/datasources/task_datasource.dart';
import 'modules/tasks/data/repositories/task_repository_impl.dart';
import 'modules/tasks/domain/repositories/task_repository.dart';
import 'modules/projects/data/datasources/supabase/project_datasource_supabase.dart';
import 'modules/projects/data/datasources/project_datasource.dart';
import 'modules/projects/data/repositories/project_repository_impl.dart';
import 'modules/projects/domain/repositories/project_repository.dart';
import 'presentation/state/project_controller.dart';

/// Setup task management dependencies
void setupTasksDependencies() {
  // Data sources
  locator.registerFactory<TaskDataSource>(() {
    final supabaseService = locator.get<SupabaseService>();
    return TaskDataSourceSupabase(supabaseService);
  });

  locator.registerFactory<ProjectDataSource>(() {
    final supabaseService = locator.get<SupabaseService>();
    return ProjectDataSourceSupabase(supabaseService);
  });

  // Repositories
  locator.registerFactory<TaskRepository>(() {
    final dataSource = locator.get<TaskDataSource>();
    return TaskRepositoryImpl(dataSource);
  });

  locator.registerFactory<ProjectRepository>(() {
    final dataSource = locator.get<ProjectDataSource>();
    return ProjectRepositoryImpl(dataSource);
  });

  locator.registerFactory<TaskController>(() {
    final repo = locator.get<TaskRepository>();
    return TaskController(repo);
  });

  locator.registerFactory<ProjectController>(() {
    final repo = locator.get<ProjectRepository>();
    return ProjectController(repo);
  });
}
