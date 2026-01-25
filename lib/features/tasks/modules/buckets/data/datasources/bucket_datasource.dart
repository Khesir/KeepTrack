import 'package:keep_track/features/tasks/modules/buckets/data/models/bucket_model.dart';

import '../../domain/entities/bucket.dart';

/// Data source interface for bucket operations
abstract class BucketDataSource {
  /// Get all buckets for a user
  Future<List<Bucket>> getBuckets();

  /// Get a specific bucket by ID
  Future<Bucket?> getBucketById(String id);

  /// Get multiple buckets by IDs
  Future<List<Bucket>> getByIds(List<String> ids);

  /// Create a new bucket
  Future<Bucket> createBucket(BucketModel bucket);

  /// Update an existing bucket
  Future<Bucket> updateBucket(BucketModel bucket);

  /// Delete a bucket
  Future<void> deleteBucket(String id);
}
