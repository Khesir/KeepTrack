/// Setup task management dependencies
/// Only registers data layer (datasources and repositories)
/// Use cases and controllers are instantiated directly without DI
library;

import 'package:persona_codex/shared/infrastructure/supabase/supabase_service.dart';

import '../../core/di/service_locator.dart';
import 'data/datasources/mongodb/task_datasource_supabase.dart';
import 'data/datasources/task_datasource.dart';
import 'data/repositories/task_repository_impl.dart';
import 'domain/repositories/task_repository.dart';

/// Setup task management dependencies
///
/// Dependency Order:
/// 1. Data Layer (DataSource, Repository)
/// Note: Use cases and controllers are NOT registered in DI
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
}
