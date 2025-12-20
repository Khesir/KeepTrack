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
    super.accountId,
    super.status,
    super.notes,
    super.createdAt,
    super.updatedAt,
  });

  /// Convert from JSON (Supabase response)
  factory PlannedPaymentModel.fromJson(Map<String, dynamic> json) {
    return PlannedPaymentModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      payee: json['payee'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: PaymentCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => PaymentCategory.other,
      ),
      frequency: PaymentFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => PaymentFrequency.monthly,
      ),
      nextPaymentDate: DateTime.parse(json['next_payment_date'] as String),
      lastPaymentDate: json['last_payment_date'] != null
          ? DateTime.parse(json['last_payment_date'] as String)
          : null,
      accountId: json['account_id'] as String?,
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.active,
      ),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to JSON (for Supabase insert/update)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'payee': payee,
      'amount': amount,
      'category': category.name,
      'frequency': frequency.name,
      'next_payment_date': nextPaymentDate.toIso8601String(),
      if (lastPaymentDate != null)
        'last_payment_date': lastPaymentDate!.toIso8601String(),
      if (accountId != null) 'account_id': accountId,
      'status': status.name,
      if (notes != null) 'notes': notes,
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
      accountId: payment.accountId,
      status: payment.status,
      notes: payment.notes,
      createdAt: payment.createdAt,
      updatedAt: payment.updatedAt,
    );
  }
}
