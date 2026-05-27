import '../../domain/entities/budget_profile.dart';

class BudgetProfileModel extends BudgetProfile {
  const BudgetProfileModel({
    super.id, required super.name, super.description,
    super.startDate, super.endDate, super.colorHex,
    super.status, super.profileType, super.isMain,
    super.userId, super.createdAt, super.updatedAt,
  });

  factory BudgetProfileModel.fromJson(Map<String, dynamic> json) => BudgetProfileModel(
    id: json['id'] as String?,
    name: json['name'] as String,
    description: json['description'] as String?,
    startDate: json['startDate'] != null ? DateTime.parse(json['startDate'] as String) : null,
    endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
    colorHex: json['colorHex'] as String?,
    status: BudgetProfileStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => BudgetProfileStatus.active,
    ),
    profileType: BudgetProfileType.values.firstWhere(
      (e) => e.name == (json['profileType'] as String?),
      orElse: () => BudgetProfileType.custom,
    ),
    isMain: json['isMain'] as bool? ?? false,
    userId: json['userId'] as String?,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
  );

  Map<String, dynamic> toApiJson() => {
    'name': name,
    if (description != null) 'description': description,
    if (startDate != null) 'startDate': startDate!.toIso8601String(),
    if (endDate != null) 'endDate': endDate!.toIso8601String(),
    if (colorHex != null) 'colorHex': colorHex,
    'status': status.name,
    'profileType': profileType.name,
  };

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    if (description != null) 'description': description,
    if (startDate != null) 'startDate': startDate!.toIso8601String(),
    if (endDate != null) 'endDate': endDate!.toIso8601String(),
    if (colorHex != null) 'colorHex': colorHex,
    'status': status.name,
    'profileType': profileType.name,
    'isMain': isMain,
    if (userId != null) 'userId': userId,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  factory BudgetProfileModel.fromEntity(BudgetProfile p) => BudgetProfileModel(
    id: p.id, name: p.name, description: p.description,
    startDate: p.startDate, endDate: p.endDate, colorHex: p.colorHex,
    status: p.status, profileType: p.profileType, isMain: p.isMain,
    userId: p.userId, createdAt: p.createdAt, updatedAt: p.updatedAt,
  );
}
