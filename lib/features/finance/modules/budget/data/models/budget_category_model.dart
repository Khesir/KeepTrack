import '../../domain/entities/budget_category.dart';

/// BudgetCategory model - DTO for Supabase
class BudgetCategoryModel {
  final String? id;
  final String budgetId;
  final String financeCategoryId;
  final String? userId;
  final double targetAmount;

  final double? spentAmount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BudgetCategoryModel({
    this.id,
    required this.budgetId,
    required this.financeCategoryId,
    required this.targetAmount,
    this.userId,
    this.spentAmount,
    this.createdAt,
    this.updatedAt,
  });

  /// Entity → Model
  factory BudgetCategoryModel.fromEntity(BudgetCategory entity) {
    return BudgetCategoryModel(
      id: entity.id,
      budgetId: entity.budgetId,
      financeCategoryId: entity.financeCategoryId,
      userId: entity.userId,
      targetAmount: entity.targetAmount,
      spentAmount: entity.spentAmount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Model → Entity (PARTIAL)
  BudgetCategory toEntity() {
    return BudgetCategory(
      id: id,
      budgetId: budgetId,
      financeCategoryId: financeCategoryId,
      userId: userId,
      targetAmount: targetAmount,
      financeCategory: null, // hydrated later
      spentAmount: spentAmount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Supabase → Model
  factory BudgetCategoryModel.fromJson(Map<String, dynamic> json) {
    return BudgetCategoryModel(
      id: json['id'] as String?,
      budgetId: json['budget_id'] as String,
      financeCategoryId: json['finance_category_id'] as String,
      userId: json['user_id'] as String?,
      targetAmount: (json['target_amount'] as num).toDouble(),
      spentAmount: json['spent_amount'] != null
          ? (json['spent_amount'] as num).toDouble()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Model → Supabase
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'budget_id': budgetId,
      'finance_category_id': financeCategoryId,
      if (userId != null) 'user_id': userId,
      'target_amount': targetAmount,
      if (spentAmount != null) 'spent_amount': spentAmount,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
