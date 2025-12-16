import '../models/account_model.dart';

/// Account data source interface
abstract class AccountDataSource {
  /// Get all accounts
  Future<List<AccountModel>> getAccounts();

  /// Get account by ID
  Future<AccountModel?> getAccountById(String id);

  /// Create a new account
  Future<AccountModel> createAccount(AccountModel account);

  /// Update an account
  Future<AccountModel> updateAccount(AccountModel account);

  /// Delete an account
  Future<void> deleteAccount(String id);
}
