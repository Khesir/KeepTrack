import 'package:persona_codex/features/projects/data/datasources/mongodb/project_datasource_mongodb.dart';
import 'package:persona_codex/features/projects/data/datasources/project_datasource.dart';
import 'package:persona_codex/features/projects/data/repositories/project_repository_impl.dart';
import 'package:persona_codex/features/projects/domain/repositories/project_repository.dart';
import 'package:persona_codex/shared/infrastructure/mongodb/mongodb_service.dart';

import '../../core/di/service_locator.dart';
import 'data/datasources/mongodb/task_datasource_mongodb.dart';
import 'data/datasources/task_datasource.dart';
import 'data/repositories/task_repository_impl.dart';
import 'domain/repositories/task_repository.dart';

/// Setup task management dependencies
void setupTasksDependencies() {
  // Core MongoDB service
  locator.registerLazySingleton<MongoDBService>(() {
    final service = MongoDBService(
      connectionString: 'mongodb://localhost:27017',
      databaseName: 'personal_codex',
    );
    // Connect on first access
    service.connect();
    return service;
  });

  // Data sources
  locator.registerFactory<TaskDataSource>(() {
    final mongoService = locator.get<MongoDBService>();
    return TaskDataSourceMongoDB(mongoService);
  });

  locator.registerFactory<ProjectDataSource>(() {
    final mongoService = locator.get<MongoDBService>();
    return ProjectDataSourceMongoDB(mongoService);
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
}
