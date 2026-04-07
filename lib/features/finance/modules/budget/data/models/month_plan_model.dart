import '../../domain/entities/month_plan.dart';
import 'budget_model.dart';

/// MonthPlan model - DTO for Supabase
class MonthPlanModel extends MonthPlan {
  MonthPlanModel({
    super.id,
    required super.month,
    super.userId,
    super.accountId,
    super.notes,
    super.budgets = const [],
    super.budgetIds = const [],
    super.createdAt,
    super.updatedAt,
  });

  /// Create model from entity
  factory MonthPlanModel.fromEntity(MonthPlan plan) {
    return MonthPlanModel(
      id: plan.id,
      month: plan.month,
      userId: plan.userId,
      accountId: plan.accountId,
      notes: plan.notes,
      budgets: plan.budgets,
      createdAt: plan.createdAt,
      updatedAt: plan.updatedAt,
    );
  }

  /// Create model from JSON (NestJS camelCase response, budgets loaded separately)
  factory MonthPlanModel.fromJson(Map<String, dynamic> json) {
    final rawIds = json['budgetIds'];
    final parsedIds = rawIds is List
        ? rawIds.map((e) => e.toString()).toList()
        : <String>[];

    return MonthPlanModel(
      id: json['id'] as String?,
      month: json['month'] as String,
      userId: json['userId'] as String?,
      accountId: json['accountId'] as String?,
      notes: json['notes'] as String?,
      budgets: const [],
      budgetIds: parsedIds,
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
      'month': month,
      if (accountId != null) 'accountId': accountId,
      if (notes != null) 'notes': notes,
    };
  }

  /// Cache serialisation (local storage)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'month': month,
      if (userId != null) 'userId': userId,
      if (accountId != null) 'accountId': accountId,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Return a new model with hydrated budgets attached
  MonthPlanModel withBudgets(List<BudgetModel> newBudgets) {
    return MonthPlanModel(
      id: id,
      month: month,
      userId: userId,
      accountId: accountId,
      notes: notes,
      budgets: newBudgets,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
