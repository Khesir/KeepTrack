/// Bucket entity - Task categorization similar to FinanceCategory
class Bucket {
  final String? id;
  final String name;
  final bool isArchive;
  final String? userId;
  final DateTime? createdAt; // Optional - Supabase auto-generates
  final DateTime? updatedAt; // Optional - Supabase auto-generates

  Bucket({
    this.id,
    required this.name,
    this.isArchive = false,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  Bucket copyWith({
    String? id,
    String? name,
    bool? isArchive,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Bucket(
      id: id ?? this.id,
      name: name ?? this.name,
      isArchive: isArchive ?? this.isArchive,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bucket &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Bucket(id: $id, name: $name, isArchive: $isArchive, userId: $userId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}