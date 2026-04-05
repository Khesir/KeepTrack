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
    super.customTargetAmount,
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
      customTargetAmount: budget.customTargetAmount,
      userId: budget.userId,
      accountId: budget.accountId,
      createdAt: budget.createdAt,
      updatedAt: budget.updatedAt,
      closedAt: budget.closedAt,
    );
  }

  /// Create model from JSON (NestJS camelCase response)
  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String?,
      month: json['month'] as String,
      title: json['title'] as String?,
      budgetType: json['budgetType'] != null
          ? BudgetType.values.firstWhere(
              (e) => e.name == (json['budgetType'] as String),
              orElse: () => BudgetType.expense,
            )
          : BudgetType.expense,
      periodType: json['periodType'] != null
          ? BudgetPeriodType.values.firstWhere(
              (e) => e.name == (json['periodType'] as String),
              orElse: () => BudgetPeriodType.monthly,
            )
          : BudgetPeriodType.monthly,
      categories: const [], // Categories loaded separately
      status: BudgetStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String),
        orElse: () => BudgetStatus.active,
      ),
      notes: json['notes'] as String?,
      customTargetAmount: json['customTargetAmount'] != null
          ? (json['customTargetAmount'] as num).toDouble()
          : null,
      userId: json['userId'] as String?,
      accountId: json['accountId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      closedAt: json['closedAt'] != null
          ? DateTime.parse(json['closedAt'] as String)
          : null,
    );
  }

  /// NestJS API request body
  Map<String, dynamic> toApiJson() {
    return {
      'month': month,
      if (title != null) 'title': title,
      'budgetType': budgetType.name,
      'periodType': periodType.name,
      'status': status.name,
      if (notes != null) 'notes': notes,
      if (customTargetAmount != null) 'customTargetAmount': customTargetAmount,
      if (accountId != null) 'accountId': accountId,
    };
  }

  /// Cache serialisation (local storage)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'month': month,
      if (title != null) 'title': title,
      'budgetType': budgetType.name,
      'periodType': periodType.name,
      'status': status.name,
      if (notes != null) 'notes': notes,
      if (customTargetAmount != null) 'customTargetAmount': customTargetAmount,
      if (userId != null) 'userId': userId,
      if (accountId != null) 'accountId': accountId,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (closedAt != null) 'closedAt': closedAt!.toIso8601String(),
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
      customTargetAmount: customTargetAmount,
      userId: userId,
      accountId: accountId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      closedAt: closedAt,
    );
  }
}
