import 'package:keep_track/core/cache/local_cache.dart';
import 'package:keep_track/features/finance/modules/account/data/datasources/account_datasource.dart';
import 'package:keep_track/features/finance/modules/account/data/datasources/rest/account_datasource_rest.dart';
import 'package:keep_track/features/finance/modules/account/data/repositories/account_repository_impl.dart';
import 'package:keep_track/features/finance/modules/account/domain/repositories/account_repository.dart';
import 'package:keep_track/features/finance/modules/budget/data/datasources/budget_category_datasource.dart';
import 'package:keep_track/features/finance/modules/budget/data/datasources/rest/budget_category_datasource_rest.dart';
import 'package:keep_track/features/finance/modules/budget/data/datasources/month_plan_datasource.dart';
import 'package:keep_track/features/finance/modules/budget/data/datasources/rest/month_plan_datasource_rest.dart';
import 'package:keep_track/features/finance/modules/budget/data/repositories/month_plan_repository_impl.dart';
import 'package:keep_track/features/finance/modules/budget/domain/repositories/month_plan_repository.dart';
import 'package:keep_track/features/finance/modules/finance_category/data/datasources/finance_category_datasource.dart';
import 'package:keep_track/features/finance/modules/finance_category/data/datasources/rest/finance_category_datasource_rest.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/repositories/finance_repository.dart';
import 'package:keep_track/features/finance/presentation/state/budget_controller.dart';

import '../../core/di/service_locator.dart';
import 'modules/budget/data/datasources/budget_datasource.dart';
import 'modules/budget/data/datasources/rest/budget_datasource_rest.dart';
import 'modules/budget/data/repositories/budget_repository_impl.dart';
import 'modules/budget/domain/repositories/budget_repository.dart';
import 'modules/finance_category/data/repositories/finance_repository_impl.dart';
import 'modules/transaction/data/datasources/transaction_datasource.dart';
import 'modules/transaction/data/datasources/rest/transaction_datasource_rest.dart';
import 'modules/transaction/data/repositories/transaction_repository_impl.dart';
import 'modules/transaction/domain/repositories/transaction_repository.dart';
import 'modules/goal/data/datasources/goal_datasource.dart';
import 'modules/goal/data/datasources/rest/goal_datasource_rest.dart';
import 'modules/goal/data/repositories/goal_repository_impl.dart';
import 'modules/goal/domain/repositories/goal_repository.dart';
import 'modules/debt/data/datasources/debt_datasource.dart';
import 'modules/debt/data/datasources/rest/debt_datasource_rest.dart';
import 'modules/debt/data/repositories/debt_repository_impl.dart';
import 'modules/debt/domain/repositories/debt_repository.dart';
import 'modules/planned_payment/data/datasources/planned_payment_datasource.dart';
import 'modules/planned_payment/data/datasources/rest/planned_payment_datasource_rest.dart';
import 'modules/planned_payment/data/repositories/planned_payment_repository_impl.dart';
import 'modules/planned_payment/domain/repositories/planned_payment_repository.dart';
import 'presentation/state/account_controller.dart';
import 'presentation/state/month_plan_controller.dart';
import 'presentation/state/finance_category_controller.dart';
import 'presentation/state/transaction_cache.dart';
import 'presentation/state/transaction_controller.dart';
import 'presentation/state/goal_controller.dart';
import 'presentation/state/debt_controller.dart';
import 'presentation/state/planned_payment_controller.dart';
import 'data/services/finance_initialization_service.dart';

/// Setup finance management dependencies
void setupFinanceDependencies() {
  final cache = locator.get<LocalCache>();

  // Data sources
  locator.registerFactory<AccountDataSource>(() => AccountDataSourceRest());
  locator.registerFactory<TransactionDataSource>(() => TransactionDataSourceRest());
  locator.registerFactory<GoalDataSource>(() => GoalDataSourceRest());
  locator.registerFactory<DebtDataSource>(() => DebtDataSourceRest());
  locator.registerFactory<PlannedPaymentDataSource>(() => PlannedPaymentDataSourceRest());
  locator.registerFactory<FinanceCategoryDataSource>(() => FinanceCategoryDataSourceRest());
  locator.registerLazySingleton<BudgetCategoryDataSource>(() => BudgetCategoryDataSourceRest());
  locator.registerFactory<BudgetDataSource>(() => BudgetDataSourceRest());
  locator.registerFactory<MonthPlanDataSource>(() => MonthPlanDataSourceRest());

  // Repositories
  locator.registerFactory<FinanceCategoryRepository>(() {
    return FinanceCategoryRepositoryImpl(locator.get<FinanceCategoryDataSource>());
  });
  locator.registerLazySingleton<BudgetRepository>(() => BudgetRepositoryImpl(
    locator.get<BudgetDataSource>(),
    locator.get<BudgetCategoryDataSource>(),
  ));
  locator.registerLazySingleton<MonthPlanRepository>(
    () => MonthPlanRepositoryImpl(locator.get<MonthPlanDataSource>()),
  );
  locator.registerFactory<AccountRepository>(() => AccountRepositoryImpl(
    locator.get<AccountDataSource>(),
    cache,
  ));
  locator.registerFactory<TransactionRepository>(() => TransactionRepositoryImpl(
    locator.get<TransactionDataSource>(),
    locator.get<AccountRepository>(),
  ));
  locator.registerFactory<GoalRepository>(() {
    return GoalRepositoryImpl(locator.get<GoalDataSource>());
  });
  locator.registerFactory<DebtRepository>(() {
    return DebtRepositoryImpl(locator.get<DebtDataSource>());
  });
  locator.registerFactory<PlannedPaymentRepository>(() {
    return PlannedPaymentRepositoryImpl(locator.get<PlannedPaymentDataSource>());
  });

  // Services
  locator.registerFactory<FinanceInitializationService>(() {
    return FinanceInitializationService(locator.get<FinanceCategoryRepository>());
  });

  // Controllers
  locator.registerLazySingleton<TransactionCache>(() => TransactionCache());

  locator.registerFactory<AccountController>(() {
    return AccountController(locator.get<AccountRepository>());
  });
  locator.registerFactory<TransactionController>(() {
    return TransactionController(
      locator.get<TransactionRepository>(),
      locator.get<TransactionCache>(),
      onMutated: () =>
          locator.get<BudgetController>().refreshBudgetsWithSpentAmounts(),
    );
  });
  locator.registerFactory<GoalController>(() {
    return GoalController(locator.get<GoalRepository>());
  });
  locator.registerFactory<DebtController>(() {
    return DebtController(locator.get<DebtRepository>());
  });
  locator.registerFactory<PlannedPaymentController>(() {
    return PlannedPaymentController(locator.get<PlannedPaymentRepository>());
  });
  locator.registerFactory<FinanceCategoryController>(() {
    return FinanceCategoryController(locator.get<FinanceCategoryRepository>());
  });
  locator.registerLazySingleton<BudgetController>(() {
    return BudgetController(locator.get<BudgetRepository>());
  });
  locator.registerLazySingleton<MonthPlanController>(() {
    return MonthPlanController(locator.get<MonthPlanRepository>());
  });
}
