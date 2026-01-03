import '../../../finance_category/domain/entities/finance_category_enums.dart';
import 'budget_category.dart';

/// Budget entity - Can be monthly recurring or one-time
///
/// Note: Budget now references transactions by ID instead of embedding them.
/// Use TransactionRepository to fetch transactions for a budget.
class Budget {
  final String? id; // Optional - Supabase auto-generates
  final String month; // Format: YYYY-MM (e.g., "2024-12")
  final String? title; // User-defined budget title (required for one-time budgets)
  final BudgetType budgetType; // Income or Expense budget
  final BudgetPeriodType periodType; // Monthly or One-time
  final List<BudgetCategory> categories;
  final BudgetStatus status;
  final String? notes;
  final String? userId; // User identifier (UUID)
  final String? accountId; // Account identifier (UUID)
  final DateTime? createdAt; // Optional - Supabase auto-generates
  final DateTime? updatedAt; // Optional - Supabase auto-generates
  final DateTime? closedAt;

  const Budget({
    this.id,
    required this.month,
    this.title,
    this.budgetType = BudgetType.expense,
    this.periodType = BudgetPeriodType.monthly,
    this.categories = const [],
    this.status = BudgetStatus.active,
    this.notes,
    this.userId,
    this.accountId,
    this.createdAt,
    this.updatedAt,
    this.closedAt,
  });

  /// Calculate total budgeted amount for a category type
  double getTotalBudgetedByType(CategoryType type) {
    return categories
        .where((cat) => cat.financeCategory?.type == type)
        .fold(0.0, (sum, cat) => sum + cat.targetAmount);
  }

  /// Calculate total budgeted income
  double get totalBudgetedIncome => getTotalBudgetedByType(CategoryType.income);

  /// Calculate total budgeted expenses (expense + investment + savings + transfer)
  double get totalBudgetedExpenses =>
      getTotalBudgetedByType(CategoryType.expense) +
      getTotalBudgetedByType(CategoryType.investment) +
      getTotalBudgetedByType(CategoryType.savings) +
      getTotalBudgetedByType(CategoryType.transfer);

  /// Budget Target = Sum of ALL category targets
  double get budgetTarget {
    return categories.fold(0.0, (sum, cat) => sum + cat.targetAmount);
  }

  /// Calculate total spent amount across all categories (includes fees)
  double get totalSpent {
    return categories.fold(
      0.0,
      (sum, cat) => sum + cat.totalSpent,
    );
  }

  /// Calculate total fees paid across all categories
  double get totalFees {
    return categories.fold(
      0.0,
      (sum, cat) => sum + (cat.feeSpent ?? 0.0),
    );
  }

  /// Calculate total spent on income categories
  double get totalIncomeReceived {
    return categories
        .where((cat) => cat.financeCategory?.type == CategoryType.income)
        .fold(0.0, (sum, cat) => sum + (cat.spentAmount ?? 0.0));
  }

  /// Calculate total spent on expense categories (expense + investment + savings + transfer)
  double get totalExpensesSpent {
    return categories
        .where((cat) =>
            cat.financeCategory?.type == CategoryType.expense ||
            cat.financeCategory?.type == CategoryType.investment ||
            cat.financeCategory?.type == CategoryType.savings ||
            cat.financeCategory?.type == CategoryType.transfer)
        .fold(0.0, (sum, cat) => sum + (cat.spentAmount ?? 0.0));
  }

  /// Remaining budget = budgetTarget - totalSpent
  double get remainingBudget {
    return budgetTarget - totalSpent;
  }

  /// Over-budget check: spent more than planned target
  bool get isOverBudget {
    return totalSpent > budgetTarget;
  }

  /// Surplus/Deficit (only meaningful when budget is closed)
  /// Surplus = Income received > Expenses spent (you have money left)
  /// Deficit = Expenses spent > Income received (you overspent your income)
  double get surplusOrDeficit {
    return totalIncomeReceived - totalExpensesSpent;
  }

  /// Check if budget has surplus (only when closed)
  bool get hasSurplus {
    return status == BudgetStatus.closed && surplusOrDeficit > 0;
  }

  /// Check if budget has deficit (only when closed)
  bool get hasDeficit {
    return status == BudgetStatus.closed && surplusOrDeficit < 0;
  }

  Budget copyWith({
    String? id,
    String? month,
    String? title,
    BudgetType? budgetType,
    BudgetPeriodType? periodType,
    List<BudgetCategory>? categories,
    BudgetStatus? status,
    String? notes,
    String? userId,
    String? accountId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? closedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      month: month ?? this.month,
      title: title ?? this.title,
      budgetType: budgetType ?? this.budgetType,
      periodType: periodType ?? this.periodType,
      categories: categories ?? this.categories,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      closedAt: closedAt ?? this.closedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Budget &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          month == other.month &&
          userId == other.userId &&
          accountId == other.accountId;

  @override
  int get hashCode => Object.hash(id, month, userId, accountId);

  @override
  String toString() =>
      'Budget(id: $id, month: $month, title: $title, type: $budgetType, period: $periodType, userId: $userId, accountId: $accountId, status: $status)';
}

enum BudgetStatus {
  active,
  closed;

  String get displayName {
    switch (this) {
      case BudgetStatus.active:
        return 'Active';
      case BudgetStatus.closed:
        return 'Closed';
    }
  }
}

enum BudgetType {
  income,
  expense;

  String get displayName {
    switch (this) {
      case BudgetType.income:
        return 'Income';
      case BudgetType.expense:
        return 'Expense';
    }
  }
}

enum BudgetPeriodType {
  monthly,
  oneTime;

  String get displayName {
    switch (this) {
      case BudgetPeriodType.monthly:
        return 'Monthly';
      case BudgetPeriodType.oneTime:
        return 'One-Time';
    }
  }

  String get description {
    switch (this) {
      case BudgetPeriodType.monthly:
        return 'Track recurring monthly finances';
      case BudgetPeriodType.oneTime:
        return 'Budget for specific event or project';
    }
  }
}
