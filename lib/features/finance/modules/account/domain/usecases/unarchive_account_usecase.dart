import '../entities/account.dart';
import '../repositories/account_repository.dart';

class UnarchiveAccountUsecase {
  final AccountRepository repository;

  UnarchiveAccountUsecase(this.repository);

  Future<Account> call(String id) async {
    return repository.unarchiveAccount(id);
  }
}
