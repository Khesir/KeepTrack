import '../../domain/entities/project.dart';

/// Project model - Data transfer object for Supabase
class ProjectModel {
  final String? id; // Optional - Supabase auto-generates
  final String name;
  final String? description;
  final String? color;
  final DateTime? createdAt; // Optional - Supabase auto-generates
  final DateTime? updatedAt; // Optional - Supabase auto-generates
  final bool isArchived;

  ProjectModel({
    this.id,
    required this.name,
    this.description,
    this.color,
    this.createdAt,
    this.updatedAt,
    this.isArchived = false,
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
    );
  }

  /// Convert from model to domain entity
  Project toEntity() {
    return Project(
      id: id,
      name: name,
      description: description,
      color: color,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isArchived: isArchived,
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
    );
  }

  /// Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (color != null) 'color': color,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      'is_archived': isArchived,
    };
  }
}
