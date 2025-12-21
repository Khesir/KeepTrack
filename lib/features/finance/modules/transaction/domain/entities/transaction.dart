/// Financial transaction entity (independent of budgets)
class Transaction {
  final String? id; // Optional - Supabase auto-generates
  final String? accountId; // Optional - can be null for cash transactions
  final String? categoryId; // Optional - link to budget category
  final String? budgetId; // Optional - link to budget if part of budget tracking
  final double amount;
  final TransactionType type;
  final String? description;
  final DateTime date;
  final String? notes;
  final DateTime? createdAt; // Optional - Supabase auto-generates
  final DateTime? updatedAt; // Optional - Supabase auto-generates

  Transaction({
    this.id,
    this.accountId,
    this.categoryId,
    this.budgetId,
    required this.amount,
    required this.type,
    this.description,
    required this.date,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  Transaction copyWith({
    String? id,
    String? accountId,
    String? categoryId,
    String? budgetId,
    double? amount,
    TransactionType? type,
    String? description,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      budgetId: budgetId ?? this.budgetId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      description: description ?? this.description,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Transaction(id: $id, amount: $amount, type: $type, date: $date)';
}

enum TransactionType {
  income,
  expense,
  transfer;

  String get displayName {
    switch (this) {
      case TransactionType.income:
        return 'Income';
      case TransactionType.expense:
        return 'Expense';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }
}
