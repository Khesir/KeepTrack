import '../../entities/account.dart';
import '../../repositories/account_repository.dart';

class SetAccountBalance {
  final AccountRepository repository;

  SetAccountBalance(this.repository);

  Future<Account> call(String accountId, double balance) async {
    return repository.setBalance(accountId, balance);
  }
}
