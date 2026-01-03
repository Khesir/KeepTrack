import '../../domain/entities/budget.dart';
import 'budget_category_model.dart';

/// Budget model - DTO for Supabase
///
/// Note: Categories are loaded separately using BudgetCategoryRepository.
class BudgetModel extends Budget {
  BudgetModel({
    super.id,
    required super.month,
    super.title,
    super.budgetType = BudgetType.expense,
    super.periodType = BudgetPeriodType.monthly,
    super.categories = const [],
    required BudgetStatus status,
    super.notes,
    super.userId,
    super.accountId,
    super.createdAt,
    super.updatedAt,
    super.closedAt,
  }) : super(status: status);

  /// Create model from entity
  factory BudgetModel.fromEntity(Budget budget) {
    return BudgetModel(
      id: budget.id,
      month: budget.month,
      title: budget.title,
      budgetType: budget.budgetType,
      periodType: budget.periodType,
      categories: budget.categories
          .map((cat) => BudgetCategoryModel.fromEntity(cat))
          .toList(),
      status: budget.status,
      notes: budget.notes,
      userId: budget.userId,
      accountId: budget.accountId,
      createdAt: budget.createdAt,
      updatedAt: budget.updatedAt,
      closedAt: budget.closedAt,
    );
  }

  /// Create model from JSON (Supabase response)
  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String?,
      month: json['month'] as String,
      title: json['title'] as String?,
      budgetType: json['budget_type'] != null
          ? BudgetType.values.firstWhere(
              (e) => e.name == (json['budget_type'] as String),
              orElse: () => BudgetType.expense,
            )
          : BudgetType.expense,
      periodType: json['period_type'] != null
          ? BudgetPeriodType.values.firstWhere(
              (e) => e.name == (json['period_type'] as String),
              orElse: () => BudgetPeriodType.monthly,
            )
          : BudgetPeriodType.monthly,
      categories: const [], // Categories loaded separately
      status: BudgetStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String),
      ),
      notes: json['notes'] as String?,
      userId: json['user_id'] as String?,
      accountId: json['account_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      closedAt: json['closed_at'] != null
          ? DateTime.parse(json['closed_at'] as String)
          : null,
    );
  }

  /// Convert model to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'month': month,
      if (title != null) 'title': title,
      'budget_type': budgetType.name,
      'period_type': periodType.name,
      'status': status.name,
      if (notes != null) 'notes': notes,
      if (userId != null) 'user_id': userId,
      if (accountId != null) 'account_id': accountId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (closedAt != null) 'closed_at': closedAt!.toIso8601String(),
    };
  }

  /// Create a new model with updated categories
  BudgetModel withCategories(List<BudgetCategoryModel> newCategories) {
    return BudgetModel(
      id: id,
      month: month,
      title: title,
      budgetType: budgetType,
      periodType: periodType,
      categories: newCategories,
      status: status,
      notes: notes,
      userId: userId,
      accountId: accountId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      closedAt: closedAt,
    );
  }
}
