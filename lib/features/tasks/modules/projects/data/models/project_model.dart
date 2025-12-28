import '../../domain/entities/project.dart';

/// Project model - Data transfer object for Supabase
class ProjectModel extends Project {
  ProjectModel({
    super.id,
    required super.name,
    super.description,
    super.color,
    super.createdAt,
    super.updatedAt,
    super.isArchived,
    super.userId,
  });

  /// Convert from domain entity to model
  factory ProjectModel.fromEntity(Project project) {
    return ProjectModel(
      id: project.id,
      name: project.name,
      description: project.description,
      color: project.color,
      createdAt: project.createdAt,
      updatedAt: project.updatedAt,
      isArchived: project.isArchived,
      userId: project.userId,
    );
  }

  /// Convert from Supabase JSON
  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: json['color'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isArchived: json['is_archived'] as bool? ?? false,
      userId: json['user_id'] as String?,
    );
  }

  /// Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (color != null) 'color': color,
      'is_archived': isArchived,
      if (userId != null) 'user_id': userId,
    };
  }
}
