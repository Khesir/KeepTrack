import 'package:keep_track/core/cache/local_cache.dart';
import 'package:keep_track/features/finance/modules/goal/data/datasources/goal_datasource.dart';
import 'package:keep_track/features/finance/modules/goal/data/models/goal_model.dart';
import 'package:uuid/uuid.dart';

class GoalDataSourceLocal implements GoalDataSource {
  final LocalCache _cache;
  final _uuid = const Uuid();

  static const _box = 'goals';

  GoalDataSourceLocal(this._cache);

  Future<List<GoalModel>> _getAll() async {
    final entries = await _cache.getAll(_box);
    return entries.map((e) => GoalModel.fromJson(e)).toList();
  }

  @override
  Future<List<GoalModel>> fetchGoals({String? budgetProfileId}) async {
    final all = await _getAll();
    if (budgetProfileId == null) return all;
    return all.where((g) => g.budgetProfileId == budgetProfileId).toList();
  }

  @override
  Future<GoalModel?> fetchGoalById(String id) async {
    final data = await _cache.get(_box, id);
    if (data == null) return null;
    return GoalModel.fromJson(data);
  }

  @override
  Future<GoalModel> createGoal(GoalModel goal) async {
    final id = goal.id ?? _uuid.v4();
    final model = GoalModel.fromJson({...goal.toJson(), 'id': id});
    await _cache.put(_box, id, model.toJson());
    return model;
  }

  @override
  Future<GoalModel> updateGoal(GoalModel goal) async {
    await _cache.put(_box, goal.id!, goal.toJson());
    return goal;
  }

  @override
  Future<void> deleteGoal(String id) async {
    await _cache.delete(_box, id);
  }

  @override
  Future<List<GoalModel>> fetchGoalsByStatus(String status) async {
    final all = await _getAll();
    return all.where((g) => g.status.name == status).toList();
  }

  Future<GoalModel> contributeToGoal(String id, double amount) async {
    final goal = await fetchGoalById(id);
    if (goal == null) throw Exception('Goal not found: $id');
    final updated = GoalModel.fromJson({
      ...goal.toJson(),
      'currentAmount': goal.currentAmount + amount,
    });
    return updateGoal(updated);
  }

  Future<GoalModel> withdrawFromGoal(String id, double amount) async {
    final goal = await fetchGoalById(id);
    if (goal == null) throw Exception('Goal not found: $id');
    final updated = GoalModel.fromJson({
      ...goal.toJson(),
      'currentAmount': (goal.currentAmount - amount).clamp(0, double.infinity),
    });
    return updateGoal(updated);
  }
}
