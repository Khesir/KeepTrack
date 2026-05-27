class Subscription {
  final String? id;
  final String userId;
  final String name;
  final String? provider;
  final double amount;
  final BillingCycle billingCycle;
  final SubscriptionStatus status;
  final DateTime nextBillingDate;
  final DateTime? lastBilledDate;
  final String? budgetCategoryId;
  final String? notes;
  final String? colorHex;
  final String? iconCodePoint;
  final String? budgetProfileId;

  const Subscription({
    this.id,
    required this.userId,
    required this.name,
    this.provider,
    required this.amount,
    required this.billingCycle,
    this.status = SubscriptionStatus.active,
    required this.nextBillingDate,
    this.lastBilledDate,
    this.budgetCategoryId,
    this.notes,
    this.colorHex,
    this.iconCodePoint,
    this.budgetProfileId,
  });

  bool get isUpcoming {
    final daysUntil = nextBillingDate.difference(DateTime.now()).inDays;
    return daysUntil >= 0 && daysUntil <= 7;
  }

  bool get isOverdue => nextBillingDate.isBefore(DateTime.now()) && status == SubscriptionStatus.active;

  double get monthlyEquivalent {
    return switch (billingCycle) {
      BillingCycle.weekly => amount * 4.33,
      BillingCycle.monthly => amount,
      BillingCycle.quarterly => amount / 3,
      BillingCycle.annual => amount / 12,
    };
  }

  Subscription copyWith({
    String? id,
    String? name,
    String? provider,
    double? amount,
    BillingCycle? billingCycle,
    SubscriptionStatus? status,
    DateTime? nextBillingDate,
    DateTime? lastBilledDate,
    String? budgetCategoryId,
    String? notes,
    String? colorHex,
    String? iconCodePoint,
    String? budgetProfileId,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      amount: amount ?? this.amount,
      billingCycle: billingCycle ?? this.billingCycle,
      status: status ?? this.status,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      lastBilledDate: lastBilledDate ?? this.lastBilledDate,
      budgetCategoryId: budgetCategoryId ?? this.budgetCategoryId,
      notes: notes ?? this.notes,
      colorHex: colorHex ?? this.colorHex,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      budgetProfileId: budgetProfileId ?? this.budgetProfileId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Subscription && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum BillingCycle {
  weekly,
  monthly,
  quarterly,
  annual;

  String get displayName => switch (this) {
        weekly => 'Weekly',
        monthly => 'Monthly',
        quarterly => 'Quarterly',
        annual => 'Annual',
      };
}

enum SubscriptionStatus {
  active,
  paused,
  cancelled;

  String get displayName => switch (this) {
        active => 'Active',
        paused => 'Paused',
        cancelled => 'Cancelled',
      };
}
