/// Project entity - Pure domain model
class Project {
  final String? id; // Optional - Supabase auto-generates
  final String name;
  final String? description;
  final String? color;
  final DateTime? createdAt; // Optional - Supabase auto-generates
  final DateTime? updatedAt; // Optional - Supabase auto-generates
  final bool isArchived;

  Project({
    this.id,
    required this.name,
    this.description,
    this.color,
    this.createdAt,
    this.updatedAt,
    this.isArchived = false,
  });

  /// Copy with method for immutability
  Project copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Project &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'Project(id: $id, name: $name)';
}
