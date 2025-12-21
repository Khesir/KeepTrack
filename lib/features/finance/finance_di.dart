import 'package:persona_codex/features/finance/modules/account/data/datasources/account_datasource.dart';
import 'package:persona_codex/features/finance/modules/account/data/datasources/supabase/account_datasource_supabase.dart';
import 'package:persona_codex/features/finance/modules/account/data/repositories/account_repository_impl.dart';
import 'package:persona_codex/features/finance/modules/account/domain/repositories/account_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/di/service_locator.dart';
import '../../shared/infrastructure/supabase/supabase_service.dart';
import 'modules/budget/data/datasources/budget_datasource.dart';
import 'modules/budget/data/datasources/supabase/budget_datasource_supabase.dart';
import 'modules/budget/data/repositories/budget_repository_impl.dart';
import 'modules/budget/domain/repositories/budget_repository.dart';
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
import 'presentation/state/transaction_controller.dart';
import 'presentation/state/goal_controller.dart';
import 'presentation/state/debt_controller.dart';
import 'presentation/state/planned_payment_controller.dart';

/// Setup finance management dependencies
void setupFinanceDependencies() {
  // Data sources (uses shared Supabase service)
  locator.registerFactory<BudgetDataSource>(() {
    final supabaseService = locator.get<SupabaseService>();
    return BudgetDataSourceSupabase(supabaseService);
  });
  locator.registerFactory<AccountDataSource>(() {
    final supabaseService = locator.get<SupabaseService>();
    return AccountDataSourceSupabase(supabaseService);
  });
  locator.registerFactory<TransactionDataSource>(() {
    final client = Supabase.instance.client;
    return TransactionDataSourceSupabase(client);
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

  // Repositories
  locator.registerFactory<BudgetRepository>(() {
    final dataSource = locator.get<BudgetDataSource>();
    return BudgetRepositoryImpl(dataSource);
  });
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
    final repository = locator.get<DebtRepository>();
    return DebtController(repository);
  });
  locator.registerFactory<PlannedPaymentController>(() {
    final repository = locator.get<PlannedPaymentRepository>();
    return PlannedPaymentController(repository);
  });
}
