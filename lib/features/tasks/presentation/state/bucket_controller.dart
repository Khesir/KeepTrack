import 'package:keep_track/core/error/result.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/features/tasks/modules/buckets/domain/entities/bucket.dart';
import 'package:keep_track/features/tasks/modules/buckets/domain/repositories/bucket_repository.dart';

/// Controller for managing bucket state and operations
class BucketController extends StreamState<AsyncState<List<Bucket>>> {
  final BucketRepository _repository;

  BucketController(this._repository) : super(const AsyncLoading()) {
    loadBuckets();
  }

  /// Load all buckets
  Future<void> loadBuckets() async {
    await execute(() async {
      return await _repository.getBuckets().then((r) => r.unwrap());
    });
  }

  /// Create a new bucket
  Future<void> createBucket(Bucket bucket) async {
    await execute(() async {
      final created = await _repository.createBucket(bucket).then((r) => r.unwrap());
      final current = data ?? [];
      return [...current, created];
    });
  }

  /// Update an existing bucket
  Future<void> updateBucket(Bucket bucket) async {
    await execute(() async {
      await _repository.updateBucket(bucket).then((r) => r.unwrap());
      await loadBuckets();
      return data ?? [];
    });
  }

  /// Delete a bucket
  Future<void> deleteBucket(String id) async {
    await execute(() async {
      await _repository.deleteBucket(id).then((r) => r.unwrap());
      await loadBuckets();
      return data ?? [];
    });
  }

  /// Archive a bucket (soft delete)
  Future<void> archiveBucket(String id) async {
    final bucket = getBucketFromCurrentState(id);
    if (bucket != null) {
      await updateBucket(bucket.copyWith(isArchive: true));
    }
  }

  /// Unarchive a bucket
  Future<void> unarchiveBucket(String id) async {
    final bucket = getBucketFromCurrentState(id);
    if (bucket != null) {
      await updateBucket(bucket.copyWith(isArchive: false));
    }
  }

  /// Refresh current data
  Future<void> refresh() async {
    await loadBuckets();
  }

  /// Clear all buckets (for testing or reset)
  void clearBuckets() {
    emit(const AsyncData([]));
  }

  /// Get buckets currently in state (if loaded)
  List<Bucket>? get currentBuckets => state is AsyncData<List<Bucket>>
      ? (state as AsyncData<List<Bucket>>).data
      : null;

  /// Get bucket by ID from current state
  Bucket? getBucketFromCurrentState(String id) {
    final buckets = currentBuckets;
    if (buckets == null) return null;

    try {
      return buckets.where((b) => b.id == id).first;
    } catch (e) {
      return null;
    }
  }
}
