import 'budget.dart';

enum MonthPlanStatus {
  active,
  closed;

  String get displayName => switch (this) {
    MonthPlanStatus.active => 'Active',
    MonthPlanStatus.closed => 'Closed',
  };
}

/// MonthPlan entity - Parent container for all budget groups in a given month.
class MonthPlan {
  final String? id;
  final String? month; // YYYY-MM for monthly plans; null for profile plans
  final String? budgetProfileId; // null for monthly plans; set for profile plans
  final String? userId;
  final String? notes;
  final MonthPlanStatus status;
  final List<Budget> budgets;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final List<String> budgetIds;

  const MonthPlan({
    this.id,
    this.month,
    this.budgetProfileId,
    this.userId,
    this.notes,
    this.status = MonthPlanStatus.active,
    this.budgets = const [],
    this.budgetIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  bool get isClosed => status == MonthPlanStatus.closed;

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
    String? budgetProfileId,
    String? userId,
    String? notes,
    MonthPlanStatus? status,
    List<Budget>? budgets,
    List<String>? budgetIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MonthPlan(
      id: id ?? this.id,
      month: month ?? this.month,
      budgetProfileId: budgetProfileId ?? this.budgetProfileId,
      userId: userId ?? this.userId,
      notes: notes ?? this.notes,
      status: status ?? this.status,
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
