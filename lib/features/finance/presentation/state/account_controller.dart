import 'package:keep_track/core/error/result.dart';
import 'package:keep_track/core/state/stream_state.dart';
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

  /// Create a new account — throws on failure so callers can show errors
  Future<void> createAccount(Account account) async {
    final created = await _repository.createAccount(account).then((r) => r.unwrap());
    final current = data ?? [];
    emit(AsyncData([...current, created]));
  }

  /// Update an existing account — throws on failure so callers can show errors
  Future<void> updateAccount(Account account) async {
    await _repository.updateAccount(account).then((r) => r.unwrap());
    await loadAccounts();
  }

  /// Delete an account — throws on failure so callers can show errors
  Future<void> deleteAccount(String id) async {
    await _repository.deleteAccount(id).then((r) => r.unwrap());
    await loadAccounts();
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
