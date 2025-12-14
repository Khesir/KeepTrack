import 'package:persona_codex/shared/infrastructure/mongodb/mongodb_service.dart';

import '../../models/budget_model.dart';
import '../budget_datasource.dart';

/// MongoDB implementation of BudgetDataSource
class BudgetDataSourceMongoDB implements BudgetDataSource {
  final MongoDBService mongoService;
  static const String collectionName = 'budgets';

  BudgetDataSourceMongoDB(this.mongoService);

  MongoCollection get _collection => mongoService.collection(collectionName);

  @override
  Future<List<BudgetModel>> getBudgets() async {
    final docs = await _collection.find();
    return docs.map((doc) => BudgetModel.fromJson(doc)).toList()
      ..sort((a, b) => b.month.compareTo(a.month)); // Sort by month descending
  }

  @override
  Future<BudgetModel?> getBudgetById(String id) async {
    final doc = await _collection.findOne({'_id': id});
    return doc != null ? BudgetModel.fromJson(doc) : null;
  }

  @override
  Future<BudgetModel?> getBudgetByMonth(String month) async {
    final doc = await _collection.findOne({'month': month});
    return doc != null ? BudgetModel.fromJson(doc) : null;
  }

  @override
  Future<BudgetModel> createBudget(BudgetModel budget) async {
    final doc = budget.toJson();
    await _collection.insertOne(doc);
    return budget;
  }

  @override
  Future<BudgetModel> updateBudget(BudgetModel budget) async {
    final doc = budget.toJson();
    final success = await _collection.updateOne({'_id': budget.id}, doc);

    if (!success) {
      throw Exception('Budget not found: ${budget.id}');
    }

    return budget;
  }

  @override
  Future<void> deleteBudget(String id) async {
    final success = await _collection.deleteOne({'_id': id});

    if (!success) {
      throw Exception('Budget not found: $id');
    }
  }
}
