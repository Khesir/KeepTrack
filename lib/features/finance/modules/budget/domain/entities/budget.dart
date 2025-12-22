import '../../../finance_category/domain/entities/finance_category_enums.dart';
import 'budget_category.dart';

/// Monthly budget entity
///
/// Note: Budget now references transactions by ID instead of embedding them.
/// Use TransactionRepository to fetch transactions for a budget.
class Budget {
  final String? id; // Optional - Supabase auto-generates
  final String month; // Format: YYYY-MM (e.g., "2024-12")
  final List<BudgetCategory> categories;
  final BudgetStatus status;
  final String? notes;
  final DateTime? createdAt; // Optional - Supabase auto-generates
  final DateTime? updatedAt; // Optional - Supabase auto-generates
  final DateTime? closedAt;

  Budget({
    this.id,
    required this.month,
    this.categories = const [],
    this.status = BudgetStatus.active,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.closedAt,
  });

  /// Calculate total budgeted amount for a category type
  double getTotalBudgetedByType(CategoryType type) {
    return categories
        .where((cat) => cat.type == type)
        .fold(0.0, (sum, cat) => sum + cat.targetAmount);
  }

  /// Calculate total budgeted income
  double get totalBudgetedIncome => getTotalBudgetedByType(CategoryType.income);

  /// Calculate total budgeted expenses
  double get totalBudgetedExpenses =>
      getTotalBudgetedByType(CategoryType.expense) +
      getTotalBudgetedByType(CategoryType.investment) +
      getTotalBudgetedByType(CategoryType.savings);

  /// Calculate budgeted balance
  double get budgetedBalance => totalBudgetedIncome - totalBudgetedExpenses;

  /// Calculate actual amounts from transactions
  /// Use TransactionRepository.getTransactionsByBudget(budget.id) to get transactions
  /// Then calculate totals using transaction amounts

  Budget copyWith({
    String? id,
    String? month,
    List<BudgetCategory>? categories,
    BudgetStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? closedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      month: month ?? this.month,
      categories: categories ?? this.categories,
      status: status ?? this.status,
      notes: notes ?? this.notes,
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
          month == other.month;

  @override
  int get hashCode => Object.hash(id, month);

  @override
  String toString() => 'Budget(id: $id, month: $month, status: $status)';
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
