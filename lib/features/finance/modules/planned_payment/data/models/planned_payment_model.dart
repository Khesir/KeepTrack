import '../../domain/entities/payment_enums.dart';
import '../../domain/entities/planned_payment.dart';

class PlannedPaymentModel extends PlannedPayment {
  PlannedPaymentModel({
    super.id,
    required super.name,
    required super.payee,
    required super.amount,
    required super.category,
    required super.frequency,
    required super.nextPaymentDate,
    super.lastPaymentDate,
    super.endDate,
    super.status,
    super.notes,
    super.createdAt,
    super.updatedAt,
    super.userId,
    super.totalInstallments,
    super.remainingInstallments,
  });

  /// Convert from JSON (NestJS camelCase response)
  factory PlannedPaymentModel.fromJson(Map<String, dynamic> json) {
    return PlannedPaymentModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      payee: json['payee'] as String? ?? '',
      amount: (json['amount'] as num).toDouble(),
      category: PaymentCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => PaymentCategory.other,
      ),
      frequency: PaymentFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => PaymentFrequency.monthly,
      ),
      nextPaymentDate: DateTime.parse(json['nextPaymentDate'] as String),
      lastPaymentDate: json['lastPaymentDate'] != null
          ? DateTime.parse(json['lastPaymentDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.active,
      ),
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      userId: json['userId'] as String?,
      totalInstallments: json['totalInstallments'] as int?,
      remainingInstallments: json['remainingInstallments'] as int?,
    );
  }

  /// NestJS API request body
  Map<String, dynamic> toApiJson() {
    return {
      'name': name,
      'payee': payee,
      'amount': amount,
      'category': category.name,
      'frequency': frequency.name,
      'nextPaymentDate': nextPaymentDate.toIso8601String(),
      if (lastPaymentDate != null) 'lastPaymentDate': lastPaymentDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      'status': status.name,
      if (notes != null) 'notes': notes,
      if (totalInstallments != null) 'totalInstallments': totalInstallments,
      if (remainingInstallments != null) 'remainingInstallments': remainingInstallments,
    };
  }

  /// Cache serialisation (local storage)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'payee': payee,
      'amount': amount,
      'category': category.name,
      'frequency': frequency.name,
      'nextPaymentDate': nextPaymentDate.toIso8601String(),
      if (lastPaymentDate != null) 'lastPaymentDate': lastPaymentDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      'status': status.name,
      if (notes != null) 'notes': notes,
      if (userId != null) 'userId': userId,
      if (totalInstallments != null) 'totalInstallments': totalInstallments,
      if (remainingInstallments != null) 'remainingInstallments': remainingInstallments,
    };
  }

  /// Convert entity to model
  factory PlannedPaymentModel.fromEntity(PlannedPayment payment) {
    return PlannedPaymentModel(
      id: payment.id,
      name: payment.name,
      payee: payment.payee,
      amount: payment.amount,
      category: payment.category,
      frequency: payment.frequency,
      nextPaymentDate: payment.nextPaymentDate,
      lastPaymentDate: payment.lastPaymentDate,
      endDate: payment.endDate,
      status: payment.status,
      notes: payment.notes,
      createdAt: payment.createdAt,
      updatedAt: payment.updatedAt,
      userId: payment.userId,
      totalInstallments: payment.totalInstallments,
      remainingInstallments: payment.remainingInstallments,
    );
  }
}
