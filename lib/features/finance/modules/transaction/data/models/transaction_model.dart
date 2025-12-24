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
    );
  }
}
