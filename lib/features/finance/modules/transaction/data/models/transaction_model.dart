import '../../domain/entities/transaction.dart';

/// Transaction model for JSON serialization
class TransactionModel extends Transaction {
  TransactionModel({
    super.id,
    super.accountId,
    super.categoryId,
    super.budgetId,
    required super.amount,
    required super.type,
    super.description,
    required super.date,
    super.notes,
    super.createdAt,
    super.updatedAt,
  });

  /// Convert from entity
  factory TransactionModel.fromEntity(Transaction transaction) {
    return TransactionModel(
      id: transaction.id,
      accountId: transaction.accountId,
      categoryId: transaction.categoryId,
      budgetId: transaction.budgetId,
      amount: transaction.amount,
      type: transaction.type,
      description: transaction.description,
      date: transaction.date,
      notes: transaction.notes,
      createdAt: transaction.createdAt,
      updatedAt: transaction.updatedAt,
    );
  }

  /// Convert from JSON
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String?,
      accountId: json['account_id'] as String?,
      categoryId: json['category_id'] as String?,
      budgetId: json['budget_id'] as String?,
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
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'account_id': accountId,
      'category_id': categoryId,
      'budget_id': budgetId,
      'amount': amount,
      'type': type.name,
      'description': description,
      'date': date.toIso8601String(),
      'notes': notes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Convert to entity
  Transaction toEntity() {
    return Transaction(
      id: id,
      accountId: accountId,
      categoryId: categoryId,
      budgetId: budgetId,
      amount: amount,
      type: type,
      description: description,
      date: date,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
