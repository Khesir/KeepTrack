import '../models/transaction_plan_model.dart';

abstract class TransactionPlanDataSource {
  Future<List<TransactionPlanModel>> getPlans({String? status});
  Future<TransactionPlanModel> createPlan(TransactionPlanModel plan);
  Future<TransactionPlanModel> updatePlan(TransactionPlanModel plan);
  Future<void> deletePlan(String id);
  Future<TransactionPlanModel> cancelPlan(String id);
  Future<TransactionPlanModel> completePlan(String id, {double? amount, DateTime? date});
}
