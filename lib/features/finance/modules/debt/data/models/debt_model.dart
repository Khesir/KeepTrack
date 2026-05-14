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
    super.transactionId,
    super.monthlyPaymentAmount,
    super.feeAmount,
    super.nextPaymentDate,
    super.paymentFrequency,
  });

  /// Convert from JSON (NestJS camelCase response)
  factory DebtModel.fromJson(Map<String, dynamic> json) {
    return DebtModel(
      id: json['id'] as String?,
      type: DebtType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DebtType.borrowing,
      ),
      personName: json['personName'] as String? ?? '',
      description: json['description'] as String? ?? '',
      originalAmount: (json['originalAmount'] as num).toDouble(),
      remainingAmount: (json['remainingAmount'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      status: DebtStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DebtStatus.active,
      ),
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      settledAt: json['settledAt'] != null
          ? DateTime.parse(json['settledAt'] as String)
          : null,
      userId: json['userId'] as String?,
      transactionId: json['transactionId'] as String?,
      monthlyPaymentAmount:
          (json['monthlyPaymentAmount'] as num?)?.toDouble() ?? 0,
      feeAmount: (json['feeAmount'] as num?)?.toDouble() ?? 0,
      nextPaymentDate: json['nextPaymentDate'] != null
          ? DateTime.parse(json['nextPaymentDate'] as String)
          : null,
      paymentFrequency: PaymentFrequency.values.firstWhere(
        (e) => e.name == json['paymentFrequency'],
        orElse: () => PaymentFrequency.monthly,
      ),
    );
  }

  /// NestJS API request body
  Map<String, dynamic> toApiJson() {
    return {
      'type': type.name,
      'personName': personName,
      'description': description,
      'originalAmount': originalAmount,
      'remainingAmount': remainingAmount,
      'startDate': startDate.toIso8601String(),
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      'status': status.name,
      if (notes != null) 'notes': notes,
      if (settledAt != null) 'settledAt': settledAt!.toIso8601String(),
      if (transactionId != null) 'transactionId': transactionId,
      'monthlyPaymentAmount': monthlyPaymentAmount,
      'feeAmount': feeAmount,
      if (nextPaymentDate != null) 'nextPaymentDate': nextPaymentDate!.toIso8601String(),
      'paymentFrequency': paymentFrequency.name,
    };
  }

  /// Cache serialisation (local storage)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'type': type.name,
      'personName': personName,
      'description': description,
      'originalAmount': originalAmount,
      'remainingAmount': remainingAmount,
      'startDate': startDate.toIso8601String(),
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      'status': status.name,
      if (notes != null) 'notes': notes,
      if (settledAt != null) 'settledAt': settledAt!.toIso8601String(),
      if (userId != null) 'userId': userId,
      if (transactionId != null) 'transactionId': transactionId,
      'monthlyPaymentAmount': monthlyPaymentAmount,
      'feeAmount': feeAmount,
      if (nextPaymentDate != null) 'nextPaymentDate': nextPaymentDate!.toIso8601String(),
      'paymentFrequency': paymentFrequency.name,
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
      transactionId: debt.transactionId,
      monthlyPaymentAmount: debt.monthlyPaymentAmount,
      feeAmount: debt.feeAmount,
      nextPaymentDate: debt.nextPaymentDate,
      paymentFrequency: debt.paymentFrequency,
    );
  }
}
