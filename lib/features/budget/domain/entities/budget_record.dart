/// Budget record/transaction entity
class BudgetRecord {
  final String id;
  final String budgetId;
  final String categoryId;
  final double amount;
  final String? description;
  final DateTime date;
  final RecordType type;

  BudgetRecord({
    required this.id,
    required this.budgetId,
    required this.categoryId,
    required this.amount,
    this.description,
    required this.date,
    required this.type,
  });

  BudgetRecord copyWith({
    String? id,
    String? budgetId,
    String? categoryId,
    double? amount,
    String? description,
    DateTime? date,
    RecordType? type,
  }) {
    return BudgetRecord(
      id: id ?? this.id,
      budgetId: budgetId ?? this.budgetId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      type: type ?? this.type,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetRecord &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'BudgetRecord(id: $id, amount: $amount, type: $type, date: $date)';
}

enum RecordType {
  income,
  expense;

  String get displayName {
    switch (this) {
      case RecordType.income:
        return 'Income';
      case RecordType.expense:
        return 'Expense';
    }
  }
}
