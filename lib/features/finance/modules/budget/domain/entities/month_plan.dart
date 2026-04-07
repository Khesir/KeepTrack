import 'budget.dart';

/// MonthPlan entity - Parent container for all budget groups in a given month.
///
/// A MonthPlan groups all Budget objects (income and expense) for a single
/// YYYY-MM month, enabling month-level planning and copying.
class MonthPlan {
  final String? id; // Supabase auto-generated
  final String month; // Format: YYYY-MM (e.g., "2025-03")
  final String? userId;
  final String? accountId;
  final String? notes;
  final List<Budget> budgets; // All budgets for this month
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final List<String> budgetIds; // Raw IDs from month_plan.budgetIds

  const MonthPlan({
    this.id,
    required this.month,
    this.userId,
    this.accountId,
    this.notes,
    this.budgets = const [],
    this.budgetIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// Total planned income across all income budgets
  double get totalPlannedIncome =>
      budgets.fold(0.0, (sum, b) => sum + b.totalBudgetedIncome);

  /// Total planned expenses across all expense budgets
  double get totalPlannedExpenses =>
      budgets.fold(0.0, (sum, b) => sum + b.totalBudgetedExpenses);

  /// Planned balance = planned income - planned expenses
  double get plannedBalance => totalPlannedIncome - totalPlannedExpenses;

  /// Whether any budget in this plan is still active
  bool get hasActiveBudgets =>
      budgets.any((b) => b.status == BudgetStatus.active);

  /// Whether all budgets in this plan are closed
  bool get allBudgetsClosed =>
      budgets.isNotEmpty &&
      budgets.every((b) => b.status == BudgetStatus.closed);

  /// Income budgets only
  List<Budget> get incomeBudgets =>
      budgets.where((b) => b.budgetType == BudgetType.income).toList();

  /// Expense budgets only
  List<Budget> get expenseBudgets =>
      budgets.where((b) => b.budgetType == BudgetType.expense).toList();

  MonthPlan copyWith({
    String? id,
    String? month,
    String? userId,
    String? accountId,
    String? notes,
    List<Budget>? budgets,
    List<String>? budgetIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MonthPlan(
      id: id ?? this.id,
      month: month ?? this.month,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      notes: notes ?? this.notes,
      budgets: budgets ?? this.budgets,
      budgetIds: budgetIds ?? this.budgetIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthPlan &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          month == other.month &&
          userId == other.userId;

  @override
  int get hashCode => Object.hash(id, month, userId);

  @override
  String toString() =>
      'MonthPlan(id: $id, month: $month, budgets: ${budgets.length})';
}
