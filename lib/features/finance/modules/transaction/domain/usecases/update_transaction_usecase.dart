import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

/// Use case for updating a transaction
class UpdateTransactionUseCase {
  final TransactionRepository _repository;

  UpdateTransactionUseCase(this._repository);

  Future<Transaction> call(Transaction transaction) async {
    return await _repository.updateTransaction(transaction);
  }
}
