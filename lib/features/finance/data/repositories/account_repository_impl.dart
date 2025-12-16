import 'package:persona_codex/features/finance/data/datasources/account_datasource.dart';
import 'package:persona_codex/features/finance/data/models/account_model.dart';
import 'package:persona_codex/features/finance/domain/entities/account.dart';
import 'package:persona_codex/features/finance/domain/repositories/account_repository.dart';

/// Account repository implementation
class AccountRepositoryImpl implements AccountRepository {
  final AccountDataSource dataSource;

  AccountRepositoryImpl(this.dataSource);

  @override
  Future<List<Account>> getAccounts() async {
    final models = await dataSource.getAccounts();
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Account?> getAccountById(String id) async {
    final model = await dataSource.getAccountById(id);
    return model?.toEntity();
  }

  @override
  Future<Account> createAccount(Account account) async {
    final model = AccountModel.fromEntity(account);
    final created = await dataSource.createAccount(model);
    return created.toEntity();
  }

  @override
  Future<Account> updateAccount(Account account) async {
    final model = AccountModel.fromEntity(account);
    final updated = await dataSource.updateAccount(model);
    return updated.toEntity();
  }

  @override
  Future<void> deleteAccount(String id) async {
    await dataSource.deleteAccount(id);
  }

  @override
  Future<Account> archiveAccount(String id) async {
    final account = await getAccountById(id);
    if (account == null) {
      throw Exception('Account not found: $id');
    }

    final archived = account.copyWith(
      isArchived: true,
      updatedAt: DateTime.now(),
    );

    return updateAccount(archived);
  }

  @override
  Future<Account> unarchiveAccount(String id) async {
    final account = await getAccountById(id);
    if (account == null) {
      throw Exception('Account not found: $id');
    }

    final unarchived = account.copyWith(
      isArchived: false,
      updatedAt: DateTime.now(),
    );

    return updateAccount(unarchived);
  }

  @override
  Future<Account> adjustBalance(String accountId, double amount) async {
    final account = await getAccountById(accountId);
    if (account == null) {
      throw Exception('Account not found: $accountId');
    }

    final updated = account.copyWith(
      balance: account.balance + amount,
      updatedAt: DateTime.now(),
    );

    return updateAccount(updated);
  }

  @override
  Future<Account> setBalance(String accountId, double balance) async {
    final account = await getAccountById(accountId);
    if (account == null) {
      throw Exception('Account not found: $accountId');
    }

    final updated = account.copyWith(
      balance: balance,
      updatedAt: DateTime.now(),
    );

    return updateAccount(updated);
  }
}
