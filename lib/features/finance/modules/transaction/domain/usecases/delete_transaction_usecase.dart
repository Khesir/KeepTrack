import '../repositories/transaction_repository.dart';

/// Use case for deleting a transaction
class DeleteTransactionUseCase {
  final TransactionRepository _repository;

  DeleteTransactionUseCase(this._repository);

  Future<void> call(String id) async {
    await _repository.deleteTransaction(id);
  }
}
