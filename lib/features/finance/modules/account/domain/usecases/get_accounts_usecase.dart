import '../entities/account.dart';
import '../repositories/account_repository.dart';

class GetAccountsUsecase {
  final AccountRepository repository;

  GetAccountsUsecase(this.repository);

  Future<List<Account>> call() async {
    return repository.getAccounts();
  }

  Future<Account?> getAccountById(String id) async {
    return repository.getAccountById(id);
  }
}
