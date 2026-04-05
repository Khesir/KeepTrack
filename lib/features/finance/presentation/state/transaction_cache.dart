import '../../modules/transaction/domain/entities/transaction.dart';

/// In-memory cache for transaction lists keyed by account ID.
/// Registered as a singleton so it persists across controller factory instances.
class TransactionCache {
  final Map<String, List<Transaction>> _byAccount = {};

  List<Transaction>? getByAccount(String accountId) => _byAccount[accountId];

  void setByAccount(String accountId, List<Transaction> data) {
    _byAccount[accountId] = data;
  }

  void invalidateAll() => _byAccount.clear();
}
