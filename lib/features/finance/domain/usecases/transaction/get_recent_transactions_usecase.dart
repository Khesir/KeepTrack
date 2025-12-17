import '../../entities/transaction.dart';
import '../../repositories/transaction_repository.dart';

/// Use case for getting recent transactions
class GetRecentTransactionsUseCase {
  final TransactionRepository _repository;

  GetRecentTransactionsUseCase(this._repository);

  Future<List<Transaction>> call({int limit = 10}) async {
    return await _repository.getRecentTransactions(limit: limit);
  }
}
