import '../repositories/account_repository.dart';

class DeleteAccountUsecase {
  final AccountRepository repository;

  DeleteAccountUsecase(this.repository);

  Future<void> call(String id) async {
    return repository.deleteAccount(id);
  }
}
