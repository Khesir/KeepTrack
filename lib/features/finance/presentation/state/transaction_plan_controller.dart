import 'package:keep_track/core/error/result.dart';
import 'package:keep_track/core/state/stream_state.dart';
import '../../modules/transaction_plan/domain/entities/transaction_plan.dart';
import '../../modules/transaction_plan/domain/repositories/transaction_plan_repository.dart';

class TransactionPlanController extends StreamState<AsyncState<List<TransactionPlan>>> {
  final TransactionPlanRepository _repository;

  TransactionPlanController(this._repository) : super(const AsyncLoading()) {
    loadPlans();
  }

  Future<void> loadPlans() async {
    await execute(() async {
      return await _repository.getPlans().then((r) => r.unwrap());
    });
  }

  Future<void> createPlan(TransactionPlan plan) async {
    final created = await _repository.createPlan(plan).then((r) => r.unwrap());
    emit(AsyncData([...data ?? [], created]));
  }

  Future<void> updatePlan(TransactionPlan plan) async {
    await _repository.updatePlan(plan).then((r) => r.unwrap());
    await loadPlans();
  }

  Future<void> deletePlan(String id) async {
    await _repository.deletePlan(id).then((r) => r.unwrap());
    await loadPlans();
  }

  Future<void> cancelPlan(String id) async {
    await _repository.cancelPlan(id).then((r) => r.unwrap());
    await loadPlans();
  }

  Future<TransactionPlan> completePlan(String id, {double? amount, DateTime? date}) async {
    final updated = await _repository.completePlan(id, amount: amount, date: date).then((r) => r.unwrap());
    await loadPlans();
    return updated;
  }
}
