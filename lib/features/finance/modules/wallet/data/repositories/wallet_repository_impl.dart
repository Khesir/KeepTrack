import 'package:keep_track/core/error/result.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_datasource.dart';
import '../models/wallet_model.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletDataSource _dataSource;

  WalletRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<Wallet>>> getWallets() async {
    final wallets = await _dataSource.getWallets();
    return Result.success(wallets);
  }

  @override
  Future<Result<Wallet>> createWallet(Wallet wallet) async {
    final created = await _dataSource.createWallet(WalletModel.fromEntity(wallet));
    return Result.success(created);
  }

  @override
  Future<Result<Wallet>> updateWallet(Wallet wallet) async {
    final updated = await _dataSource.updateWallet(WalletModel.fromEntity(wallet));
    return Result.success(updated);
  }

  @override
  Future<Result<void>> deleteWallet(String id) async {
    await _dataSource.deleteWallet(id);
    return Result.success(null);
  }
}
