/// Setup task management dependencies
/// Only registers data layer (datasources and repositories)
/// Use cases and controllers are instantiated directly without DI
library;

import 'package:keep_track/features/profile/presentation/state/task_activity_controller.dart';
import 'package:keep_track/features/tasks/data/sevices/bucket_initialization_service.dart';
import 'package:keep_track/features/tasks/modules/buckets/data/datasources/bucket_datasource.dart';
import 'package:keep_track/features/tasks/modules/buckets/data/datasources/supabase/bucket_datasource_supabase.dart';
import 'package:keep_track/features/tasks/modules/buckets/data/repositories/bucket_repository_impl.dart';
import 'package:keep_track/features/tasks/modules/buckets/domain/repositories/bucket_repository.dart';
import 'package:keep_track/features/tasks/presentation/state/bucket_controller.dart';
import 'package:keep_track/features/tasks/presentation/state/task_controller.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';

import '../../core/di/service_locator.dart';
import 'modules/tasks/data/datasources/supabase/task_datasource_supabase.dart';
import 'modules/tasks/data/datasources/task_datasource.dart';
import 'modules/tasks/data/repositories/task_repository_impl.dart';
import 'modules/tasks/domain/repositories/task_repository.dart';
import 'modules/projects/data/datasources/supabase/project_datasource_supabase.dart';
import 'modules/projects/data/datasources/project_datasource.dart';
import 'modules/projects/data/repositories/project_repository_impl.dart';
import 'modules/projects/domain/repositories/project_repository.dart';
import 'modules/pomodoro/data/datasources/pomodoro_session_datasource.dart';
import 'modules/pomodoro/data/datasources/supabase/pomodoro_session_datasource_supabase.dart';
import 'modules/pomodoro/data/repositories/pomodoro_session_repository_impl.dart';
import 'modules/pomodoro/domain/repositories/pomodoro_session_repository.dart';
import 'presentation/state/project_controller.dart';
import 'presentation/state/pomodoro_session_controller.dart';

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

  locator.registerFactory<TaskActivityController>(() {
    final repo = locator.get<TaskRepository>();
    return TaskActivityController(repo);
  });

  // Pomodoro data sources
  locator.registerFactory<PomodoroSessionDataSource>(() {
    final supabaseService = locator.get<SupabaseService>();
    return PomodoroSessionDataSourceSupabase(supabaseService);
  });

  // Pomodoro repositories
  locator.registerFactory<PomodoroSessionRepository>(() {
    final dataSource = locator.get<PomodoroSessionDataSource>();
    return PomodoroSessionRepositoryImpl(dataSource);
  });

  // Pomodoro controllers - use singleton so nav indicator and timer share state
  locator.registerLazySingleton<PomodoroSessionController>(() {
    final repo = locator.get<PomodoroSessionRepository>();
    final supabaseService = locator.get<SupabaseService>();
    return PomodoroSessionController(repo, supabaseService.userId!);
  });

  locator.registerFactory<BucketDataSource>(() {
    final supabaseService = locator.get<SupabaseService>();
    return BucketDataSourceSupabase(supabaseService);
  });

  locator.registerFactory<BucketRepository>(() {
    final dataSource = locator.get<BucketDataSource>();
    return BucketRepositoryImpl(dataSource);
  });

  locator.registerFactory<BucketInitializationService>(() {
    final bucketRepository = locator.get<BucketRepository>();
    return BucketInitializationService(bucketRepository);
  });
  locator.registerFactory<BucketController>(() {
    final bucketRepository = locator.get<BucketRepository>();
    return BucketController(bucketRepository);
  });
}
