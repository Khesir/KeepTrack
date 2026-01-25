import '../../domain/entities/bucket.dart';

class BucketModel extends Bucket {
  BucketModel({
    required super.id,
    required super.name,
    super.isArchive = false,
    required super.userId,
    super.createdAt,
    super.updatedAt,
  });

  /// Convert from JSON (Supabase response)
  factory BucketModel.fromJson(Map<String, dynamic> json) {
    return BucketModel(
      id: json['id'] as String?,
      name: json['name'] as String,
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
      'is_archive': isArchive,
      'user_id': userId,
    };
  }

  /// Convert entity to model
  factory BucketModel.fromEntity(Bucket bucket) {
    return BucketModel(
      id: bucket.id,
      name: bucket.name,
      isArchive: bucket.isArchive,
      userId: bucket.userId,
      createdAt: bucket.createdAt,
      updatedAt: bucket.updatedAt,
    );
  }

  /// Convert model back to entity
  Bucket toEntity() {
    return Bucket(
      id: id,
      name: name,
      isArchive: isArchive,
      userId: userId,
    );
  }
}