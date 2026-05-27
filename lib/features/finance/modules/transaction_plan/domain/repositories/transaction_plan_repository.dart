import 'package:keep_track/core/error/result.dart';
import '../entities/transaction_plan.dart';

abstract class TransactionPlanRepository {
  Future<Result<List<TransactionPlan>>> getPlans({String? status});
  Future<Result<TransactionPlan>> createPlan(TransactionPlan plan);
  Future<Result<TransactionPlan>> updatePlan(TransactionPlan plan);
  Future<Result<void>> deletePlan(String id);
  Future<Result<TransactionPlan>> cancelPlan(String id);
  Future<Result<TransactionPlan>> completePlan(String id, {double? amount, DateTime? date});
}
