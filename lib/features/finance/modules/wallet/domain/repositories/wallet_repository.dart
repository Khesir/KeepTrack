import 'package:keep_track/core/error/result.dart';
import '../entities/wallet.dart';

abstract class WalletRepository {
  Future<Result<List<Wallet>>> getWallets();
  Future<Result<Wallet>> createWallet(Wallet wallet);
  Future<Result<Wallet>> updateWallet(Wallet wallet);
  Future<Result<void>> deleteWallet(String id);
}
