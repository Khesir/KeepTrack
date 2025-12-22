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
  });

  /// Convert from JSON (Supabase response)
  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0,
      targetDate: json['target_date'] != null
          ? DateTime.parse(json['target_date'] as String)
          : null,
      colorHex: json['color_hex'] as String?,
      iconCodePoint: json['icon_code_point'] as String?,
      status: GoalStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => GoalStatus.active,
      ),
      monthlyContribution:
          (json['monthly_contribution'] as num?)?.toDouble() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      userId: json['user_id'] as String?,
    );
  }

  /// Convert to JSON (for Supabase insert/update)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      if (targetDate != null) 'target_date': targetDate!.toIso8601String(),
      if (colorHex != null) 'color_hex': colorHex,
      if (iconCodePoint != null) 'icon_code_point': iconCodePoint,
      'status': status.name,
      'monthly_contribution': monthlyContribution,
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      if (userId != null) 'user_id': userId,
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
    );
  }
}
