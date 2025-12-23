import 'package:persona_codex/core/error/result.dart';
import 'package:persona_codex/core/state/stream_state.dart';
import '../../modules/account/domain/entities/account.dart';
import '../../modules/account/domain/repositories/account_repository.dart';

/// Controller for managing account list state
class AccountController extends StreamState<AsyncState<List<Account>>> {
  final AccountRepository _repository;

  AccountController(this._repository) : super(const AsyncLoading()) {
    loadAccounts();
  }

  /// Load all accounts
  Future<void> loadAccounts() async {
    await execute(() async {
      return await _repository.getAccounts().then((r) => r.unwrap());
    });
  }

  /// Create a new account
  Future<void> createAccount(Account account) async {
    await execute(() async {
      final created = await _repository
          .createAccount(account)
          .then((r) => r.unwrap());
      final current = data ?? [];
      return [...current, created];
    });
  }

  /// Update an existing account
  Future<void> updateAccount(Account account) async {
    await execute(() async {
      await _repository.updateAccount(account).then((r) => r.unwrap());
      await loadAccounts();
      return data ?? [];
    });
  }

  /// Delete an account
  Future<void> deleteAccount(String id) async {
    await execute(() async {
      await _repository.deleteAccount(id).then((r) => r.unwrap());
      await loadAccounts();
      return data ?? [];
    });
  }

  /// Archive an account
  Future<void> archiveAccount(String id) async {
    await execute(() async {
      await _repository.archiveAccount(id).then((r) => r.unwrap());
      await loadAccounts();
      return data ?? [];
    });
  }

  /// Unarchive an account
  Future<void> unarchiveAccount(String id) async {
    await execute(() async {
      await _repository.unarchiveAccount(id).then((r) => r.unwrap());
      await loadAccounts();
      return data ?? [];
    });
  }

  /// Adjust account balance
  Future<void> adjustBalance(String accountId, double amount) async {
    await execute(() async {
      await _repository
          .adjustBalance(accountId, amount)
          .then((r) => r.unwrap());
      await loadAccounts();
      return data ?? [];
    });
  }

  /// Set account balance directly
  Future<void> setBalance(String accountId, double balance) async {
    await execute(() async {
      await _repository.setBalance(accountId, balance).then((r) => r.unwrap());
      await loadAccounts();
      return data ?? [];
    });
  }
}
