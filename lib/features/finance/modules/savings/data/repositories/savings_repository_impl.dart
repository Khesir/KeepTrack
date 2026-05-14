import 'package:keep_track/core/error/result.dart';
import '../../domain/entities/savings_bucket.dart';
import '../../domain/repositories/savings_repository.dart';
import '../datasources/savings_datasource.dart';
import '../models/savings_bucket_model.dart';

class SavingsRepositoryImpl implements SavingsRepository {
  final SavingsDataSource _dataSource;

  SavingsRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<SavingsBucket>>> getSavingsBuckets() async {
    final buckets = await _dataSource.getSavingsBuckets();
    return Result.success(buckets);
  }

  @override
  Future<Result<SavingsBucket>> createSavingsBucket(SavingsBucket bucket) async {
    final created = await _dataSource.createSavingsBucket(SavingsBucketModel.fromEntity(bucket));
    return Result.success(created);
  }

  @override
  Future<Result<SavingsBucket>> updateSavingsBucket(SavingsBucket bucket) async {
    final updated = await _dataSource.updateSavingsBucket(SavingsBucketModel.fromEntity(bucket));
    return Result.success(updated);
  }

  @override
  Future<Result<void>> deleteSavingsBucket(String id) async {
    await _dataSource.deleteSavingsBucket(id);
    return Result.success(null);
  }
}
