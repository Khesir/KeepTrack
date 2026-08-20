import 'package:keep_track/features/finance/modules/finance_category/domain/entities/finance_category.dart';

/// Budget category entity (Domain)
class BudgetCategory {
  final String? id; // Supabase UUID
  final String budgetId; // FK -> budgets.id
  final String financeCategoryId; // FK -> finance_categories.id
  final String? userId;

  final double targetAmount;

  /// Calculated client-side from transactions (not stored in DB)
  final double? spentAmount;
  final double? feeSpent;

  /// Nullable for partial hydration
  final FinanceCategory? financeCategory;

  // Optional metadata
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Category Link — at most one of these three is ever set. When set, this
  /// category tracks a specific Subscription/Debt/Goal instead of (or in
  /// addition to) its plain FinanceCategory tag. See CONTEXT.md ("Category
  /// Link").
  final String? subscriptionId;
  final String? debtId;
  final String? goalId;

  /// Snapshot of the linked entity's name at link time, so the row still has
  /// something real to display if the entity is later hard-deleted.
  final String? linkedEntityLabel;

  const BudgetCategory({
    this.id,
    required this.budgetId,
    required this.financeCategoryId,
    required this.targetAmount,
    this.spentAmount,
    this.feeSpent,
    this.userId,
    this.financeCategory,
    this.createdAt,
    this.updatedAt,
    this.subscriptionId,
    this.debtId,
    this.goalId,
    this.linkedEntityLabel,
  });

  /// Whether this category is fully hydrated
  bool get isHydrated => financeCategory != null;

  /// Whether this category has a Category Link to a Subscription, Debt, or Goal.
  bool get isLinked => subscriptionId != null || debtId != null || goalId != null;

  /// Type string for the linked entity, matching the type strings
  /// `EntityLinkPickerSheet` already uses ('subscription' / 'debt_payment' /
  /// 'goal'), or null when unlinked.
  ///
  /// Note: a debt link only ever reports 'debt_payment' here — this entity
  /// alone cannot tell a borrowing Debt from a lending Debt (Receivable)
  /// apart, since it only stores the linked `debtId`, not the Debt's own
  /// `type`. Callers that need the borrowing/lending distinction (e.g. to
  /// pick "Debt" vs "Receivable" for a badge or picker) must look up the
  /// actual `Debt` record via `debtId` and read its `type`, the same way
  /// existing code already does for `Transaction.debtId`.
  String? get linkedEntityType {
    if (subscriptionId != null) return 'subscription';
    if (debtId != null) return 'debt_payment';
    if (goalId != null) return 'goal';
    return null;
  }

  /// Builds a fresh category for a different budget/month, carrying forward
  /// [financeCategoryId], [financeCategory], [targetAmount], and the Category
  /// Link fields — dropping [id], [spentAmount], [feeSpent], and timestamps.
  /// Used when copying a budget forward (e.g. "Copy from previous month").
  BudgetCategory copyForNewBudget({required String newBudgetId}) {
    return BudgetCategory(
      budgetId: newBudgetId,
      financeCategoryId: financeCategoryId,
      targetAmount: targetAmount,
      userId: userId,
      financeCategory: financeCategory,
      subscriptionId: subscriptionId,
      debtId: debtId,
      goalId: goalId,
      linkedEntityLabel: linkedEntityLabel,
    );
  }

  /// Total spent including fees (calculated client-side)
  double get totalSpent => (spentAmount ?? 0.0) + (feeSpent ?? 0.0);

  BudgetCategory copyWith({
    String? id,
    String? budgetId,
    String? financeCategoryId,
    String? userId,
    double? targetAmount,
    double? spentAmount,
    double? feeSpent,
    FinanceCategory? financeCategory,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? subscriptionId,
    String? debtId,
    String? goalId,
    String? linkedEntityLabel,
  }) {
    return BudgetCategory(
      id: id ?? this.id,
      budgetId: budgetId ?? this.budgetId,
      financeCategoryId: financeCategoryId ?? this.financeCategoryId,
      userId: userId ?? this.userId,
      targetAmount: targetAmount ?? this.targetAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      feeSpent: feeSpent ?? this.feeSpent,
      financeCategory: financeCategory ?? this.financeCategory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      debtId: debtId ?? this.debtId,
      goalId: goalId ?? this.goalId,
      linkedEntityLabel: linkedEntityLabel ?? this.linkedEntityLabel,
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
