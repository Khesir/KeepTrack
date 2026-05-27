import 'package:keep_track/core/cache/local_cache.dart';
import 'package:keep_track/features/finance/modules/savings/data/models/savings_bucket_model.dart';
import 'package:uuid/uuid.dart';
import '../savings_datasource.dart';

class SavingsDataSourceLocal implements SavingsDataSource {
  final LocalCache _cache;
  final _uuid = const Uuid();

  static const _box = 'savings_buckets';

  SavingsDataSourceLocal(this._cache);

  Future<List<SavingsBucketModel>> _getAll() async {
    final entries = await _cache.getAll(_box);
    return entries.map((e) => SavingsBucketModel.fromJson(e)).toList();
  }

  @override
  Future<List<SavingsBucketModel>> getSavingsBuckets() async => _getAll();

  @override
  Future<SavingsBucketModel> createSavingsBucket(
    SavingsBucketModel bucket,
  ) async {
    final id = bucket.id ?? _uuid.v4();
    final model = SavingsBucketModel.fromJson({...bucket.toJson(), 'id': id});
    await _cache.put(_box, id, model.toJson());
    return model;
  }

  @override
  Future<SavingsBucketModel> updateSavingsBucket(
    SavingsBucketModel bucket,
  ) async {
    await _cache.put(_box, bucket.id!, bucket.toJson());
    return bucket;
  }

  @override
  Future<void> deleteSavingsBucket(String id) async {
    await _cache.delete(_box, id);
  }
}
