/// Pomodoro Session entity - Pure domain model
class PomodoroSession {
  final String? id;
  final String userId;
  final PomodoroSessionType type;
  final int durationSeconds;
  final DateTime startedAt;
  final DateTime? endedAt;
  final PomodoroSessionStatus status;
  final List<String> tasksCleared; // Task UUIDs completed during session

  PomodoroSession({
    this.id,
    required this.userId,
    required this.type,
    required this.durationSeconds,
    required this.startedAt,
    this.endedAt,
    required this.status,
    this.tasksCleared = const [],
  });

  /// Copy with method for immutability
  PomodoroSession copyWith({
    String? id,
    String? userId,
    PomodoroSessionType? type,
    int? durationSeconds,
    DateTime? startedAt,
    DateTime? endedAt,
    PomodoroSessionStatus? status,
    List<String>? tasksCleared,
  }) {
    return PomodoroSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
      tasksCleared: tasksCleared ?? this.tasksCleared,
    );
  }

  /// Check if session is currently running
  bool get isRunning => status == PomodoroSessionStatus.running && endedAt == null;

  /// Get elapsed seconds based on current time
  int get elapsedSeconds {
    if (endedAt != null) {
      return endedAt!.difference(startedAt).inSeconds;
    }
    return DateTime.now().difference(startedAt).inSeconds;
  }

  /// Get remaining seconds
  int get remainingSeconds {
    final elapsed = elapsedSeconds;
    return durationSeconds - elapsed > 0 ? durationSeconds - elapsed : 0;
  }

  /// Check if session is completed
  bool get isCompleted => status == PomodoroSessionStatus.completed;

  /// Check if session is canceled
  bool get isCanceled => status == PomodoroSessionStatus.canceled;

  /// Get progress percentage (0.0 to 1.0)
  double get progress {
    if (durationSeconds == 0) return 1.0;
    final elapsed = elapsedSeconds;
    final progress = elapsed / durationSeconds;
    return progress > 1.0 ? 1.0 : progress;
  }
}

/// Pomodoro session type
enum PomodoroSessionType {
  pomodoro,
  shortBreak,
  longBreak,
}

/// Pomodoro session status
enum PomodoroSessionStatus {
  running,
  completed,
  canceled,
}

/// Extension for string conversion
extension PomodoroSessionTypeExtension on PomodoroSessionType {
  String get name {
    switch (this) {
      case PomodoroSessionType.pomodoro:
        return 'pomodoro';
      case PomodoroSessionType.shortBreak:
        return 'short';
      case PomodoroSessionType.longBreak:
        return 'long';
    }
  }

  String get displayName {
    switch (this) {
      case PomodoroSessionType.pomodoro:
        return 'Pomodoro';
      case PomodoroSessionType.shortBreak:
        return 'Short Break';
      case PomodoroSessionType.longBreak:
        return 'Long Break';
    }
  }

  static PomodoroSessionType fromString(String value) {
    switch (value) {
      case 'pomodoro':
        return PomodoroSessionType.pomodoro;
      case 'short':
        return PomodoroSessionType.shortBreak;
      case 'long':
        return PomodoroSessionType.longBreak;
      default:
        return PomodoroSessionType.pomodoro;
    }
  }
}

extension PomodoroSessionStatusExtension on PomodoroSessionStatus {
  String get name {
    switch (this) {
      case PomodoroSessionStatus.running:
        return 'running';
      case PomodoroSessionStatus.completed:
        return 'completed';
      case PomodoroSessionStatus.canceled:
        return 'canceled';
    }
  }

  static PomodoroSessionStatus fromString(String value) {
    switch (value) {
      case 'running':
        return PomodoroSessionStatus.running;
      case 'completed':
        return PomodoroSessionStatus.completed;
      case 'canceled':
        return PomodoroSessionStatus.canceled;
      default:
        return PomodoroSessionStatus.running;
    }
  }
}
