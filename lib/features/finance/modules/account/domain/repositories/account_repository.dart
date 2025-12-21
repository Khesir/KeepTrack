import '../entities/account.dart';

/// Account repository interface
abstract class AccountRepository {
  /// Get all accounts
  Future<List<Account>> getAccounts();

  /// Get account by ID
  Future<Account?> getAccountById(String id);

  /// Create a new account
  Future<Account> createAccount(Account account);

  /// Update an account
  Future<Account> updateAccount(Account account);

  /// Delete an account
  Future<void> deleteAccount(String id);

  /// Archive an account
  Future<Account> archiveAccount(String id);

  /// Unarchive an account
  Future<Account> unarchiveAccount(String id);

  /// Adjust account balance (e.g., for transactions)
  Future<Account> adjustBalance(String accountId, double amount);

  /// Set account balance directly
  Future<Account> setBalance(String accountId, double balance);
}
