import 'package:persona_codex/shared/infrastructure/mongodb/mongodb_service.dart';

import '../../core/di/service_locator.dart';
import 'data/datasources/mongodb/task_datasource_mongodb.dart';
import 'data/datasources/task_datasource.dart';
import 'data/repositories/task_repository_impl.dart';
import 'domain/repositories/task_repository.dart';

/// Setup task management dependencies
void setupTasksDependencies() {
  // Data sources
  locator.registerFactory<TaskDataSource>(() {
    final mongoService = locator.get<MongoDBService>();
    return TaskDataSourceMongoDB(mongoService);
  });

  // Repositories
  locator.registerFactory<TaskRepository>(() {
    final dataSource = locator.get<TaskDataSource>();
    return TaskRepositoryImpl(dataSource);
  });
}
