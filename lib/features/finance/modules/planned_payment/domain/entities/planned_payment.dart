import 'payment_enums.dart';

/// Planned payment entity for tracking recurring and scheduled payments
class PlannedPayment {
  final String? id; // Optional - Supabase auto-generates
  final String name;
  final String payee;
  final double amount;
  final PaymentCategory category;
  final PaymentFrequency frequency;
  final DateTime nextPaymentDate;
  final DateTime? lastPaymentDate;
  final DateTime? endDate; // Optional end date - auto-close when reached
  final String? accountId; // Link to Account
  final PaymentStatus status;
  final String? notes;
  final DateTime? createdAt; // Optional - Supabase auto-generates
  final DateTime? updatedAt; // Optional - Supabase auto-generates
  final String? userId;

  // Installment tracking
  final int? totalInstallments; // Total number of installments (null for recurring)
  final int? remainingInstallments; // Remaining installments (null for recurring)

  PlannedPayment({
    this.id,
    required this.name,
    required this.payee,
    required this.amount,
    required this.category,
    required this.frequency,
    required this.nextPaymentDate,
    this.lastPaymentDate,
    this.endDate,
    this.accountId,
    this.status = PaymentStatus.active,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.userId,
    this.totalInstallments,
    this.remainingInstallments,
  });

  /// Check if payment is upcoming (within next 7 days)
  bool get isUpcoming {
    final now = DateTime.now();
    final daysUntil = nextPaymentDate.difference(now).inDays;
    return daysUntil >= 0 && daysUntil <= 7;
  }

  /// Check if payment is overdue
  bool get isOverdue {
    return DateTime.now().isAfter(nextPaymentDate) &&
        status == PaymentStatus.active;
  }

  /// Calculate days until next payment (negative if overdue)
  int get daysUntilPayment => nextPaymentDate.difference(DateTime.now()).inDays;

  /// Check if this is an installment plan (has defined number of payments)
  bool get isInstallmentPlan => totalInstallments != null && totalInstallments! > 0;

  /// Check if all installments are complete
  bool get isInstallmentComplete =>
      isInstallmentPlan && (remainingInstallments == null || remainingInstallments! <= 0);

  /// Get progress of installment (0.0 to 1.0)
  double get installmentProgress {
    if (!isInstallmentPlan) return 0.0;
    if (totalInstallments == null || totalInstallments == 0) return 0.0;
    final paid = totalInstallments! - (remainingInstallments ?? totalInstallments!);
    return paid / totalInstallments!;
  }

  /// Check if end date has been reached
  bool get isEndDateReached {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  /// Check if payment should be auto-closed (installment complete or end date reached)
  bool get shouldAutoClose => isInstallmentComplete || isEndDateReached;

  PlannedPayment copyWith({
    String? id,
    String? name,
    String? payee,
    double? amount,
    PaymentCategory? category,
    PaymentFrequency? frequency,
    DateTime? nextPaymentDate,
    DateTime? lastPaymentDate,
    DateTime? endDate,
    String? accountId,
    PaymentStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    int? totalInstallments,
    int? remainingInstallments,
  }) {
    return PlannedPayment(
      id: id ?? this.id,
      name: name ?? this.name,
      payee: payee ?? this.payee,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      endDate: endDate ?? this.endDate,
      accountId: accountId ?? this.accountId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      totalInstallments: totalInstallments ?? this.totalInstallments,
      remainingInstallments: remainingInstallments ?? this.remainingInstallments,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlannedPayment &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'PlannedPayment(id: $id, name: $name, amount: $amount, frequency: ${frequency.name})';
}
