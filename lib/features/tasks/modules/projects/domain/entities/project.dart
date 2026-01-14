/// Project entity - Pure domain model
class Project {
  final String? id; // Optional - Supabase auto-generates
  final String name;
  final String? description;
  final String? color;
  final DateTime? createdAt; // Optional - Supabase auto-generates
  final DateTime? updatedAt; // Optional - Supabase auto-generates
  final bool isArchived;
  final String? userId;
  final ProjectStatus status; // Project status: active, postponed, closed
  final Map<String, String>
  metadata; // Dynamic metadata (e.g., links, ERD, etc.)
  final String? bucketId;

  Project({
    this.id,
    required this.name,
    this.description,
    this.color,
    this.createdAt,
    this.updatedAt,
    this.isArchived = false,
    this.userId,
    this.status = ProjectStatus.active,
    this.metadata = const {},
    this.bucketId,
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
    String? userId,
    ProjectStatus? status,
    Map<String, String>? metadata,
    String? bucketId,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      bucketId: bucketId ?? this.bucketId,
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

enum ProjectStatus {
  active,
  postponed,
  closed;

  String get displayName {
    switch (this) {
      case ProjectStatus.active:
        return 'Active';
      case ProjectStatus.postponed:
        return 'Postponed';
      case ProjectStatus.closed:
        return 'Closed';
    }
  }
}
