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

  /// Convert from JSON (Supabase response)
  factory FinanceCategoryModel.fromJson(Map<String, dynamic> json) {
    return FinanceCategoryModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      type: CategoryType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CategoryType.expense,
      ),
      isArchive: json['is_archive'] as bool? ?? false,
      userId: json['user_id'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to JSON (for Supabase insert/update)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type.name,
      'is_archive': isArchive,
      'user_id': userId,
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
