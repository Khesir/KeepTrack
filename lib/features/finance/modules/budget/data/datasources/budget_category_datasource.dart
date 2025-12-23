import '../models/budget_category_model.dart';

abstract class BudgetCategoryDataSource {
  Future<List<BudgetCategoryModel>> getCategoriesByBudgetId(String budgetId);
  Future<BudgetCategoryModel> createCategory(BudgetCategoryModel category);
  Future<BudgetCategoryModel> updateCategory(BudgetCategoryModel category);
  Future<void> deleteCategory(String id);
  Future<void> deleteCategoriesByBudgetId(String budgetId);
}
