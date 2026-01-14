import 'package:keep_track/core/error/result.dart';
import 'package:keep_track/core/error/failure.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import 'package:keep_track/features/tasks/modules/buckets/domain/entities/bucket.dart';
import 'package:keep_track/features/tasks/modules/buckets/domain/repositories/bucket_repository.dart';

/// Service to initialize default bucket data for new users
class BucketInitializationService {
  final BucketRepository _bucketRepository;

  BucketInitializationService(this._bucketRepository);

  /// Initialize default buckets for a new user
  /// Returns true if initialization was successful, false if user already has buckets
  Future<Result<bool>> initializeDefaultCategories(String userId) async {
    try {
      AppLogger.info('Initializing default buckets for user: $userId');

      // Check if user already has buckets
      final existingResult = await _bucketRepository.getBuckets();
      if (existingResult.isSuccess) {
        final existing = existingResult.dataOrNull ?? [];
        if (existing.isNotEmpty) {
          AppLogger.info(
            'User already has ${existing.length} buckets, skipping initialization',
          );
          return Result.success(false);
        }
      }

      // Define default buckets
      final defaultBuckets = _getDefaultCategories(userId);

      // Create all buckets
      int successCount = 0;
      for (final bucket in defaultBuckets) {
        final result = await _bucketRepository.createBucket(bucket);
        if (result.isSuccess) {
          successCount++;
          AppLogger.info('Created bucket: ${bucket.name}');
        } else {
          AppLogger.warning(
            'Failed to create bucket: ${bucket.name}',
            result.failureOrNull,
          );
        }
      }

      AppLogger.info(
        'Default buckets initialized: $successCount/${defaultBuckets.length} created',
      );
      return Result.success(true);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize default buckets', e, stackTrace);
      return Result.error(
        UnknownFailure(
          message: 'Failed to initialize default buckets',
          stackTrace: stackTrace,
          originalError: e,
        ),
      );
    }
  }

  /// Get list of default buckets
  List<Bucket> _getDefaultCategories(String userId) {
    return [
      Bucket(name: 'Work', userId: userId),
      Bucket(name: 'Personal', userId: userId),
      Bucket(name: 'Shopping', userId: userId),
      Bucket(name: 'Home', userId: userId),
      Bucket(name: 'Health & Fitness', userId: userId),
      Bucket(name: 'Finance', userId: userId),
      Bucket(name: 'Learning', userId: userId),
      Bucket(name: 'Projects', userId: userId),
      Bucket(name: 'Family', userId: userId),
      Bucket(name: 'Social', userId: userId),
      Bucket(name: 'Travel', userId: userId),
      Bucket(name: 'Goals', userId: userId),
      Bucket(name: 'Ideas', userId: userId),
      Bucket(name: 'Errands', userId: userId),
      Bucket(name: 'Other', userId: userId),
    ];
  }
}
