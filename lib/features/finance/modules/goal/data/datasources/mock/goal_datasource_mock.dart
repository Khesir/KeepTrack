import 'package:keep_track/features/finance/modules/goal/data/datasources/rest/goal_datasource_rest.dart';
import 'package:keep_track/features/finance/modules/goal/data/models/goal_model.dart';
import 'package:keep_track/features/finance/modules/goal/domain/entities/goal.dart';

final _goals = <GoalModel>[
  GoalModel(
    id: 'goal-car',
    name: 'New Car',
    description: 'Saving for a car down payment',
    targetAmount: 25000,
    currentAmount: 8000,
    targetDate: DateTime(2027, 6, 1),
    colorHex: '#E91E63',
    iconCodePoint: '57812',
    status: GoalStatus.active,
    monthlyContribution: 500,
    userId: 'demo',
  ),
  GoalModel(
    id: 'goal-vacation',
    name: 'Europe Vacation',
    description: 'Summer trip to Europe',
    targetAmount: 5000,
    currentAmount: 2300,
    targetDate: DateTime(2026, 12, 1),
    colorHex: '#2196F3',
    iconCodePoint: '58130',
    status: GoalStatus.active,
    monthlyContribution: 300,
    userId: 'demo',
  ),
  GoalModel(
    id: 'goal-macbook',
    name: 'MacBook Pro',
    description: 'Upgrade work laptop',
    targetAmount: 2500,
    currentAmount: 1200,
    targetDate: DateTime(2026, 9, 1),
    colorHex: '#9C27B0',
    iconCodePoint: '57809',
    status: GoalStatus.active,
    monthlyContribution: 200,
    userId: 'demo',
  ),
];

class GoalDataSourceMock extends GoalDataSourceRest {
  @override
  Future<List<GoalModel>> fetchGoals({String? budgetProfileId}) async => _goals;

  @override
  Future<GoalModel?> fetchGoalById(String id) async =>
      _goals.where((g) => g.id == id).firstOrNull;

  @override
  Future<GoalModel> createGoal(GoalModel goal) async => goal;

  @override
  Future<GoalModel> updateGoal(GoalModel goal) async => goal;

  @override
  Future<void> deleteGoal(String id) async {}

  @override
  Future<List<GoalModel>> fetchGoalsByStatus(String status) async =>
      _goals.where((g) => g.status.name == status).toList();

  @override
  Future<GoalModel> contributeToGoal(String id, double amount) async {
    final goal = _goals.firstWhere((g) => g.id == id);
    return GoalModel(
      id: goal.id, name: goal.name, description: goal.description,
      targetAmount: goal.targetAmount, currentAmount: goal.currentAmount + amount,
      targetDate: goal.targetDate, colorHex: goal.colorHex,
      iconCodePoint: goal.iconCodePoint, status: goal.status,
      monthlyContribution: goal.monthlyContribution, userId: goal.userId,
    );
  }

  @override
  Future<GoalModel> withdrawFromGoal(String id, double amount) async {
    final goal = _goals.firstWhere((g) => g.id == id);
    return GoalModel(
      id: goal.id, name: goal.name, description: goal.description,
      targetAmount: goal.targetAmount, currentAmount: (goal.currentAmount - amount).clamp(0, double.infinity),
      targetDate: goal.targetDate, colorHex: goal.colorHex,
      iconCodePoint: goal.iconCodePoint, status: goal.status,
      monthlyContribution: goal.monthlyContribution, userId: goal.userId,
    );
  }
}
