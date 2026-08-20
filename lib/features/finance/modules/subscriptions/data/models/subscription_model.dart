import '../../domain/entities/subscription.dart';

class SubscriptionModel extends Subscription {
  SubscriptionModel({
    super.id,
    required super.userId,
    required super.name,
    super.provider,
    required super.amount,
    required super.billingCycle,
    super.status,
    required super.nextBillingDate,
    super.lastBilledDate,
    super.notes,
    super.colorHex,
    super.iconCodePoint,
    super.budgetProfileId,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String?,
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String,
      provider: json['provider'] as String?,
      amount: (json['amount'] as num).toDouble(),
      billingCycle: BillingCycle.values.firstWhere(
        (e) => e.name == json['billingCycle'],
        orElse: () => BillingCycle.monthly,
      ),
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SubscriptionStatus.active,
      ),
      nextBillingDate: DateTime.parse(json['nextBillingDate'] as String),
      lastBilledDate: json['lastBilledDate'] != null
          ? DateTime.parse(json['lastBilledDate'] as String)
          : null,
      notes: json['notes'] as String?,
      colorHex: json['colorHex'] as String?,
      iconCodePoint: json['iconCodePoint']?.toString(),
      budgetProfileId: json['budgetProfileId'] as String?,
    );
  }

  Map<String, dynamic> toApiJson() {
    return {
      'name': name,
      if (provider != null) 'provider': provider,
      'amount': amount,
      'billingCycle': billingCycle.name,
      'status': status.name,
      'nextBillingDate': nextBillingDate.toIso8601String(),
      if (notes != null) 'notes': notes,
      if (colorHex != null) 'colorHex': colorHex,
      if (iconCodePoint != null) 'iconCodePoint': int.tryParse(iconCodePoint!),
      if (budgetProfileId != null) 'budgetProfileId': budgetProfileId,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'name': name,
      if (provider != null) 'provider': provider,
      'amount': amount,
      'billingCycle': billingCycle.name,
      'status': status.name,
      'nextBillingDate': nextBillingDate.toIso8601String(),
      if (lastBilledDate != null) 'lastBilledDate': lastBilledDate!.toIso8601String(),
      if (notes != null) 'notes': notes,
      if (colorHex != null) 'colorHex': colorHex,
      if (iconCodePoint != null) 'iconCodePoint': iconCodePoint,
      if (budgetProfileId != null) 'budgetProfileId': budgetProfileId,
    };
  }

  factory SubscriptionModel.fromEntity(Subscription s) {
    return SubscriptionModel(
      id: s.id,
      userId: s.userId,
      name: s.name,
      provider: s.provider,
      amount: s.amount,
      billingCycle: s.billingCycle,
      status: s.status,
      nextBillingDate: s.nextBillingDate,
      lastBilledDate: s.lastBilledDate,
      notes: s.notes,
      colorHex: s.colorHex,
      iconCodePoint: s.iconCodePoint,
      budgetProfileId: s.budgetProfileId,
    );
  }
}
