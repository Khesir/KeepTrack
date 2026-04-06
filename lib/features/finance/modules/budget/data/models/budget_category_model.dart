import 'package:keep_track/features/finance/modules/finance_category/data/models/finance_category_model.dart';

import '../../domain/entities/budget_category.dart';

/// BudgetCategory model
class BudgetCategoryModel extends BudgetCategory {
  BudgetCategoryModel({
    super.id,
    required super.budgetId,
    required super.financeCategoryId,
    required super.targetAmount,
    super.spentAmount,
    super.feeSpent,
    super.userId,
    super.financeCategory,
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
      spentAmount: entity.spentAmount,
      feeSpent: entity.feeSpent,
      financeCategory: entity.financeCategory,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Create model from JSON (NestJS camelCase response).
  /// [financeCategoryId] may be a plain String ID or a populated Map from
  /// the backend `.populate('categories.financeCategoryId')` call.
  factory BudgetCategoryModel.fromJson(Map<String, dynamic> json) {
    final rawFcId = json['financeCategoryId'];
    String financeCategoryId;
    FinanceCategoryModel? fcModel;

    if (rawFcId is Map<String, dynamic>) {
      fcModel = FinanceCategoryModel.fromJson(rawFcId);
      financeCategoryId = fcModel.id ?? '';
    } else {
      financeCategoryId = (rawFcId as String?) ?? '';
    }

    // Support both `id` (transformed) and `_id` (raw Mongoose)
    final id = (json['id'] ?? json['_id']) as String?;

    return BudgetCategoryModel(
      id: id,
      budgetId: json['budgetId'] as String? ?? '',
      financeCategoryId: financeCategoryId,
      userId: json['userId'] as String?,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      financeCategory: fcModel?.toEntity(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// NestJS API request body
  Map<String, dynamic> toApiJson() {
    return {
      'budgetId': budgetId,
      'financeCategoryId': financeCategoryId,
      'targetAmount': targetAmount,
    };
  }

  /// Cache serialisation (local storage)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'budgetId': budgetId,
      'financeCategoryId': financeCategoryId,
      if (userId != null) 'userId': userId,
      'targetAmount': targetAmount,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}
