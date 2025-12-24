/// Financial transaction entity (independent of budgets)
class Transaction {
  final String? id; // Optional - Supabase auto-generates
  final String? accountId; // Optional - can be null for cash transactions
  final String? financeCategoryId;
  final double amount;
  final TransactionType type;
  final String? description;
  final DateTime date;
  final String? notes;
  final DateTime? createdAt; // Optional - Supabase auto-generates
  final DateTime? updatedAt; // Optional - Supabase auto-generates
  final String? userId;

  // Context metadata - links to related entities
  final String? debtId; // Link to debt if this transaction is a debt payment
  final String? goalId; // Link to goal if this transaction is a goal contribution
  final String? plannedPaymentId; // Link to planned payment if this transaction fulfills one
  final String? refundedTransactionId; // Link to original transaction if this is a refund

  Transaction({
    this.id,
    this.accountId,
    this.financeCategoryId,
    required this.amount,
    required this.type,
    this.description,
    required this.date,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.userId,
    this.debtId,
    this.goalId,
    this.plannedPaymentId,
    this.refundedTransactionId,
  });

  Transaction copyWith({
    String? id,
    String? accountId,
    String? financeCategoryId,
    double? amount,
    TransactionType? type,
    String? description,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    String? debtId,
    String? goalId,
    String? plannedPaymentId,
    String? refundedTransactionId,
  }) {
    return Transaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      financeCategoryId: financeCategoryId ?? this.financeCategoryId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      description: description ?? this.description,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      debtId: debtId ?? this.debtId,
      goalId: goalId ?? this.goalId,
      plannedPaymentId: plannedPaymentId ?? this.plannedPaymentId,
      refundedTransactionId: refundedTransactionId ?? this.refundedTransactionId,
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
