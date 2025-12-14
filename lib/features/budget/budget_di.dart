import '../../core/di/service_locator.dart';
import '../../shared/infrastructure/mongodb/mongodb_service.dart';
import 'data/datasources/budget_datasource.dart';
import 'data/datasources/mongodb/budget_datasource_mongodb.dart';
import 'data/repositories/budget_repository_impl.dart';
import 'domain/repositories/budget_repository.dart';

/// Setup budget management dependencies
void setupBudgetDependencies() {
  // Data sources (uses shared MongoDB service from tasks)
  locator.registerFactory<BudgetDataSource>(() {
    final mongoService = locator.get<MongoDBService>();
    return BudgetDataSourceMongoDB(mongoService);
  });

  // Repositories
  locator.registerFactory<BudgetRepository>(() {
    final dataSource = locator.get<BudgetDataSource>();
    return BudgetRepositoryImpl(dataSource);
  });
}
