import '../../domain/entities/transaction.dart';

/// Transaction model for JSON serialization
class TransactionModel extends Transaction {
  TransactionModel({
    super.id,
    super.accountId,
    super.financeCategoryId,
    required super.amount,
    required super.type,
    super.description,
    required super.date,
    super.notes,
    super.createdAt,
    super.updatedAt,
    super.userId,
    super.fee,
    super.feeDescription,
    super.budgetId,
    super.debtId,
    super.goalId,
    super.plannedPaymentId,
    super.refundedTransactionId,
  });

  /// Convert from entity
  factory TransactionModel.fromEntity(Transaction transaction) {
    return TransactionModel(
      id: transaction.id,
      accountId: transaction.accountId,
      financeCategoryId: transaction.financeCategoryId,
      amount: transaction.amount,
      type: transaction.type,
      description: transaction.description,
      date: transaction.date,
      notes: transaction.notes,
      createdAt: transaction.createdAt,
      updatedAt: transaction.updatedAt,
      userId: transaction.userId,
      fee: transaction.fee,
      feeDescription: transaction.feeDescription,
      budgetId: transaction.budgetId,
      debtId: transaction.debtId,
      goalId: transaction.goalId,
      plannedPaymentId: transaction.plannedPaymentId,
      refundedTransactionId: transaction.refundedTransactionId,
    );
  }

  /// Convert from JSON
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String?,
      accountId: json['account_id'] as String?,
      financeCategoryId: json['finance_category_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      userId: json['user_id'] as String?,
      fee: json['fee'] != null ? (json['fee'] as num).toDouble() : 0.0,
      feeDescription: json['fee_description'] as String?,
      budgetId: json['budget_id'] as String?,
      debtId: json['debt_id'] as String?,
      goalId: json['goal_id'] as String?,
      plannedPaymentId: json['planned_payment_id'] as String?,
      refundedTransactionId: json['refunded_transaction_id'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'account_id': accountId,
      'finance_category_id': financeCategoryId,
      'amount': amount,
      'type': type.name,
      'description': description,
      'date': date.toIso8601String(),
      'notes': notes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (userId != null) 'user_id': userId,
      'fee': fee,
      if (feeDescription != null) 'fee_description': feeDescription,
      if (budgetId != null) 'budget_id': budgetId,
      if (debtId != null) 'debt_id': debtId,
      if (goalId != null) 'goal_id': goalId,
      if (plannedPaymentId != null) 'planned_payment_id': plannedPaymentId,
      if (refundedTransactionId != null) 'refunded_transaction_id': refundedTransactionId,
    };
  }

  /// Convert to entity
  Transaction toEntity() {
    return Transaction(
      id: id,
      accountId: accountId,
      financeCategoryId: financeCategoryId,
      amount: amount,
      type: type,
      description: description,
      date: date,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      userId: userId,
      fee: fee,
      feeDescription: feeDescription,
      budgetId: budgetId,
      debtId: debtId,
      goalId: goalId,
      plannedPaymentId: plannedPaymentId,
      refundedTransactionId: refundedTransactionId,
    );
  }
}
