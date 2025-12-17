import '../../entities/transaction.dart';
import '../../repositories/transaction_repository.dart';

/// Use case for creating a transaction
class CreateTransactionUseCase {
  final TransactionRepository _repository;

  CreateTransactionUseCase(this._repository);

  Future<Transaction> call(Transaction transaction) async {
    return await _repository.createTransaction(transaction);
  }
}
