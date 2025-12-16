import '../../entities/account.dart';
import '../../repositories/account_repository.dart';

class ArchiveAccountUsecase {
  final AccountRepository repository;

  ArchiveAccountUsecase(this.repository);

  Future<Account> call(String id) async {
    return repository.archiveAccount(id);
  }
}
