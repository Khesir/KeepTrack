import '../../domain/entities/month_plan.dart';
import 'budget_model.dart';

/// MonthPlan model - DTO for local cache
class MonthPlanModel extends MonthPlan {
  MonthPlanModel({
    super.id,
    super.month,
    super.budgetProfileId,
    super.userId,
    super.notes,
    super.status = MonthPlanStatus.active,
    super.budgets = const [],
    super.budgetIds = const [],
    super.createdAt,
    super.updatedAt,
  });

  factory MonthPlanModel.fromEntity(MonthPlan plan) {
    return MonthPlanModel(
      id: plan.id,
      month: plan.month,
      budgetProfileId: plan.budgetProfileId,
      userId: plan.userId,
      notes: plan.notes,
      status: plan.status,
      budgets: plan.budgets,
      createdAt: plan.createdAt,
      updatedAt: plan.updatedAt,
    );
  }

  factory MonthPlanModel.fromJson(Map<String, dynamic> json) {
    final rawIds = json['budgetIds'];
    final parsedIds = rawIds is List
        ? rawIds.map((e) => e.toString()).toList()
        : <String>[];

    final rawStatus = json['status'] as String?;
    final status = rawStatus == 'closed'
        ? MonthPlanStatus.closed
        : MonthPlanStatus.active;

    return MonthPlanModel(
      id: json['id'] as String?,
      month: json['month'] as String?,
      budgetProfileId: json['budgetProfileId'] as String?,
      userId: json['userId'] as String?,
      notes: json['notes'] as String?,
      status: status,
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

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (month != null) 'month': month,
      if (budgetProfileId != null) 'budgetProfileId': budgetProfileId,
      if (userId != null) 'userId': userId,
      if (notes != null) 'notes': notes,
      'status': status.name,
      'budgetIds': budgetIds,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  MonthPlanModel withBudgets(List<BudgetModel> newBudgets) {
    return MonthPlanModel(
      id: id,
      month: month,
      userId: userId,
      notes: notes,
      status: status,
      budgets: newBudgets,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
