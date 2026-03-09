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

  /// Create model from Supabase JSON row (budgets loaded separately)
  factory MonthPlanModel.fromJson(Map<String, dynamic> json) {
    return MonthPlanModel(
      id: json['id'] as String?,
      month: json['month'] as String,
      userId: json['user_id'] as String?,
      accountId: json['account_id'] as String?,
      notes: json['notes'] as String?,
      budgets: const [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to JSON for Supabase insert/update
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'month': month,
      if (userId != null) 'user_id': userId,
      if (accountId != null) 'account_id': accountId,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
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
