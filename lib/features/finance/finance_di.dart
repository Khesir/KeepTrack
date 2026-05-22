import 'package:keep_track/core/cache/local_cache.dart';
import 'package:keep_track/core/demo/demo_mode.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/features/finance/modules/budget/budget_di.dart';
import 'package:keep_track/features/finance/modules/budget/presentation/controllers/budget_controller.dart';
import 'package:keep_track/features/finance/modules/budget_profile/data/datasources/local/budget_profile_datasource_local.dart';
import 'package:keep_track/features/finance/modules/budget_profile/data/datasources/mock/budget_profile_datasource_mock.dart';
import 'package:keep_track/features/finance/modules/debt/data/datasources/debt_datasource.dart';
import 'package:keep_track/features/finance/modules/debt/data/datasources/local/debt_datasource_local.dart';
import 'package:keep_track/features/finance/modules/debt/data/datasources/mock/debt_datasource_mock.dart';
import 'package:keep_track/features/finance/modules/debt/data/repositories/debt_repository_impl.dart';
import 'package:keep_track/features/finance/modules/debt/domain/repositories/debt_repository.dart';
import 'package:keep_track/features/finance/modules/finance_category/data/datasources/finance_category_datasource.dart';
import 'package:keep_track/features/finance/modules/finance_category/data/datasources/local/finance_category_datasource_local.dart';
import 'package:keep_track/features/finance/modules/finance_category/data/datasources/mock/finance_category_datasource_mock.dart';
import 'package:keep_track/features/finance/modules/finance_category/data/repositories/finance_repository_impl.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/repositories/finance_repository.dart';
import 'package:keep_track/features/finance/modules/goal/data/datasources/goal_datasource.dart';
import 'package:keep_track/features/finance/modules/goal/data/datasources/local/goal_datasource_local.dart';
import 'package:keep_track/features/finance/modules/goal/data/datasources/mock/goal_datasource_mock.dart';
import 'package:keep_track/features/finance/modules/goal/data/repositories/goal_repository_impl.dart';
import 'package:keep_track/features/finance/modules/goal/domain/repositories/goal_repository.dart';
import 'package:keep_track/features/finance/modules/planned_payment/data/datasources/planned_payment_datasource.dart';
import 'package:keep_track/features/finance/modules/planned_payment/data/datasources/local/planned_payment_datasource_local.dart';
import 'package:keep_track/features/finance/modules/planned_payment/data/datasources/mock/planned_payment_datasource_mock.dart';
import 'package:keep_track/features/finance/modules/planned_payment/data/repositories/planned_payment_repository_impl.dart';
import 'package:keep_track/features/finance/modules/planned_payment/domain/repositories/planned_payment_repository.dart';
import 'package:keep_track/features/finance/modules/savings/data/datasources/local/savings_datasource_local.dart';
import 'package:keep_track/features/finance/modules/savings/data/datasources/mock/savings_datasource_mock.dart';
import 'package:keep_track/features/finance/modules/savings/data/datasources/savings_datasource.dart';
import 'package:keep_track/features/finance/modules/savings/data/repositories/savings_repository_impl.dart';
import 'package:keep_track/features/finance/modules/savings/domain/repositories/savings_repository.dart';
import 'package:keep_track/features/finance/modules/subscriptions/data/datasources/local/subscription_datasource_local.dart';
import 'package:keep_track/features/finance/modules/subscriptions/data/datasources/mock/subscription_datasource_mock.dart';
import 'package:keep_track/features/finance/modules/subscriptions/data/datasources/subscription_datasource.dart';
import 'package:keep_track/features/finance/modules/subscriptions/data/repositories/subscription_repository_impl.dart';
import 'package:keep_track/features/finance/modules/subscriptions/domain/repositories/subscription_repository.dart';
import 'package:keep_track/features/finance/modules/transaction/data/datasources/local/transaction_datasource_local.dart';
import 'package:keep_track/features/finance/modules/transaction/data/datasources/mock/transaction_datasource_mock.dart';
import 'package:keep_track/features/finance/modules/transaction/data/datasources/transaction_datasource.dart';
import 'package:keep_track/features/finance/modules/transaction/data/repositories/transaction_repository_impl.dart';
import 'package:keep_track/features/finance/modules/transaction/domain/repositories/transaction_repository.dart';
import 'package:keep_track/features/finance/modules/transaction_plan/data/datasources/local/transaction_plan_datasource_local.dart';
import 'package:keep_track/features/finance/modules/transaction_plan/data/datasources/mock/transaction_plan_datasource_mock.dart';
import 'package:keep_track/features/finance/modules/transaction_plan/data/datasources/transaction_plan_datasource.dart';
import 'package:keep_track/features/finance/modules/transaction_plan/data/repositories/transaction_plan_repository_impl.dart';
import 'package:keep_track/features/finance/modules/transaction_plan/domain/repositories/transaction_plan_repository.dart';
import 'package:keep_track/features/finance/presentation/state/budget_profile_controller.dart';
import 'package:keep_track/features/finance/presentation/state/debt_controller.dart';
import 'package:keep_track/features/finance/presentation/state/finance_category_controller.dart';
import 'package:keep_track/features/finance/presentation/state/goal_controller.dart';
import 'package:keep_track/features/finance/presentation/state/planned_payment_controller.dart';
import 'package:keep_track/features/finance/presentation/state/savings_controller.dart';
import 'package:keep_track/features/finance/presentation/state/subscription_controller.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_cache.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_controller.dart';
import 'package:keep_track/features/finance/presentation/state/transaction_plan_controller.dart';
import 'data/services/finance_initialization_service.dart';

void setupFinanceDependencies() {
  final demo = DemoMode.enabled;

  setupBudgetDependencies();

  // Data sources — local Hive in production, mock in demo
  locator.registerFactory<SavingsDataSource>(
    () => demo ? SavingsDataSourceMock() : SavingsDataSourceLocal(locator.get<LocalCache>()),
  );
  locator.registerFactory<TransactionPlanDataSource>(
    () => demo ? TransactionPlanDataSourceMock() : TransactionPlanDataSourceLocal(locator.get<LocalCache>()),
  );
  locator.registerFactory<SubscriptionDataSource>(
    () => demo ? SubscriptionDataSourceMock() : SubscriptionDataSourceLocal(locator.get<LocalCache>()),
  );
  locator.registerFactory<TransactionDataSource>(
    () => demo ? TransactionDataSourceMock() : TransactionDataSourceLocal(locator.get<LocalCache>()),
  );
  locator.registerFactory<GoalDataSource>(
    () => demo ? GoalDataSourceMock() : GoalDataSourceLocal(locator.get<LocalCache>()),
  );
  locator.registerFactory<DebtDataSource>(
    () => demo ? DebtDataSourceMock() : DebtDataSourceLocal(locator.get<LocalCache>()),
  );
  locator.registerFactory<PlannedPaymentDataSource>(
    () => demo ? PlannedPaymentDataSourceMock() : PlannedPaymentDataSourceLocal(locator.get<LocalCache>()),
  );
  locator.registerFactory<FinanceCategoryDataSource>(
    () => demo ? FinanceCategoryDataSourceMock() : FinanceCategoryDataSourceLocal(locator.get<LocalCache>()),
  );

  // Repositories
  locator.registerFactory<FinanceCategoryRepository>(
    () => FinanceCategoryRepositoryImpl(locator.get<FinanceCategoryDataSource>()),
  );
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
  locator.registerFactory<GoalRepository>(
    () => GoalRepositoryImpl(locator.get<GoalDataSource>()),
  );
  locator.registerFactory<DebtRepository>(
    () => DebtRepositoryImpl(locator.get<DebtDataSource>()),
  );
  locator.registerFactory<PlannedPaymentRepository>(
    () => PlannedPaymentRepositoryImpl(locator.get<PlannedPaymentDataSource>()),
  );

  // Services
  locator.registerFactory<FinanceInitializationService>(
    () => FinanceInitializationService(locator.get<FinanceCategoryRepository>()),
  );

  // Controllers
  locator.registerLazySingleton<TransactionCache>(() => TransactionCache());

  locator.registerLazySingleton<SavingsController>(
    () => SavingsController(locator.get<SavingsRepository>()),
  );
  locator.registerLazySingleton<SubscriptionController>(
    () => SubscriptionController(locator.get<SubscriptionRepository>()),
  );
  locator.registerLazySingleton<TransactionPlanController>(
    () => TransactionPlanController(locator.get<TransactionPlanRepository>()),
  );
  locator.registerLazySingleton<TransactionController>(
    () => TransactionController(
      locator.get<TransactionRepository>(),
      locator.get<TransactionCache>(),
      onMutated: () => locator.get<BudgetController>().refreshBudgetsWithSpentAmounts(),
    ),
  );
  locator.registerLazySingleton<BudgetProfileController>(
    () => BudgetProfileController(
      demo ? BudgetProfileDataSourceMock() : BudgetProfileDataSourceLocal(locator.get<LocalCache>()),
    ),
  );
  locator.registerLazySingleton<GoalController>(
    () => GoalController(
      locator.get<GoalRepository>(),
      demo ? GoalDataSourceMock() : GoalDataSourceLocal(locator.get<LocalCache>()),
    ),
  );
  locator.registerLazySingleton<DebtController>(
    () => DebtController(locator.get<DebtRepository>()),
  );
  locator.registerLazySingleton<PlannedPaymentController>(
    () => PlannedPaymentController(locator.get<PlannedPaymentRepository>()),
  );
  locator.registerLazySingleton<FinanceCategoryController>(
    () => FinanceCategoryController(locator.get<FinanceCategoryRepository>()),
  );
}
