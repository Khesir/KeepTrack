import '../models/wallet_model.dart';

abstract class WalletDataSource {
  Future<List<WalletModel>> getWallets();
  Future<WalletModel> createWallet(WalletModel wallet);
  Future<WalletModel> updateWallet(WalletModel wallet);
  Future<void> deleteWallet(String id);
}
