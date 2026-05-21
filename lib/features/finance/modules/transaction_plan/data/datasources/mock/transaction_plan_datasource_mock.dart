import 'package:keep_track/features/finance/modules/transaction/domain/entities/transaction.dart';
import 'package:keep_track/features/finance/modules/transaction_plan/data/datasources/transaction_plan_datasource.dart';
import 'package:keep_track/features/finance/modules/transaction_plan/data/models/transaction_plan_model.dart';
import 'package:keep_track/features/finance/modules/transaction_plan/domain/entities/transaction_plan.dart';

final _plans = <TransactionPlanModel>[
  TransactionPlanModel(
    id: 'tp-salary-june',
    userId: 'demo',
    description: 'June Salary',
    amount: 5000,
    type: TransactionType.income,
    plannedDate: DateTime(2026, 6, 1),
    status: TransactionPlanStatus.pending,
    financeCategoryId: 'cat-salary',
    budgetId: 'budget-inc-1',
  ),
  TransactionPlanModel(
    id: 'tp-cc-bill',
    userId: 'demo',
    description: 'Credit Card Bill — May',
    amount: 450,
    type: TransactionType.expense,
    plannedDate: DateTime(2026, 6, 5),
    status: TransactionPlanStatus.pending,
    financeCategoryId: 'cat-shopping',
  ),
  TransactionPlanModel(
    id: 'tp-freelance-june',
    userId: 'demo',
    description: 'Freelance Invoice — Client XYZ',
    amount: 800,
    type: TransactionType.income,
    plannedDate: DateTime(2026, 6, 15),
    status: TransactionPlanStatus.pending,
    financeCategoryId: 'cat-freelance',
  ),
];

class TransactionPlanDataSourceMock implements TransactionPlanDataSource {
  @override
  Future<List<TransactionPlanModel>> getPlans({String? status}) async {
    if (status == null) return _plans;
    return _plans.where((p) => p.status.name == status).toList();
  }

  @override
  Future<TransactionPlanModel> createPlan(TransactionPlanModel plan) async => plan;

  @override
  Future<TransactionPlanModel> updatePlan(TransactionPlanModel plan) async => plan;

  @override
  Future<void> deletePlan(String id) async {}

  @override
  Future<TransactionPlanModel> cancelPlan(String id) async {
    final plan = _plans.firstWhere((p) => p.id == id);
    return TransactionPlanModel(
      id: plan.id, userId: plan.userId, description: plan.description,
      amount: plan.amount, type: plan.type, plannedDate: plan.plannedDate,
      status: TransactionPlanStatus.cancelled,
    );
  }

  @override
  Future<TransactionPlanModel> completePlan(String id, {double? amount, DateTime? date}) async {
    final plan = _plans.firstWhere((p) => p.id == id);
    return TransactionPlanModel(
      id: plan.id, userId: plan.userId, description: plan.description,
      amount: amount ?? plan.amount, type: plan.type,
      plannedDate: plan.plannedDate, status: TransactionPlanStatus.completed,
      completedAt: date ?? DateTime.now(),
    );
  }
}
