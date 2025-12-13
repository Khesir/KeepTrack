import 'budget_category.dart';
import 'budget_record.dart';

/// Monthly budget entity
class Budget {
  final String id;
  final String month; // Format: YYYY-MM (e.g., "2024-12")
  final List<BudgetCategory> categories;
  final List<BudgetRecord> records;
  final BudgetStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? closedAt;

  Budget({
    required this.id,
    required this.month,
    required this.categories,
    this.records = const [],
    this.status = BudgetStatus.active,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.closedAt,
  });

  /// Calculate total budgeted amount for a category type
  double getTotalBudgetedByType(CategoryType type) {
    return categories
        .where((cat) => cat.type == type)
        .fold(0.0, (sum, cat) => sum + cat.targetAmount);
  }

  /// Calculate total actual amount for a category
  double getActualAmountForCategory(String categoryId) {
    return records
        .where((record) => record.categoryId == categoryId)
        .fold(0.0, (sum, record) => sum + record.amount);
  }

  /// Calculate total actual amount by record type
  double getTotalActualByRecordType(RecordType type) {
    return records
        .where((record) => record.type == type)
        .fold(0.0, (sum, record) => sum + record.amount);
  }

  /// Calculate total budgeted income
  double get totalBudgetedIncome =>
      getTotalBudgetedByType(CategoryType.income);

  /// Calculate total budgeted expenses
  double get totalBudgetedExpenses =>
      getTotalBudgetedByType(CategoryType.expense) +
      getTotalBudgetedByType(CategoryType.investment) +
      getTotalBudgetedByType(CategoryType.savings);

  /// Calculate total actual income
  double get totalActualIncome =>
      getTotalActualByRecordType(RecordType.income);

  /// Calculate total actual expenses
  double get totalActualExpenses =>
      getTotalActualByRecordType(RecordType.expense);

  /// Calculate surplus or deficit
  double get balance => totalActualIncome - totalActualExpenses;

  /// Calculate budgeted balance
  double get budgetedBalance =>
      totalBudgetedIncome - totalBudgetedExpenses;

  /// Check if over budget
  bool get isOverBudget => totalActualExpenses > totalBudgetedExpenses;

  /// Check if under budget (surplus)
  bool get hasSurplus => totalActualExpenses < totalBudgetedExpenses;

  /// Get variance (actual - budgeted)
  double get variance => balance - budgetedBalance;

  Budget copyWith({
    String? id,
    String? month,
    List<BudgetCategory>? categories,
    List<BudgetRecord>? records,
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
      records: records ?? this.records,
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
      other is Budget && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

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
