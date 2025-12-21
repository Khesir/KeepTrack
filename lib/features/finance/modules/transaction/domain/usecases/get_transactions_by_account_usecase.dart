import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

/// Use case for getting transactions by account
class GetTransactionsByAccountUseCase {
  final TransactionRepository _repository;

  GetTransactionsByAccountUseCase(this._repository);

  Future<List<Transaction>> call(String accountId) async {
    return await _repository.getTransactionsByAccount(accountId);
  }
}
