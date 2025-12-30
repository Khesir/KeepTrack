import 'package:persona_codex/features/finance/modules/finance_category/domain/entities/finance_category.dart';

/// Budget category entity (Domain)
class BudgetCategory {
  final String? id; // Supabase UUID
  final String budgetId; // FK -> budgets.id
  final String financeCategoryId; // FK -> finance_categories.id
  final String? userId;

  final double targetAmount;

  /// Nullable for partial hydration
  final FinanceCategory? financeCategory;

  // Optional derived / metadata
  final double? spentAmount;
  final double? feeSpent; // Total fees/taxes paid for this category
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BudgetCategory({
    this.id,
    required this.budgetId,
    required this.financeCategoryId,
    required this.targetAmount,
    this.userId,
    this.financeCategory,
    this.spentAmount,
    this.feeSpent,
    this.createdAt,
    this.updatedAt,
  });

  /// Whether this category is fully hydrated
  bool get isHydrated => financeCategory != null;

  /// Total spent including fees (amount + fees)
  double get totalSpent => (spentAmount ?? 0.0) + (feeSpent ?? 0.0);

  BudgetCategory copyWith({
    String? id,
    String? budgetId,
    String? financeCategoryId,
    String? userId,
    double? targetAmount,
    FinanceCategory? financeCategory,
    double? spentAmount,
    double? feeSpent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetCategory(
      id: id ?? this.id,
      budgetId: budgetId ?? this.budgetId,
      financeCategoryId: financeCategoryId ?? this.financeCategoryId,
      userId: userId ?? this.userId,
      targetAmount: targetAmount ?? this.targetAmount,
      financeCategory: financeCategory ?? this.financeCategory,
      spentAmount: spentAmount ?? this.spentAmount,
      feeSpent: feeSpent ?? this.feeSpent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'BudgetCategory(id: $id, budgetId: $budgetId, '
      'category: ${financeCategory?.name ?? financeCategoryId})';
}
