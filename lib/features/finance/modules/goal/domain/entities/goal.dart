/// Financial goal entity for tracking savings targets
class Goal {
  final String? id; // Optional - Supabase auto-generates
  final String name;
  final String description;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final String? colorHex; // Store color as hex string (e.g., "#FF5722")
  final String? iconCodePoint; // Store icon as code point
  final GoalStatus status;
  final double monthlyContribution;
  final DateTime? createdAt; // Optional - Supabase auto-generates
  final DateTime? updatedAt; // Optional - Supabase auto-generates
  final DateTime? completedAt;
  final String? userId;
  Goal({
    this.id,
    required this.name,
    required this.description,
    required this.targetAmount,
    this.currentAmount = 0,
    this.targetDate,
    this.colorHex,
    this.iconCodePoint,
    this.status = GoalStatus.active,
    this.monthlyContribution = 0,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.userId,
  });

  /// Calculate progress percentage (0.0 to 1.0)
  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  /// Calculate remaining amount to reach goal
  double get remainingAmount =>
      (targetAmount - currentAmount).clamp(0.0, double.infinity);

  /// Check if goal is completed
  bool get isCompleted => currentAmount >= targetAmount;

  /// Calculate days remaining until target date
  int? get daysRemaining => targetDate?.difference(DateTime.now()).inDays;

  Goal copyWith({
    String? id,
    String? name,
    String? description,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? colorHex,
    String? iconCodePoint,
    GoalStatus? status,
    double? monthlyContribution,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    String? userId,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      colorHex: colorHex ?? this.colorHex,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      status: status ?? this.status,
      monthlyContribution: monthlyContribution ?? this.monthlyContribution,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      userId: userId ?? this.userId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Goal && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Goal(id: $id, name: $name, progress: ${(progress * 100).toStringAsFixed(1)}%)';
}

enum GoalStatus {
  active,
  completed,
  paused;

  String get displayName {
    switch (this) {
      case GoalStatus.active:
        return 'Active';
      case GoalStatus.completed:
        return 'Completed';
      case GoalStatus.paused:
        return 'Paused';
    }
  }
}
