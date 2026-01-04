import 'package:keep_track/features/finance/modules/account/data/datasources/account_datasource.dart';
import 'package:keep_track/features/finance/modules/account/data/datasources/supabase/account_datasource_supabase.dart';
import 'package:keep_track/features/finance/modules/account/data/repositories/account_repository_impl.dart';
import 'package:keep_track/features/finance/modules/account/domain/repositories/account_repository.dart';
import 'package:keep_track/features/finance/modules/budget/data/datasources/budget_category_datasource.dart';
import 'package:keep_track/features/finance/modules/budget/data/datasources/supabase/budget_category_datasource_supabase.dart';
import 'package:keep_track/features/finance/modules/finance_category/data/datasources/finance_category_datasource.dart';
import 'package:keep_track/features/finance/modules/finance_category/data/datasources/supabase/finance_category_datasource_supabase.dart';
import 'package:keep_track/features/finance/modules/finance_category/domain/repositories/finance_repository.dart';
import 'package:keep_track/features/finance/presentation/state/budget_controller.dart';

import '../../core/di/service_locator.dart';
import '../../shared/infrastructure/supabase/supabase_service.dart';
import 'modules/budget/data/datasources/budget_datasource.dart';
import 'modules/budget/data/datasources/supabase/budget_datasource_supabase.dart';
import 'modules/budget/data/repositories/budget_repository_impl.dart';
import 'modules/budget/domain/repositories/budget_repository.dart';
import 'modules/finance_category/data/repositories/finance_repository_impl.dart';
import 'modules/transaction/data/datasources/transaction_datasource.dart';
import 'modules/transaction/data/datasources/supabase/transaction_datasource_supabase.dart';
import 'modules/transaction/data/repositories/transaction_repository_impl.dart';
import 'modules/transaction/domain/repositories/transaction_repository.dart';
import 'modules/goal/data/datasources/goal_datasource.dart';
import 'modules/goal/data/datasources/supabase/goal_datasource_supabase.dart';
import 'modules/goal/data/repositories/goal_repository_impl.dart';
import 'modules/goal/domain/repositories/goal_repository.dart';
import 'modules/debt/data/datasources/debt_datasource.dart';
import 'modules/debt/data/datasources/supabase/debt_datasource_supabase.dart';
import 'modules/debt/data/repositories/debt_repository_impl.dart';
import 'modules/debt/domain/repositories/debt_repository.dart';
import 'modules/planned_payment/data/datasources/planned_payment_datasource.dart';
import 'modules/planned_payment/data/datasources/supabase/planned_payment_datasource_supabase.dart';
import 'modules/planned_payment/data/repositories/planned_payment_repository_impl.dart';
import 'modules/planned_payment/domain/repositories/planned_payment_repository.dart';
import 'presentation/state/account_controller.dart';
import 'presentation/state/finance_category_controller.dart';
import 'presentation/state/transaction_controller.dart';
import 'presentation/state/goal_controller.dart';
import 'presentation/state/debt_controller.dart';
import 'presentation/state/planned_payment_controller.dart';
import 'data/services/finance_initialization_service.dart';

/// Setup finance management dependencies
void setupFinanceDependencies() {
  // Data sources (uses shared Supabase service)

  locator.registerFactory<AccountDataSource>(() {
    final supabaseService = locator.get<SupabaseService>();
    return AccountDataSourceSupabase(supabaseService);
  });
  locator.registerFactory<TransactionDataSource>(() {
    final supabaseService = locator.get<SupabaseService>();
    return TransactionDataSourceSupabase(supabaseService);
  });
  locator.registerFactory<GoalDataSource>(() {
    final supabaseService = locator.get<SupabaseService>();
    return GoalDataSourceSupabase(supabaseService);
  });
  locator.registerFactory<DebtDataSource>(() {
    final supabaseService = locator.get<SupabaseService>();
    return DebtDataSourceSupabase(supabaseService);
  });
  locator.registerFactory<PlannedPaymentDataSource>(() {
    final supabaseService = locator.get<SupabaseService>();
    return PlannedPaymentDataSourceSupabase(supabaseService);
  });
  locator.registerFactory<FinanceCategoryDataSource>(() {
    final supabaseService = locator.get<SupabaseService>();
    return FinanceCategoryDataSourceSupabase(supabaseService);
  });
  locator.registerLazySingleton<BudgetCategoryDataSource>(() {
    final supabaseService = locator.get<SupabaseService>();
    return BudgetCategoryDataSourceSupabase(supabaseService);
  });
  locator.registerFactory<BudgetDataSource>(() {
    final supabaseService = locator.get<SupabaseService>();
    final bugetCategory = locator.get<BudgetCategoryDataSource>();
    return BudgetDataSourceSupabase(supabaseService, bugetCategory);
  });

  // Repositories
  locator.registerFactory<FinanceCategoryRepository>(() {
    final dataSource = locator.get<FinanceCategoryDataSource>();
    return FinanceCategoryRepositoryImpl(dataSource);
  });

  // Update repository registration
  locator.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(
      locator.get<BudgetDataSource>(),
      locator.get<BudgetCategoryDataSource>(),
    ),
  );
  locator.registerFactory<AccountRepository>(() {
    final dataSource = locator.get<AccountDataSource>();
    return AccountRepositoryImpl(dataSource);
  });
  locator.registerFactory<TransactionRepository>(() {
    final dataSource = locator.get<TransactionDataSource>();
    final accountRepository = locator.get<AccountRepository>();
    return TransactionRepositoryImpl(dataSource, accountRepository);
  });
  locator.registerFactory<GoalRepository>(() {
    final dataSource = locator.get<GoalDataSource>();
    return GoalRepositoryImpl(dataSource);
  });
  locator.registerFactory<DebtRepository>(() {
    final dataSource = locator.get<DebtDataSource>();
    return DebtRepositoryImpl(dataSource);
  });
  locator.registerFactory<PlannedPaymentRepository>(() {
    final dataSource = locator.get<PlannedPaymentDataSource>();
    return PlannedPaymentRepositoryImpl(dataSource);
  });

  // Services
  locator.registerFactory<FinanceInitializationService>(() {
    final categoryRepository = locator.get<FinanceCategoryRepository>();
    return FinanceInitializationService(categoryRepository);
  });

  // Controllers
  locator.registerFactory<AccountController>(() {
    final repository = locator.get<AccountRepository>();
    return AccountController(repository);
  });
  locator.registerFactory<TransactionController>(() {
    final repository = locator.get<TransactionRepository>();
    return TransactionController(repository);
  });
  locator.registerFactory<GoalController>(() {
    final repository = locator.get<GoalRepository>();
    return GoalController(repository);
  });
  locator.registerFactory<DebtController>(() {
    final debtRepository = locator.get<DebtRepository>();
    final transactionRepository = locator.get<TransactionRepository>();
    final supabaseService = locator.get<SupabaseService>();
    return DebtController(debtRepository, transactionRepository, supabaseService);
  });
  locator.registerFactory<PlannedPaymentController>(() {
    final repository = locator.get<PlannedPaymentRepository>();
    return PlannedPaymentController(repository);
  });
  locator.registerFactory<FinanceCategoryController>(() {
    final repository = locator.get<FinanceCategoryRepository>();
    return FinanceCategoryController(repository);
  });
  locator.registerFactory<BudgetController>(() {
    final repository = locator.get<BudgetRepository>();
    return BudgetController(repository);
  });
}
