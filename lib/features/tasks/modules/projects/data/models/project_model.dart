import 'dart:convert';
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
    super.status,
    super.metadata,
    super.bucketId,
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
      status: project.status,
      metadata: project.metadata,
      bucketId: project.bucketId,
    );
  }

  /// Convert from Supabase JSON
  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    // Parse status from string
    ProjectStatus status = ProjectStatus.active;
    if (json['status'] != null) {
      final statusStr = json['status'] as String;
      status = ProjectStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => ProjectStatus.active,
      );
    }

    // Parse metadata from JSON string or map
    Map<String, String> metadata = {};
    if (json['metadata'] != null) {
      if (json['metadata'] is String) {
        final decoded = jsonDecode(json['metadata'] as String);
        metadata = Map<String, String>.from(decoded as Map);
      } else if (json['metadata'] is Map) {
        metadata = Map<String, String>.from(json['metadata'] as Map);
      }
    }

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
      status: status,
      metadata: metadata,
      bucketId: json['bucket_id'] as String?,
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
      'status': status.name,
      'metadata': metadata.isNotEmpty ? jsonEncode(metadata) : null,
      if (bucketId != null) 'bucket_id': bucketId,
    };
  }
}
