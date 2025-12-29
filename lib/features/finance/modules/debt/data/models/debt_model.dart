import '../../domain/entities/debt.dart';

class DebtModel extends Debt {
  DebtModel({
    super.id,
    required super.type,
    required super.personName,
    required super.description,
    required super.originalAmount,
    required super.remainingAmount,
    required super.startDate,
    super.dueDate,
    super.status,
    super.notes,
    super.createdAt,
    super.updatedAt,
    super.settledAt,
    super.userId,
    super.accountId,
    super.transactionId,
  });

  /// Convert from JSON (Supabase response)
  factory DebtModel.fromJson(Map<String, dynamic> json) {
    return DebtModel(
      id: json['id'] as String?,
      type: DebtType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DebtType.borrowing,
      ),
      personName: json['person_name'] as String,
      description: json['description'] as String? ?? '',
      originalAmount: (json['original_amount'] as num).toDouble(),
      remainingAmount: (json['remaining_amount'] as num).toDouble(),
      startDate: DateTime.parse(json['start_date'] as String),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      status: DebtStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DebtStatus.active,
      ),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      settledAt: json['settled_at'] != null
          ? DateTime.parse(json['settled_at'] as String)
          : null,
      userId: json['user_id'] as String?,
      accountId: json['account_id'] as String?,
      transactionId: json['transaction_id'] as String?,
    );
  }

  /// Convert to JSON (for Supabase insert/update)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'type': type.name,
      'person_name': personName,
      'description': description,
      'original_amount': originalAmount,
      'remaining_amount': remainingAmount,
      'start_date': startDate.toIso8601String(),
      if (dueDate != null) 'due_date': dueDate!.toIso8601String(),
      'status': status.name,
      if (notes != null) 'notes': notes,
      if (settledAt != null) 'settled_at': settledAt!.toIso8601String(),
      if (userId != null) 'user_id': userId,
      if (accountId != null) 'account_id': accountId,
      if (transactionId != null) 'transaction_id': transactionId,
    };
  }

  /// Convert entity to model
  factory DebtModel.fromEntity(Debt debt) {
    return DebtModel(
      id: debt.id,
      type: debt.type,
      personName: debt.personName,
      description: debt.description,
      originalAmount: debt.originalAmount,
      remainingAmount: debt.remainingAmount,
      startDate: debt.startDate,
      dueDate: debt.dueDate,
      status: debt.status,
      notes: debt.notes,
      createdAt: debt.createdAt,
      updatedAt: debt.updatedAt,
      settledAt: debt.settledAt,
      userId: debt.userId,
      accountId: debt.accountId,
      transactionId: debt.transactionId,
    );
  }
}
