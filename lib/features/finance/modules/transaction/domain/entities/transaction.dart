class Transaction {
  final String? id;
  final String? financeCategoryId;
  final double amount;
  final TransactionType type;
  final String? description;
  final DateTime date;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? userId;

  final double fee;
  final String? feeDescription;

  final String? budgetId;
  final String? budgetProfileId;
  final String? debtId;
  final String? goalId;
  final String? plannedPaymentId;
  final String? refundedTransactionId;
  final String? savingsId;
  final String? subscriptionId;

  Transaction({
    this.id,
    this.financeCategoryId,
    required this.amount,
    required this.type,
    this.description,
    required this.date,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.userId,
    this.fee = 0.0,
    this.feeDescription,
    this.budgetId,
    this.budgetProfileId,
    this.debtId,
    this.goalId,
    this.plannedPaymentId,
    this.refundedTransactionId,
    this.savingsId,
    this.subscriptionId,
  });

  Transaction copyWith({
    String? id,
    String? financeCategoryId,
    double? amount,
    TransactionType? type,
    String? description,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    double? fee,
    String? feeDescription,
    String? budgetId,
    String? budgetProfileId,
    String? debtId,
    String? goalId,
    String? plannedPaymentId,
    String? refundedTransactionId,
    String? savingsId,
    String? subscriptionId,
  }) {
    return Transaction(
      id: id ?? this.id,
      financeCategoryId: financeCategoryId ?? this.financeCategoryId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      description: description ?? this.description,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      fee: fee ?? this.fee,
      feeDescription: feeDescription ?? this.feeDescription,
      budgetId: budgetId ?? this.budgetId,
      budgetProfileId: budgetProfileId ?? this.budgetProfileId,
      debtId: debtId ?? this.debtId,
      goalId: goalId ?? this.goalId,
      plannedPaymentId: plannedPaymentId ?? this.plannedPaymentId,
      refundedTransactionId: refundedTransactionId ?? this.refundedTransactionId,
      savingsId: savingsId ?? this.savingsId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  double get totalCost => amount + fee;

  bool get hasFee => fee > 0;

  @override
  String toString() =>
      'Transaction(id: $id, amount: $amount, fee: $fee, type: $type, date: $date)';
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
