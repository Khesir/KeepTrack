import 'package:keep_track/core/error/result.dart';

import '../entities/account.dart';

/// Account repository interface
abstract class AccountRepository {
  /// Get all accounts
  Future<Result<List<Account>>> getAccounts();

  /// Get account by ID
  Future<Result<Account>> getAccountById(String id);

  /// Create a new account
  Future<Result<Account>> createAccount(Account account);

  /// Update an account
  Future<Result<Account>> updateAccount(Account account);

  /// Delete an account
  Future<Result<void>> deleteAccount(String id);

  /// Archive an account
  Future<Result<Account>> archiveAccount(String id);

  /// Unarchive an account
  Future<Result<Account>> unarchiveAccount(String id);

  /// Adjust account balance (e.g., for transactions)
  Future<Result<Account>> adjustBalance(String accountId, double amount);

  /// Set account balance directly
  Future<Result<Account>> setBalance(String accountId, double balance);
}
