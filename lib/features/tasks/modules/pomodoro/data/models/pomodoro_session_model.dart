import '../../domain/entities/pomodoro_session.dart';

/// Pomodoro Session Model - Data transfer object
class PomodoroSessionModel extends PomodoroSession {
  PomodoroSessionModel({
    required super.id,
    required super.userId,
    super.projectId,
    super.title,
    required super.type,
    required super.durationSeconds,
    required super.startedAt,
    super.endedAt,
    super.pausedAt,
    super.elapsedSecondsBeforePause = 0,
    required super.status,
    super.tasksCleared,
    super.createdAt,
    super.updatedAt,
  });

  /// Create from entity
  factory PomodoroSessionModel.fromEntity(PomodoroSession session) {
    return PomodoroSessionModel(
      id: session.id,
      userId: session.userId,
      projectId: session.projectId,
      title: session.title,
      type: session.type,
      durationSeconds: session.durationSeconds,
      startedAt: session.startedAt,
      endedAt: session.endedAt,
      pausedAt: session.pausedAt,
      elapsedSecondsBeforePause: session.elapsedSecondsBeforePause,
      status: session.status,
      tasksCleared: session.tasksCleared,
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
    );
  }

  /// Convert to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'project_id': projectId,
      'title': title,
      'type': type.name,
      'duration_seconds': durationSeconds,
      'started_at': startedAt.toUtc().toIso8601String(), // Store as UTC
      'ended_at': endedAt?.toUtc().toIso8601String(),
      'paused_at': pausedAt?.toUtc().toIso8601String(),
      'elapsed_seconds_before_pause': elapsedSecondsBeforePause,
      'status': status.name,
      'tasks_cleared': tasksCleared,
    };
  }

  /// Create from JSON (database response)
  factory PomodoroSessionModel.fromJson(Map<String, dynamic> json) {
    final type = PomodoroSessionTypeExtension.fromString(
      json['type'] ?? 'pomodoro',
    );
    return PomodoroSessionModel(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      projectId: json['project_id']?.toString(),
      title: json['title']?.toString(), // Will use default if null
      type: type,
      durationSeconds: json['duration_seconds'] ?? 0,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at']).toLocal()
          : DateTime.now(),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at']).toLocal()
          : null,
      pausedAt: json['paused_at'] != null
          ? DateTime.parse(json['paused_at']).toLocal()
          : null,
      elapsedSecondsBeforePause: json['elapsed_seconds_before_pause'] ?? 0,
      status: PomodoroSessionStatusExtension.fromString(
        json['status'] ?? 'running',
      ),
      tasksCleared:
          (json['tasks_cleared'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to entity
  PomodoroSession toEntity() {
    return PomodoroSession(
      id: id,
      userId: userId,
      projectId: projectId,
      title: title,
      type: type,
      durationSeconds: durationSeconds,
      startedAt: startedAt,
      endedAt: endedAt,
      pausedAt: pausedAt,
      elapsedSecondsBeforePause: elapsedSecondsBeforePause,
      status: status,
      tasksCleared: tasksCleared,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
