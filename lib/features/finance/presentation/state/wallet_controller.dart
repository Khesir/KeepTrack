import 'package:keep_track/core/error/result.dart';
import 'package:keep_track/core/state/stream_state.dart';
import '../../modules/wallet/domain/entities/wallet.dart';
import '../../modules/wallet/domain/repositories/wallet_repository.dart';

class WalletController extends StreamState<AsyncState<List<Wallet>>> {
  final WalletRepository _repository;

  WalletController(this._repository) : super(const AsyncLoading()) {
    loadWallets();
  }

  List<Wallet> get wallets => data ?? [];

  Future<void> loadWallets() async {
    await execute(() async {
      return await _repository.getWallets().then((r) => r.unwrap());
    });
  }

  Future<void> createWallet(Wallet wallet) async {
    final created = await _repository.createWallet(wallet).then((r) => r.unwrap());
    final current = data ?? [];
    emit(AsyncData([...current, created]));
  }

  Future<void> updateWallet(Wallet wallet) async {
    await _repository.updateWallet(wallet).then((r) => r.unwrap());
    await loadWallets();
  }

  Future<void> deleteWallet(String id) async {
    await _repository.deleteWallet(id).then((r) => r.unwrap());
    await loadWallets();
  }
}
