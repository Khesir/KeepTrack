import '../../domain/entities/finance_category.dart';
import '../../domain/entities/finance_category_enums.dart';

class FinanceCategoryModel extends FinanceCategory {
  FinanceCategoryModel({
    required super.id,
    required super.name,
    required super.type,
    super.isArchive = false,
    required super.userId,
    super.createdAt,
    super.updatedAt,
  });

  /// Convert from JSON (NestJS camelCase response)
  factory FinanceCategoryModel.fromJson(Map<String, dynamic> json) {
    return FinanceCategoryModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      type: CategoryType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CategoryType.expense,
      ),
      isArchive: json['isArchive'] as bool? ?? false,
      userId: json['userId'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// NestJS API request body
  Map<String, dynamic> toApiJson() {
    return {
      'name': name,
      'type': type.name,
      'isArchive': isArchive,
    };
  }

  /// Cache serialisation (local storage)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type.name,
      'isArchive': isArchive,
      if (userId?.isNotEmpty ?? false) 'userId': userId,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Convert entity to model
  factory FinanceCategoryModel.fromEntity(FinanceCategory category) {
    return FinanceCategoryModel(
      id: category.id,
      name: category.name,
      type: category.type,
      isArchive: category.isArchive,
      userId: category.userId,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
    );
  }

  /// Convert model back to entity
  FinanceCategory toEntity() {
    return FinanceCategory(
      id: id,
      name: name,
      type: type,
      isArchive: isArchive,
      userId: userId,
    );
  }
}
