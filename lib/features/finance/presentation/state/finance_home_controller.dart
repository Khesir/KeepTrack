import 'package:persona_codex/core/state/state.dart';
import 'package:persona_codex/features/finance/modules/account/domain/entities/account.dart';
import 'package:persona_codex/features/finance/modules/account/domain/usecases/archive_account_usecase.dart';

import '../../modules/account/domain/usecases/adjust_account_balance_usecase.dart';
import '../../modules/account/domain/usecases/create_account_usecase.dart';
import '../../modules/account/domain/usecases/delete_account_usecase.dart';
import '../../modules/account/domain/usecases/get_accounts_usecase.dart';
import '../../modules/account/domain/usecases/update_account_usecase.dart';

class AccountController extends StreamState<AsyncState<List<Account>>> {
  final GetAccountsUsecase _getAccountsUsecase;
  final CreateAccountUsecase _createAccountUsecase;
  final UpdateAccountUsecase _updateAccountUsecase;
  final DeleteAccountUsecase _deleteAccountUsecase;
  final ArchiveAccountUsecase _archiveAccountUsecase;
  final AdjustAccountBalanceUsecase _adjustAccountBalanceUsecase;

  AccountController({
    required GetAccountsUsecase getAccountsUsecase,
    required CreateAccountUsecase createAccountUsecase,
    required UpdateAccountUsecase updateAccountUsecase,
    required DeleteAccountUsecase deleteAccountUsecase,
    required ArchiveAccountUsecase archiveAccountUsecase,
    required AdjustAccountBalanceUsecase adjustAccountBalanceUsecase,
  }) : _getAccountsUsecase = getAccountsUsecase,
       _createAccountUsecase = createAccountUsecase,
       _updateAccountUsecase = updateAccountUsecase,
       _deleteAccountUsecase = deleteAccountUsecase,
       _archiveAccountUsecase = archiveAccountUsecase,
       _adjustAccountBalanceUsecase = adjustAccountBalanceUsecase,
       super(const AsyncLoading()) {
    loadAccounts();
  }

  /// Load all accounts
  Future<void> loadAccounts() async {
    await execute(() async => await _getAccountsUsecase());
  }

  /// Create a new account
  Future<void> createAccount(Account account) async {
    await execute(() async {
      final created = await _createAccountUsecase(account);
      final current = data ?? [];
      return [...current, created];
    });
  }

  /// Update an existing account
  Future<void> updateAccount(Account account) async {
    await execute(() async {
      final updated = await _updateAccountUsecase(account);
      final current = data ?? [];
      final index = current.indexWhere((a) => a.id == updated.id);
      if (index != -1) current[index] = updated;
      return current;
    });
  }

  /// Delete an account
  Future<void> deleteAccount(String id) async {
    await execute(() async {
      await _deleteAccountUsecase(id);
      final current = data ?? [];
      return current.where((a) => a.id != id).toList();
    });
  }

  /// Archive or unarchive account
  Future<void> archiveAccount(String id, {bool archive = true}) async {
    await execute(() async {
      final archived = await _archiveAccountUsecase(id);
      final current = data ?? [];
      final index = current.indexWhere((a) => a.id == archived.id);
      if (index != -1) current[index] = archived;
      return current;
    });
  }

  /// Adjust account balance
  Future<void> adjustBalance(String id, double amount) async {
    await execute(() async {
      final adjusted = await _adjustAccountBalanceUsecase(id, amount);
      final current = data ?? [];
      final index = current.indexWhere((a) => a.id == adjusted.id);
      if (index != -1) current[index] = adjusted;
      return current;
    });
  }
}
