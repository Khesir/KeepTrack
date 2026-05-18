import 'package:keep_track/core/error/result.dart';
import '../../domain/entities/transaction_plan.dart';
import '../../domain/repositories/transaction_plan_repository.dart';
import '../datasources/transaction_plan_datasource.dart';
import '../models/transaction_plan_model.dart';

class TransactionPlanRepositoryImpl implements TransactionPlanRepository {
  final TransactionPlanDataSource _dataSource;

  TransactionPlanRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<TransactionPlan>>> getPlans({String? status}) async {
    final plans = await _dataSource.getPlans(status: status);
    return Result.success(plans);
  }

  @override
  Future<Result<TransactionPlan>> createPlan(TransactionPlan plan) async {
    final created = await _dataSource.createPlan(TransactionPlanModel.fromEntity(plan));
    return Result.success(created);
  }

  @override
  Future<Result<TransactionPlan>> updatePlan(TransactionPlan plan) async {
    final updated = await _dataSource.updatePlan(TransactionPlanModel.fromEntity(plan));
    return Result.success(updated);
  }

  @override
  Future<Result<void>> deletePlan(String id) async {
    await _dataSource.deletePlan(id);
    return Result.success(null);
  }

  @override
  Future<Result<TransactionPlan>> cancelPlan(String id) async {
    final updated = await _dataSource.cancelPlan(id);
    return Result.success(updated);
  }

  @override
  Future<Result<TransactionPlan>> completePlan(String id, {double? amount, DateTime? date}) async {
    final updated = await _dataSource.completePlan(id, amount: amount, date: date);
    return Result.success(updated);
  }
}
