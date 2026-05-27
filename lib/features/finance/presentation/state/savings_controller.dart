import 'package:keep_track/core/error/result.dart';
import 'package:keep_track/core/state/stream_state.dart';
import '../../modules/savings/domain/entities/savings_bucket.dart';
import '../../modules/savings/domain/repositories/savings_repository.dart';

class SavingsController extends StreamState<AsyncState<List<SavingsBucket>>> {
  final SavingsRepository _repository;

  SavingsController(this._repository) : super(const AsyncLoading()) {
    loadSavings();
  }

  Future<void> loadSavings() async {
    await execute(() async {
      return await _repository.getSavingsBuckets().then((r) => r.unwrap());
    });
  }

  Future<void> createSavingsBucket(SavingsBucket bucket) async {
    final created = await _repository.createSavingsBucket(bucket).then((r) => r.unwrap());
    final current = data ?? [];
    emit(AsyncData([...current, created]));
  }

  Future<void> updateSavingsBucket(SavingsBucket bucket) async {
    await _repository.updateSavingsBucket(bucket).then((r) => r.unwrap());
    await loadSavings();
  }

  Future<void> deleteSavingsBucket(String id) async {
    await _repository.deleteSavingsBucket(id).then((r) => r.unwrap());
    await loadSavings();
  }
}
