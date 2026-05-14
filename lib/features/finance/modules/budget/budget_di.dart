import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/features/finance/modules/budget/data/datasources/budget_category_datasource.dart';
import 'package:keep_track/features/finance/modules/budget/data/datasources/rest/budget_category_datasource_rest.dart';
import 'package:keep_track/features/finance/modules/budget/data/datasources/budget_datasource.dart';
import 'package:keep_track/features/finance/modules/budget/data/datasources/rest/budget_datasource_rest.dart';
import 'package:keep_track/features/finance/modules/budget/data/datasources/month_plan_datasource.dart';
import 'package:keep_track/features/finance/modules/budget/data/datasources/rest/month_plan_datasource_rest.dart';
import 'package:keep_track/features/finance/modules/budget/data/repositories/budget_repository_impl.dart';
import 'package:keep_track/features/finance/modules/budget/data/repositories/month_plan_repository_impl.dart';
import 'package:keep_track/features/finance/modules/budget/domain/repositories/budget_repository.dart';
import 'package:keep_track/features/finance/modules/budget/domain/repositories/month_plan_repository.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/controllers/budget_controller.dart';
import 'package:keep_track/features/finance/presentation/state/month_plan_controller.dart';

void setupBudgetDependencies() {
  // Data sources
  locator.registerLazySingleton<BudgetCategoryDataSource>(
    () => BudgetCategoryDataSourceRest(),
  );
  locator.registerFactory<BudgetDataSource>(() => BudgetDataSourceRest());
  locator.registerFactory<MonthPlanDataSource>(() => MonthPlanDataSourceRest());

  // Repositories
  locator.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(
      locator.get<BudgetDataSource>(),
      locator.get<BudgetCategoryDataSource>(),
    ),
  );
  locator.registerLazySingleton<MonthPlanRepository>(
    () => MonthPlanRepositoryImpl(locator.get<MonthPlanDataSource>()),
  );

  // Controllers
  locator.registerLazySingleton<BudgetController>(
    () => BudgetController(locator.get<BudgetRepository>()),
  );
  locator.registerLazySingleton<MonthPlanController>(
    () => MonthPlanController(locator.get<MonthPlanRepository>()),
  );
}
