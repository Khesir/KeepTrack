import '../../entities/account.dart';
import '../../repositories/account_repository.dart';

class UpdateAccountUsecase {
  final AccountRepository repository;

  UpdateAccountUsecase(this.repository);

  Future<Account> call(Account account) async {
    return repository.updateAccount(account);
  }
}
