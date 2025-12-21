import '../entities/account.dart';
import '../repositories/account_repository.dart';

class AdjustAccountBalanceUsecase {
  final AccountRepository repository;

  AdjustAccountBalanceUsecase(this.repository);

  Future<Account> call(String accountId, double amount) async {
    return repository.adjustBalance(accountId, amount);
  }
}
