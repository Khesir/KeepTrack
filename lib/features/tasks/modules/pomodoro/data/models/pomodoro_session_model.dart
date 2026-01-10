import '../../domain/entities/pomodoro_session.dart';

/// Pomodoro Session Model - Data transfer object
class PomodoroSessionModel extends PomodoroSession {
  PomodoroSessionModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.durationSeconds,
    required super.startedAt,
    super.endedAt,
    required super.status,
    super.tasksCleared,
  });

  /// Create from entity
  factory PomodoroSessionModel.fromEntity(PomodoroSession session) {
    return PomodoroSessionModel(
      id: session.id,
      userId: session.userId,
      type: session.type,
      durationSeconds: session.durationSeconds,
      startedAt: session.startedAt,
      endedAt: session.endedAt,
      status: session.status,
      tasksCleared: session.tasksCleared,
    );
  }

  /// Convert to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'type': type.name,
      'duration_seconds': durationSeconds,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'status': status.name,
      'tasks_cleared': tasksCleared,
    };
  }

  /// Create from JSON (database response)
  factory PomodoroSessionModel.fromJson(Map<String, dynamic> json) {
    return PomodoroSessionModel(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      type: PomodoroSessionTypeExtension.fromString(json['type'] ?? 'pomodoro'),
      durationSeconds: json['duration_seconds'] ?? 0,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : DateTime.now(),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'])
          : null,
      status: PomodoroSessionStatusExtension.fromString(json['status'] ?? 'running'),
      tasksCleared: (json['tasks_cleared'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  /// Convert to entity
  PomodoroSession toEntity() {
    return PomodoroSession(
      id: id,
      userId: userId,
      type: type,
      durationSeconds: durationSeconds,
      startedAt: startedAt,
      endedAt: endedAt,
      status: status,
      tasksCleared: tasksCleared,
    );
  }
}
