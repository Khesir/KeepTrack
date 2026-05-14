import 'package:keep_track/features/finance/modules/budget/budget_di.dart';
import 'package:keep_track/features/finance/modules/savings/data/datasources/rest/savings_datasource_rest.dart';
import 'package:keep_track/features/finance/modules/savings/data/datasources/savings_datasource.dart';
import 'package:keep_track/features/finance/modules/savings/data/repositories/savings_repository_impl.dart';
import 'package:keep_track/features/finance/modules/savings/domain/repositories/savings_repository.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/controllers/budget_controller.dart';
import 'package:keep_track/features/finance/modules/finance_category/data/datasources/finance_category_datasource.dart';
import 'package:keep_track/features/finance/modules/finance_category/data/datasources/rest/finance_category_datasource_rest.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/repositories/finance_repository.dart';

import '../../core/di/service_locator.dart';
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
import 'presentation/state/finance_category_controller.dart';
import 'presentation/state/savings_controller.dart';
import 'presentation/state/transaction_cache.dart';
import 'presentation/state/transaction_controller.dart';
import 'presentation/state/goal_controller.dart';
import 'presentation/state/debt_controller.dart';
import 'presentation/state/planned_payment_controller.dart';
import 'data/services/finance_initialization_service.dart';

/// Setup finance management dependencies
void setupFinanceDependencies() {
  // Budget module (datasources, repositories, controllers)
  setupBudgetDependencies();

  // Data sources
  locator.registerFactory<SavingsDataSource>(() => SavingsDataSourceRest());
  locator.registerFactory<TransactionDataSource>(
    () => TransactionDataSourceRest(),
  );
  locator.registerFactory<GoalDataSource>(() => GoalDataSourceRest());
  locator.registerFactory<DebtDataSource>(() => DebtDataSourceRest());
  locator.registerFactory<PlannedPaymentDataSource>(
    () => PlannedPaymentDataSourceRest(),
  );
  locator.registerFactory<FinanceCategoryDataSource>(
    () => FinanceCategoryDataSourceRest(),
  );

  // Repositories
  locator.registerFactory<FinanceCategoryRepository>(() {
    return FinanceCategoryRepositoryImpl(
      locator.get<FinanceCategoryDataSource>(),
    );
  });
  locator.registerFactory<SavingsRepository>(
    () => SavingsRepositoryImpl(locator.get<SavingsDataSource>()),
  );
  locator.registerFactory<TransactionRepository>(
    () => TransactionRepositoryImpl(locator.get<TransactionDataSource>()),
  );
  locator.registerFactory<GoalRepository>(() {
    return GoalRepositoryImpl(locator.get<GoalDataSource>());
  });
  locator.registerFactory<DebtRepository>(() {
    return DebtRepositoryImpl(locator.get<DebtDataSource>());
  });
  locator.registerFactory<PlannedPaymentRepository>(() {
    return PlannedPaymentRepositoryImpl(
      locator.get<PlannedPaymentDataSource>(),
    );
  });

  // Services
  locator.registerFactory<FinanceInitializationService>(() {
    return FinanceInitializationService(
      locator.get<FinanceCategoryRepository>(),
    );
  });

  // Controllers
  locator.registerLazySingleton<TransactionCache>(() => TransactionCache());

  locator.registerFactory<SavingsController>(() {
    return SavingsController(locator.get<SavingsRepository>());
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
}
