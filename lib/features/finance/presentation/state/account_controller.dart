import 'package:persona_codex/core/state/stream_state.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';

/// Controller for managing account list state
class AccountController extends StreamState<AsyncState<List<Account>>> {
  final AccountRepository _repository;

  AccountController(this._repository) : super(const AsyncLoading()) {
    loadAccounts();
  }

  /// Load all accounts
  Future<void> loadAccounts() async {
    await execute(() => _repository.getAccounts());
  }

  /// Create a new account
  Future<void> createAccount(Account account) async {
    try {
      await _repository.createAccount(account);
      await loadAccounts();
    } catch (e) {
      emit(AsyncError('Failed to create account: $e', e));
    }
  }

  /// Update an existing account
  Future<void> updateAccount(Account account) async {
    try {
      await _repository.updateAccount(account);
      await loadAccounts();
    } catch (e) {
      emit(AsyncError('Failed to update account: $e', e));
    }
  }

  /// Delete an account
  Future<void> deleteAccount(String id) async {
    try {
      await _repository.deleteAccount(id);
      await loadAccounts();
    } catch (e) {
      emit(AsyncError('Failed to delete account: $e', e));
    }
  }

  /// Archive an account
  Future<void> archiveAccount(String id) async {
    try {
      await _repository.archiveAccount(id);
      await loadAccounts();
    } catch (e) {
      emit(AsyncError('Failed to archive account: $e', e));
    }
  }

  /// Unarchive an account
  Future<void> unarchiveAccount(String id) async {
    try {
      await _repository.unarchiveAccount(id);
      await loadAccounts();
    } catch (e) {
      emit(AsyncError('Failed to unarchive account: $e', e));
    }
  }

  /// Adjust account balance
  Future<void> adjustBalance(String accountId, double amount) async {
    try {
      await _repository.adjustBalance(accountId, amount);
      await loadAccounts();
    } catch (e) {
      emit(AsyncError('Failed to adjust balance: $e', e));
    }
  }

  /// Set account balance directly
  Future<void> setBalance(String accountId, double balance) async {
    try {
      await _repository.setBalance(accountId, balance);
      await loadAccounts();
    } catch (e) {
      emit(AsyncError('Failed to set balance: $e', e));
    }
  }
}
