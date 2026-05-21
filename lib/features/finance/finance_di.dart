import 'package:keep_track/core/demo/demo_mode.dart';
import 'package:keep_track/features/finance/modules/budget/budget_di.dart';
import 'package:keep_track/features/finance/modules/savings/data/datasources/rest/savings_datasource_rest.dart';
import 'package:keep_track/features/finance/modules/savings/data/datasources/mock/savings_datasource_mock.dart';
import 'package:keep_track/features/finance/modules/savings/data/datasources/savings_datasource.dart';
import 'package:keep_track/features/finance/modules/savings/data/repositories/savings_repository_impl.dart';
import 'package:keep_track/features/finance/modules/savings/domain/repositories/savings_repository.dart';
import 'modules/transaction_plan/data/datasources/rest/transaction_plan_datasource_rest.dart';
import 'modules/transaction_plan/data/datasources/mock/transaction_plan_datasource_mock.dart';
import 'modules/transaction_plan/data/datasources/transaction_plan_datasource.dart';
import 'modules/transaction_plan/data/repositories/transaction_plan_repository_impl.dart';
import 'modules/transaction_plan/domain/repositories/transaction_plan_repository.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/controllers/budget_controller.dart';
import 'package:keep_track/features/finance/modules/finance_category/data/datasources/finance_category_datasource.dart';
import 'package:keep_track/features/finance/modules/finance_category/data/datasources/rest/finance_category_datasource_rest.dart';
import 'package:keep_track/features/finance/modules/finance_category/data/datasources/mock/finance_category_datasource_mock.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/repositories/finance_repository.dart';

import '../../core/di/service_locator.dart';
import 'modules/finance_category/data/repositories/finance_repository_impl.dart';
import 'modules/transaction/data/datasources/transaction_datasource.dart';
import 'modules/transaction/data/datasources/rest/transaction_datasource_rest.dart';
import 'modules/transaction/data/datasources/mock/transaction_datasource_mock.dart';
import 'modules/transaction/data/repositories/transaction_repository_impl.dart';
import 'modules/transaction/domain/repositories/transaction_repository.dart';
import 'modules/goal/data/datasources/goal_datasource.dart';
import 'modules/goal/data/datasources/rest/goal_datasource_rest.dart';
import 'modules/goal/data/datasources/mock/goal_datasource_mock.dart';
import 'modules/goal/data/repositories/goal_repository_impl.dart';
import 'modules/goal/domain/repositories/goal_repository.dart';
import 'modules/debt/data/datasources/debt_datasource.dart';
import 'modules/debt/data/datasources/rest/debt_datasource_rest.dart';
import 'modules/debt/data/datasources/mock/debt_datasource_mock.dart';
import 'modules/debt/data/repositories/debt_repository_impl.dart';
import 'modules/debt/domain/repositories/debt_repository.dart';
import 'modules/planned_payment/data/datasources/planned_payment_datasource.dart';
import 'modules/planned_payment/data/datasources/rest/planned_payment_datasource_rest.dart';
import 'modules/planned_payment/data/datasources/mock/planned_payment_datasource_mock.dart';
import 'modules/planned_payment/data/repositories/planned_payment_repository_impl.dart';
import 'modules/planned_payment/domain/repositories/planned_payment_repository.dart';
import 'modules/subscriptions/data/datasources/rest/subscription_datasource_rest.dart';
import 'modules/subscriptions/data/datasources/mock/subscription_datasource_mock.dart';
import 'modules/subscriptions/data/datasources/subscription_datasource.dart';
import 'modules/subscriptions/data/repositories/subscription_repository_impl.dart';
import 'modules/subscriptions/domain/repositories/subscription_repository.dart';
import 'presentation/state/finance_category_controller.dart';
import 'presentation/state/savings_controller.dart';
import 'presentation/state/subscription_controller.dart';
import 'presentation/state/transaction_plan_controller.dart';
import 'presentation/state/transaction_cache.dart';
import 'presentation/state/transaction_controller.dart';
import 'presentation/state/goal_controller.dart';
import 'presentation/state/debt_controller.dart';
import 'presentation/state/budget_profile_controller.dart';
import 'modules/budget_profile/data/datasources/rest/budget_profile_datasource_rest.dart';
import 'modules/budget_profile/data/datasources/mock/budget_profile_datasource_mock.dart';
import 'presentation/state/planned_payment_controller.dart';
import 'data/services/finance_initialization_service.dart';

/// Setup finance management dependencies
void setupFinanceDependencies() {
  final demo = DemoMode.enabled;

  // Budget module (datasources, repositories, controllers)
  setupBudgetDependencies();

  // Data sources
  locator.registerFactory<SavingsDataSource>(() => demo ? SavingsDataSourceMock() : SavingsDataSourceRest());
  locator.registerFactory<TransactionPlanDataSource>(() => demo ? TransactionPlanDataSourceMock() : TransactionPlanDataSourceRest());
  locator.registerFactory<SubscriptionDataSource>(() => demo ? SubscriptionDataSourceMock() : SubscriptionDataSourceRest());
  locator.registerFactory<TransactionDataSource>(() => demo ? TransactionDataSourceMock() : TransactionDataSourceRest());
  locator.registerFactory<GoalDataSource>(() => demo ? GoalDataSourceMock() : GoalDataSourceRest());
  locator.registerFactory<DebtDataSource>(() => demo ? DebtDataSourceMock() : DebtDataSourceRest());
  locator.registerFactory<PlannedPaymentDataSource>(() => demo ? PlannedPaymentDataSourceMock() : PlannedPaymentDataSourceRest());
  locator.registerFactory<FinanceCategoryDataSource>(() => demo ? FinanceCategoryDataSourceMock() : FinanceCategoryDataSourceRest());

  // Repositories
  locator.registerFactory<FinanceCategoryRepository>(() {
    return FinanceCategoryRepositoryImpl(
      locator.get<FinanceCategoryDataSource>(),
    );
  });
  locator.registerFactory<SavingsRepository>(
    () => SavingsRepositoryImpl(locator.get<SavingsDataSource>()),
  );
  locator.registerFactory<TransactionPlanRepository>(
    () => TransactionPlanRepositoryImpl(locator.get<TransactionPlanDataSource>()),
  );
  locator.registerFactory<SubscriptionRepository>(
    () => SubscriptionRepositoryImpl(locator.get<SubscriptionDataSource>()),
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
  locator.registerFactory<SubscriptionController>(() {
    return SubscriptionController(locator.get<SubscriptionRepository>());
  });
  locator.registerFactory<TransactionPlanController>(() {
    return TransactionPlanController(locator.get<TransactionPlanRepository>());
  });
  locator.registerFactory<TransactionController>(() {
    return TransactionController(
      locator.get<TransactionRepository>(),
      locator.get<TransactionCache>(),
      onMutated: () =>
          locator.get<BudgetController>().refreshBudgetsWithSpentAmounts(),
    );
  });
  locator.registerLazySingleton<BudgetProfileController>(
    () => BudgetProfileController(demo ? BudgetProfileDataSourceMock() : BudgetProfileDataSourceRest()),
  );
  locator.registerFactory<GoalController>(() {
    return GoalController(locator.get<GoalRepository>(), demo ? GoalDataSourceMock() : GoalDataSourceRest());
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
