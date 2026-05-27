import '../../domain/entities/goal.dart';

class GoalModel extends Goal {
  GoalModel({
    super.id,
    required super.name,
    required super.description,
    required super.targetAmount,
    super.currentAmount,
    super.targetDate,
    super.colorHex,
    super.iconCodePoint,
    super.status,
    super.monthlyContribution,
    super.createdAt,
    super.updatedAt,
    super.completedAt,
    super.userId,
    super.managementFeePercent,
    super.withdrawalFeePercent,
    super.savingsBucketId,
    super.budgetProfileId,
  });

  /// Convert from JSON (NestJS camelCase response)
  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0,
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'] as String)
          : null,
      colorHex: json['colorHex'] as String?,
      iconCodePoint: json['iconCodePoint']?.toString(),
      status: GoalStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => GoalStatus.active,
      ),
      monthlyContribution:
          (json['monthlyContribution'] as num?)?.toDouble() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      userId: json['userId'] as String?,
      managementFeePercent:
          (json['managementFeePercent'] as num?)?.toDouble() ?? 0,
      withdrawalFeePercent:
          (json['withdrawalFeePercent'] as num?)?.toDouble() ?? 0,
      savingsBucketId: json['savingsBucketId'] as String?,
      budgetProfileId: json['budgetProfileId'] as String?,
    );
  }

  /// NestJS API request body
  Map<String, dynamic> toApiJson() {
    return {
      'name': name,
      'description': description,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      if (targetDate != null) 'targetDate': targetDate!.toIso8601String(),
      if (colorHex != null) 'colorHex': colorHex,
      if (iconCodePoint != null) 'iconCodePoint': int.tryParse(iconCodePoint!),
      'status': status.name,
      'monthlyContribution': monthlyContribution,
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      'managementFeePercent': managementFeePercent,
      'withdrawalFeePercent': withdrawalFeePercent,
      if (savingsBucketId != null) 'savingsBucketId': savingsBucketId,
      if (budgetProfileId != null) 'budgetProfileId': budgetProfileId,
    };
  }

  /// Cache serialisation (local storage)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      if (targetDate != null) 'targetDate': targetDate!.toIso8601String(),
      if (colorHex != null) 'colorHex': colorHex,
      if (iconCodePoint != null) 'iconCodePoint': iconCodePoint,
      'status': status.name,
      'monthlyContribution': monthlyContribution,
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      if (userId != null) 'userId': userId,
      'managementFeePercent': managementFeePercent,
      'withdrawalFeePercent': withdrawalFeePercent,
      if (savingsBucketId != null) 'savingsBucketId': savingsBucketId,
      if (budgetProfileId != null) 'budgetProfileId': budgetProfileId,
    };
  }

  /// Convert entity to model
  factory GoalModel.fromEntity(Goal goal) {
    return GoalModel(
      id: goal.id,
      name: goal.name,
      description: goal.description,
      targetAmount: goal.targetAmount,
      currentAmount: goal.currentAmount,
      targetDate: goal.targetDate,
      colorHex: goal.colorHex,
      iconCodePoint: goal.iconCodePoint,
      status: goal.status,
      monthlyContribution: goal.monthlyContribution,
      createdAt: goal.createdAt,
      updatedAt: goal.updatedAt,
      completedAt: goal.completedAt,
      userId: goal.userId,
      managementFeePercent: goal.managementFeePercent,
      withdrawalFeePercent: goal.withdrawalFeePercent,
      savingsBucketId: goal.savingsBucketId,
      budgetProfileId: goal.budgetProfileId,
    );
  }
}
