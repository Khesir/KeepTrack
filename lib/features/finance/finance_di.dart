import 'package:persona_codex/features/finance/data/datasources/account_datasource.dart';
import 'package:persona_codex/features/finance/data/datasources/supabase/account_datasource_supabase.dart';
import 'package:persona_codex/features/finance/data/repositories/account_repository_impl.dart';
import 'package:persona_codex/features/finance/domain/repositories/account_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/di/service_locator.dart';
import '../../shared/infrastructure/supabase/supabase_service.dart';
import 'data/datasources/budget_datasource.dart';
import 'data/datasources/supabase/budget_datasource_supabase.dart';
import 'data/repositories/budget_repository_impl.dart';
import 'domain/repositories/budget_repository.dart';
import 'data/datasources/transaction_datasource.dart';
import 'data/datasources/supabase/transaction_datasource_supabase.dart';
import 'data/repositories/transaction_repository_impl.dart';
import 'domain/repositories/transaction_repository.dart';
import 'presentation/state/account_controller.dart';
import 'presentation/state/transaction_controller.dart';

/// Setup budget management dependencies
void setupBudgetDependencies() {
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

  // Controllers
  locator.registerFactory<AccountController>(() {
    final repository = locator.get<AccountRepository>();
    return AccountController(repository);
  });
  locator.registerFactory<TransactionController>(() {
    final repository = locator.get<TransactionRepository>();
    return TransactionController(repository);
  });
}
