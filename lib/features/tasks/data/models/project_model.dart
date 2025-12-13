import '../../domain/entities/project.dart';

/// Project model - Data transfer object for database
class ProjectModel {
  final String id;
  final String name;
  final String? description;
  final String? color;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;

  ProjectModel({
    required this.id,
    required this.name,
    this.description,
    this.color,
    required this.createdAt,
    required this.updatedAt,
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

  /// Convert from MongoDB document
  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: json['color'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isArchived: json['isArchived'] as bool? ?? false,
    );
  }

  /// Convert to MongoDB document
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isArchived': isArchived,
    };
  }
}
