/// Setup task management dependencies with Use Cases
/// This demonstrates Clean Architecture DI setup
library;

import 'package:persona_codex/shared/infrastructure/supabase/supabase_service.dart';

import '../../core/di/service_locator.dart';
import 'data/datasources/mongodb/task_datasource_supabase.dart';
import 'data/datasources/task_datasource.dart';
import 'data/repositories/task_repository_impl.dart';
import 'domain/repositories/task_repository.dart';
import 'domain/usecases/usecases.dart';
import 'presentation/state/task_list_controller_with_usecases.dart';

/// Setup task management dependencies following Clean Architecture
///
/// Dependency Order:
/// 1. Data Layer (DataSource, Repository)
/// 2. Domain Layer (Use Cases)
/// 3. Presentation Layer (Controllers)
void setupTasksDependencies() {
  // ============================================================
  // DATA LAYER
  // ============================================================

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

  // ============================================================
  // DOMAIN LAYER - USE CASES
  // ============================================================

  // Get tasks use cases
  locator.registerFactory<GetTasksUseCase>(() {
    return GetTasksUseCase(locator.get<TaskRepository>());
  });

  locator.registerFactory<GetFilteredTasksUseCase>(() {
    return GetFilteredTasksUseCase(locator.get<TaskRepository>());
  });

  // Create task use case
  locator.registerFactory<CreateTaskUseCase>(() {
    return CreateTaskUseCase(locator.get<TaskRepository>());
  });

  // Update task use case
  locator.registerFactory<UpdateTaskStatusUseCase>(() {
    return UpdateTaskStatusUseCase(locator.get<TaskRepository>());
  });

  // Delete task use case
  locator.registerFactory<DeleteTaskUseCase>(() {
    return DeleteTaskUseCase(locator.get<TaskRepository>());
  });

  // ============================================================
  // PRESENTATION LAYER - CONTROLLERS
  // ============================================================

  // Task list controller (uses use cases)
  locator.registerFactory<TaskListController>(() {
    return createTaskListController(locator);
  });

  // Alternative: Direct instantiation
  // locator.registerFactory<TaskListController>(() {
  //   return TaskListController(
  //     getTasksUseCase: locator.get<GetTasksUseCase>(),
  //     getFilteredTasksUseCase: locator.get<GetFilteredTasksUseCase>(),
  //     updateTaskStatusUseCase: locator.get<UpdateTaskStatusUseCase>(),
  //     deleteTaskUseCase: locator.get<DeleteTaskUseCase>(),
  //   );
  // });
}
