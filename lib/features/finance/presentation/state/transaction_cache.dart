import '../../modules/transaction/domain/entities/transaction.dart';

class TransactionCache {
  List<Transaction>? _recent;

  List<Transaction>? getRecent() => _recent;

  void setRecent(List<Transaction> data) {
    _recent = data;
  }

  void invalidateAll() => _recent = null;
}
