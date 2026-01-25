import 'package:keep_track/core/error/failure.dart';
import 'package:keep_track/core/error/result.dart';

import '../../domain/entities/bucket.dart';
import '../../domain/repositories/bucket_repository.dart';
import '../datasources/bucket_datasource.dart';
import '../datasources/supabase/bucket_datasource_supabase.dart';
import '../models/bucket_model.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';

/// Repository implementation for buckets
class BucketRepositoryImpl implements BucketRepository {
  final BucketDataSource dataSource;

  BucketRepositoryImpl(this.dataSource);

  /// Create repository with Supabase data source
  factory BucketRepositoryImpl.withSupabase(SupabaseService supabase) {
    return BucketRepositoryImpl(BucketDataSourceSupabase(supabase));
  }

  @override
  Future<Result<List<Bucket>>> getBuckets() async {
    final bucketModels = await dataSource.getBuckets();
    final buckets = bucketModels.cast<Bucket>();
    return Result.success(buckets);
  }

  @override
  Future<Result<Bucket>> getBucketById(String id) async {
    final bucket = await dataSource.getBucketById(id);
    if (bucket == null) {
      return Result.error(
        NotFoundFailure(
          resourceType: 'Bucket',
          resourceId: id,
        ),
      );
    }
    return Result.success(bucket);
  }

  @override
  Future<Result<List<Bucket>>> getByIds(List<String> ids) async {
    final bucketModels = await dataSource.getByIds(ids);
    final buckets = bucketModels.cast<Bucket>();
    return Result.success(buckets);
  }

  @override
  Future<Result<Bucket>> createBucket(Bucket bucket) async {
    final model = BucketModel.fromEntity(bucket);
    final created = await dataSource.createBucket(model);
    return Result.success(created);
  }

  @override
  Future<Result<Bucket>> updateBucket(Bucket bucket) async {
    if (bucket.id == null) {
      return Result.error(
        ValidationFailure('Bucket ID is required for updates'),
      );
    }

    final model = BucketModel.fromEntity(bucket);
    final updated = await dataSource.updateBucket(model);
    return Result.success(updated);
  }

  @override
  Future<Result<void>> deleteBucket(String id) async {
    await dataSource.deleteBucket(id);
    return Result.success(null);
  }
}