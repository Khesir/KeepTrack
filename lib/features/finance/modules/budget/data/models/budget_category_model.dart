import '../../domain/entities/budget_category.dart';

/// BudgetCategory model - DTO for Supabase
class BudgetCategoryModel extends BudgetCategory {
  BudgetCategoryModel({
    super.id,
    required super.budgetId,
    required super.financeCategoryId,
    required super.targetAmount,
    super.userId,
    super.financeCategory,
    super.spentAmount,
    super.feeSpent,
    super.createdAt,
    super.updatedAt,
  });

  /// Create model from entity
  factory BudgetCategoryModel.fromEntity(BudgetCategory entity) {
    return BudgetCategoryModel(
      id: entity.id,
      budgetId: entity.budgetId,
      financeCategoryId: entity.financeCategoryId,
      userId: entity.userId,
      targetAmount: entity.targetAmount,
      financeCategory: entity.financeCategory,
      spentAmount: entity.spentAmount,
      feeSpent: entity.feeSpent,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Create model from JSON (Supabase response)
  factory BudgetCategoryModel.fromJson(Map<String, dynamic> json) {
    return BudgetCategoryModel(
      id: json['id'] as String?,
      budgetId: json['budget_id'] as String,
      financeCategoryId: json['finance_category_id'] as String,
      userId: json['user_id'] as String?,
      targetAmount: (json['target_amount'] as num).toDouble(),
      financeCategory: null, // Hydrated separately
      spentAmount: json['spent_amount'] != null
          ? (json['spent_amount'] as num).toDouble()
          : null,
      feeSpent: json['fee_spent'] != null
          ? (json['fee_spent'] as num).toDouble()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert model to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'budget_id': budgetId,
      'finance_category_id': financeCategoryId,
      if (userId != null) 'user_id': userId,
      'target_amount': targetAmount,
      if (spentAmount != null) 'spent_amount': spentAmount,
      if (feeSpent != null) 'fee_spent': feeSpent,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
