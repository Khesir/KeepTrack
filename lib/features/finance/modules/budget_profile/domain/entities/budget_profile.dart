class BudgetProfile {
  final String? id;
  final String name;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? colorHex;
  final BudgetProfileStatus status;
  final BudgetProfileType profileType;
  final bool isMain;
  final String? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BudgetProfile({
    this.id,
    required this.name,
    this.description,
    this.startDate,
    this.endDate,
    this.colorHex,
    this.status = BudgetProfileStatus.active,
    this.profileType = BudgetProfileType.custom,
    this.isMain = false,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status == BudgetProfileStatus.active;
  bool get isExpired => endDate != null && endDate!.isBefore(DateTime.now());
  bool get isMonthly => profileType == BudgetProfileType.monthly;

  BudgetProfile copyWith({
    String? id, String? name, String? description,
    DateTime? startDate, DateTime? endDate, String? colorHex,
    BudgetProfileStatus? status, BudgetProfileType? profileType,
    bool? isMain,
    String? userId, DateTime? createdAt, DateTime? updatedAt,
  }) => BudgetProfile(
    id: id ?? this.id, name: name ?? this.name,
    description: description ?? this.description,
    startDate: startDate ?? this.startDate, endDate: endDate ?? this.endDate,
    colorHex: colorHex ?? this.colorHex, status: status ?? this.status,
    profileType: profileType ?? this.profileType,
    isMain: isMain ?? this.isMain,
    userId: userId ?? this.userId, createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BudgetProfile && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum BudgetProfileStatus {
  active, completed, archived;

  String get displayName => switch (this) {
    BudgetProfileStatus.active => 'Active',
    BudgetProfileStatus.completed => 'Completed',
    BudgetProfileStatus.archived => 'Archived',
  };
}

enum BudgetProfileType {
  monthly, custom;

  String get displayName => switch (this) {
    BudgetProfileType.monthly => 'Monthly',
    BudgetProfileType.custom => 'Custom',
  };
}
