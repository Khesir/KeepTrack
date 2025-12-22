import 'finance_category_enums.dart';

/// Finance category entity
class FinanceCategory {
  final String? id;
  final String name;
  final CategoryType type;
  final bool isArchive;
  final String? userId;
  final DateTime? createdAt; // Optional - Supabase auto-generates
  final DateTime? updatedAt; // Optional - Supabase auto-generates

  FinanceCategory({
    this.id,
    required this.name,
    required this.type,
    this.isArchive = false,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  FinanceCategory copyWith({
    String? id,
    String? name,
    CategoryType? type,
    bool? isArchive,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FinanceCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isArchive: isArchive ?? this.isArchive,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinanceCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FinanceCategory(id: $id, name: $name, type: $type, isArchive: $isArchive, userId: $userId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
