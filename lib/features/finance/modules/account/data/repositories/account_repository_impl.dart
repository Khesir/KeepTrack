import 'package:persona_codex/core/error/failure.dart';
import 'package:persona_codex/core/error/result.dart';
import 'package:persona_codex/features/finance/modules/account/data/datasources/account_datasource.dart';
import 'package:persona_codex/features/finance/modules/account/domain/entities/account.dart';

import '../../domain/repositories/account_repository.dart';
import '../models/account_model.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AccountDataSource dataSource;

  AccountRepositoryImpl(this.dataSource);

  @override
  Future<Result<List<Account>>> getAccounts() async {
    final accounts = await dataSource.getAccounts();
    return Result.success(accounts);
  }

  @override
  Future<Result<Account>> getAccountById(String id) async {
    final account = await dataSource.getAccountById(id);
    if (account == null) {
      return Result.error(NotFoundFailure(message: 'Account not found: $id'));
    }
    return Result.success(account);
  }

  @override
  Future<Result<Account>> createAccount(Account account) async {
    final model = AccountModel.fromEntity(account);
    final created = await dataSource.createAccount(model);
    return Result.success(created);
  }

  @override
  Future<Result<Account>> updateAccount(Account account) async {
    final model = AccountModel.fromEntity(account);
    final updated = await dataSource.updateAccount(model);
    return Result.success(updated);
  }

  @override
  Future<Result<void>> deleteAccount(String id) async {
    await dataSource.deleteAccount(id);
    return Result.success(null);
  }

  @override
  Future<Result<Account>> archiveAccount(String id) async {
    final result = await getAccountById(id);
    if (result.isError) return result;

    final account = result.data;
    final updated = account.copyWith(
      isArchived: true,
      updatedAt: DateTime.now(),
    );

    return updateAccount(updated);
  }

  @override
  Future<Result<Account>> unarchiveAccount(String id) async {
    final result = await getAccountById(id);
    if (result.isError) return result;

    final account = result.data;
    final updated = account.copyWith(
      isArchived: false,
      updatedAt: DateTime.now(),
    );

    return updateAccount(updated);
  }

  @override
  Future<Result<Account>> adjustBalance(String id, double amount) async {
    final result = await getAccountById(id);
    if (result.isError) return result;

    final account = result.data;
    final updated = account.copyWith(
      balance: account.balance + amount,
      updatedAt: DateTime.now(),
    );

    return updateAccount(updated);
  }

  @override
  Future<Result<Account>> setBalance(String id, double balance) async {
    final result = await getAccountById(id);
    if (result.isError) return result;

    final account = result.data;
    final updated = account.copyWith(
      balance: balance,
      updatedAt: DateTime.now(),
    );

    return updateAccount(updated);
  }
}
