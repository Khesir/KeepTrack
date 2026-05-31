import 'package:keep_track/core/cache/local_cache.dart';
import 'package:keep_track/features/finance/modules/wallet/data/models/wallet_model.dart';
import 'package:uuid/uuid.dart';
import '../wallet_datasource.dart';

class WalletDataSourceLocal implements WalletDataSource {
  final LocalCache _cache;
  final _uuid = const Uuid();

  static const _box = 'wallets';

  WalletDataSourceLocal(this._cache);

  Future<List<WalletModel>> _getAll() async {
    final entries = await _cache.getAll(_box);
    return entries.map((e) => WalletModel.fromJson(e)).toList();
  }

  @override
  Future<List<WalletModel>> getWallets() async => _getAll();

  @override
  Future<WalletModel> createWallet(WalletModel wallet) async {
    final id = wallet.id ?? _uuid.v4();
    final model = WalletModel.fromJson({...wallet.toJson(), 'id': id});
    await _cache.put(_box, id, model.toJson());
    return model;
  }

  @override
  Future<WalletModel> updateWallet(WalletModel wallet) async {
    await _cache.put(_box, wallet.id!, wallet.toJson());
    return wallet;
  }

  @override
  Future<void> deleteWallet(String id) async {
    await _cache.delete(_box, id);
  }
}
