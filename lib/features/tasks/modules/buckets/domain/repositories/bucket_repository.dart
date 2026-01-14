import 'package:keep_track/core/error/result.dart';

import '../entities/bucket.dart';

/// Repository contract for task buckets
abstract class BucketRepository {
  /// Get all buckets available to the current user
  /// (system + user-created)
  Future<Result<List<Bucket>>> getBuckets();

  /// Get a specific bucket by ID
  Future<Result<Bucket>> getBucketById(String id);

  /// Get multiple buckets by IDs (used for hydration)
  Future<Result<List<Bucket>>> getByIds(List<String> ids);

  /// Create a new user-defined bucket
  Future<Result<Bucket>> createBucket(Bucket bucket);

  /// Update an existing bucket
  Future<Result<Bucket>> updateBucket(Bucket bucket);

  /// Delete a bucket
  Future<Result<void>> deleteBucket(String id);
}