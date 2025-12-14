import '../../core/di/service_locator.dart';
import '../../shared/infrastructure/mongodb/mongodb_service.dart';
import 'data/datasources/mongodb/project_datasource_mongodb.dart';
import 'data/datasources/project_datasource.dart';
import 'data/repositories/project_repository_impl.dart';
import 'domain/repositories/project_repository.dart';

/// Setup project management dependencies
void setupProjectsDependencies() {
  // Data sources (uses shared MongoDB service)
  locator.registerFactory<ProjectDataSource>(() {
    final mongoService = locator.get<MongoDBService>();
    return ProjectDataSourceMongoDB(mongoService);
  });

  // Repositories
  locator.registerFactory<ProjectRepository>(() {
    final dataSource = locator.get<ProjectDataSource>();
    return ProjectRepositoryImpl(dataSource);
  });
}
