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
  final String? accountId; // Link to Account
  final PaymentStatus status;
  final String? notes;
  final DateTime? createdAt; // Optional - Supabase auto-generates
  final DateTime? updatedAt; // Optional - Supabase auto-generates

  PlannedPayment({
    this.id,
    required this.name,
    required this.payee,
    required this.amount,
    required this.category,
    required this.frequency,
    required this.nextPaymentDate,
    this.lastPaymentDate,
    this.accountId,
    this.status = PaymentStatus.active,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  /// Check if payment is upcoming (within next 7 days)
  bool get isUpcoming {
    final now = DateTime.now();
    final daysUntil = nextPaymentDate.difference(now).inDays;
    return daysUntil >= 0 && daysUntil <= 7;
  }

  /// Check if payment is overdue
  bool get isOverdue {
    return DateTime.now().isAfter(nextPaymentDate) && status == PaymentStatus.active;
  }

  /// Calculate days until next payment (negative if overdue)
  int get daysUntilPayment => nextPaymentDate.difference(DateTime.now()).inDays;

  PlannedPayment copyWith({
    String? id,
    String? name,
    String? payee,
    double? amount,
    PaymentCategory? category,
    PaymentFrequency? frequency,
    DateTime? nextPaymentDate,
    DateTime? lastPaymentDate,
    String? accountId,
    PaymentStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      accountId: accountId ?? this.accountId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
  String toString() => 'PlannedPayment(id: $id, name: $name, amount: $amount, frequency: ${frequency.name})';
}

enum PaymentCategory {
  bills,
  subscriptions,
  insurance,
  loan,
  rent,
  utilities,
  other;

  String get displayName {
    switch (this) {
      case PaymentCategory.bills:
        return 'Bills';
      case PaymentCategory.subscriptions:
        return 'Subscriptions';
      case PaymentCategory.insurance:
        return 'Insurance';
      case PaymentCategory.loan:
        return 'Loan';
      case PaymentCategory.rent:
        return 'Rent';
      case PaymentCategory.utilities:
        return 'Utilities';
      case PaymentCategory.other:
        return 'Other';
    }
  }
}

enum PaymentFrequency {
  daily,
  weekly,
  biweekly,
  monthly,
  quarterly,
  yearly;

  String get displayName {
    switch (this) {
      case PaymentFrequency.daily:
        return 'Daily';
      case PaymentFrequency.weekly:
        return 'Weekly';
      case PaymentFrequency.biweekly:
        return 'Bi-weekly';
      case PaymentFrequency.monthly:
        return 'Monthly';
      case PaymentFrequency.quarterly:
        return 'Quarterly';
      case PaymentFrequency.yearly:
        return 'Yearly';
    }
  }
}

enum PaymentStatus {
  active,
  paused,
  cancelled;

  String get displayName {
    switch (this) {
      case PaymentStatus.active:
        return 'Active';
      case PaymentStatus.paused:
        return 'Paused';
      case PaymentStatus.cancelled:
        return 'Cancelled';
    }
  }
}
