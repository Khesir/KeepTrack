import '../entities/account.dart';
import '../repositories/account_repository.dart';

class CreateAccountUsecase {
  final AccountRepository repository;

  CreateAccountUsecase(this.repository);

  Future<Account> call(Account account) async {
    return repository.createAccount(account);
  }
}
