/// Budget category entity
class BudgetCategory {
  final String id;
  final String name;
  final CategoryType type;
  final double targetAmount;

  BudgetCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.targetAmount,
  });

  BudgetCategory copyWith({
    String? id,
    String? name,
    CategoryType? type,
    double? targetAmount,
  }) {
    return BudgetCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      targetAmount: targetAmount ?? this.targetAmount,
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
  String toString() => 'BudgetCategory(id: $id, name: $name, type: $type)';
}

enum CategoryType {
  income,
  expense,
  investment,
  savings;

  String get displayName {
    switch (this) {
      case CategoryType.income:
        return 'Income';
      case CategoryType.expense:
        return 'Expense';
      case CategoryType.investment:
        return 'Investment';
      case CategoryType.savings:
        return 'Savings';
    }
  }
}
