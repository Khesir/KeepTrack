import 'package:keep_track/core/cache/local_cache.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/features/finance/modules/budget/data/datasources/budget_category_datasource.dart';
import 'package:keep_track/features/finance/modules/budget/data/datasources/local/budget_category_datasource_local.dart';
import 'package:keep_track/features/finance/modules/budget/data/datasources/budget_datasource.dart';
import 'package:keep_track/features/finance/modules/budget/data/datasources/local/budget_datasource_local.dart';
import 'package:keep_track/features/finance/modules/budget/data/datasources/month_plan_datasource.dart';
import 'package:keep_track/features/finance/modules/budget/data/datasources/local/month_plan_datasource_local.dart';
import 'package:keep_track/features/finance/modules/budget/data/repositories/budget_repository_impl.dart';
import 'package:keep_track/features/finance/modules/budget/data/repositories/month_plan_repository_impl.dart';
import 'package:keep_track/features/finance/modules/budget/domain/repositories/budget_repository.dart';
import 'package:keep_track/features/finance/modules/budget/domain/repositories/month_plan_repository.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/controllers/budget_controller.dart';
import 'package:keep_track/features/finance/presentation/state/month_plan_controller.dart';

void setupBudgetDependencies() {
  locator.registerLazySingleton<BudgetCategoryDataSource>(
    () => BudgetCategoryDataSourceLocal(locator.get<LocalCache>()),
  );
  locator.registerFactory<BudgetDataSource>(
    () => BudgetDataSourceLocal(locator.get<LocalCache>()),
  );
  locator.registerFactory<MonthPlanDataSource>(
    () => MonthPlanDataSourceLocal(locator.get<LocalCache>()),
  );

  locator.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(
      locator.get<BudgetDataSource>(),
      locator.get<BudgetCategoryDataSource>(),
    ),
  );
  locator.registerLazySingleton<MonthPlanRepository>(
    () => MonthPlanRepositoryImpl(locator.get<MonthPlanDataSource>()),
  );

  locator.registerLazySingleton<BudgetController>(
    () => BudgetController(locator.get<BudgetRepository>()),
  );
  locator.registerLazySingleton<MonthPlanController>(
    () => MonthPlanController(locator.get<MonthPlanRepository>()),
  );
}
