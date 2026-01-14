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
  Future<void> createBucket({required String name}) async {
    // TODO: Implement Create bucket
  }

  /// Update an existing bucket
  Future<void> updateBucket(Bucket bucket) async {
    // TODO: Implement UpdateBucket
  }

  /// Delete a bucket
  Future<void> deleteBucket(String id) async {
    // TODO: Implement DeleteBucket
  }

  /// Archive a bucket (soft delete)
  Future<void> archiveBucket(String id) async {
    // TODO: Implement ArchiveBucket
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
