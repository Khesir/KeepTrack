import '../../domain/entities/transaction.dart';

/// Transaction model for JSON serialization
class TransactionModel extends Transaction {
  TransactionModel({
    super.id,
    super.accountId,
    super.toAccountId,
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
      toAccountId: transaction.toAccountId,
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

  /// Convert from JSON (NestJS camelCase response)
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String?,
      accountId: json['accountId'] as String?,
      toAccountId: json['toAccountId'] as String?,
      financeCategoryId: json['financeCategoryId'] as String?,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      userId: json['userId'] as String?,
      fee: json['fee'] != null ? (json['fee'] as num).toDouble() : 0.0,
      feeDescription: json['feeDescription'] as String?,
      budgetId: json['budgetId'] as String?,
      debtId: json['debtId'] as String?,
      goalId: json['goalId'] as String?,
      plannedPaymentId: json['plannedPaymentId'] as String?,
      refundedTransactionId: json['refundedTransactionId'] as String?,
    );
  }

  /// NestJS API request body
  Map<String, dynamic> toApiJson() {
    return {
      if (accountId != null) 'accountId': accountId,
      if (toAccountId != null) 'toAccountId': toAccountId,
      if (financeCategoryId != null) 'financeCategoryId': financeCategoryId,
      'amount': amount,
      'type': type.name,
      if (description != null) 'description': description,
      'date': date.toIso8601String(),
      if (notes != null) 'notes': notes,
      'fee': fee,
      if (feeDescription != null) 'feeDescription': feeDescription,
      if (budgetId != null) 'budgetId': budgetId,
      if (debtId != null) 'debtId': debtId,
      if (goalId != null) 'goalId': goalId,
      if (plannedPaymentId != null) 'plannedPaymentId': plannedPaymentId,
      if (refundedTransactionId != null) 'refundedTransactionId': refundedTransactionId,
    };
  }

  /// Cache serialisation (local storage)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (accountId != null) 'accountId': accountId,
      if (toAccountId != null) 'toAccountId': toAccountId,
      if (financeCategoryId != null) 'financeCategoryId': financeCategoryId,
      'amount': amount,
      'type': type.name,
      if (description != null) 'description': description,
      'date': date.toIso8601String(),
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (userId != null) 'userId': userId,
      'fee': fee,
      if (feeDescription != null) 'feeDescription': feeDescription,
      if (budgetId != null) 'budgetId': budgetId,
      if (debtId != null) 'debtId': debtId,
      if (goalId != null) 'goalId': goalId,
      if (plannedPaymentId != null) 'plannedPaymentId': plannedPaymentId,
      if (refundedTransactionId != null) 'refundedTransactionId': refundedTransactionId,
    };
  }

  /// Convert to entity
  Transaction toEntity() {
    return Transaction(
      id: id,
      accountId: accountId,
      toAccountId: toAccountId,
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
