// Pomodoro Session entity - Pure domain model
class PomodoroSession {
  final String? id;
  final String userId;
  final String? projectId;
  final String title;
  final PomodoroSessionType type;
  final int durationSeconds;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime? pausedAt;
  final int elapsedSecondsBeforePause;
  final PomodoroSessionStatus status;
  final List<String> tasksCleared;

  final DateTime? createdAt; // Optional - Supabase auto-generates
  final DateTime? updatedAt; // Optional - Supabase auto-generates
  PomodoroSession({
    this.id,
    required this.userId,
    this.projectId,
    String? title,
    required this.type,
    required this.durationSeconds,
    required this.startedAt,
    this.endedAt,
    this.pausedAt,
    this.elapsedSecondsBeforePause = 0,
    required this.status,
    this.tasksCleared = const [],

    this.createdAt,
    this.updatedAt,
  }) : title = title ?? _getDefaultTitle(type);

  static String _getDefaultTitle(PomodoroSessionType type) {
    switch (type) {
      case PomodoroSessionType.pomodoro:
        return 'Pomodoro Session';
      case PomodoroSessionType.shortBreak:
        return 'Short Break';
      case PomodoroSessionType.longBreak:
        return 'Long Break';
      case PomodoroSessionType.stopwatch:
        return 'Stopwatch Session';
    }
  }

  PomodoroSession copyWith({
    String? id,
    String? userId,
    String? projectId,
    String? title,
    PomodoroSessionType? type,
    int? durationSeconds,
    DateTime? startedAt,
    DateTime? endedAt,
    DateTime? pausedAt,
    int? elapsedSecondsBeforePause,
    PomodoroSessionStatus? status,
    List<String>? tasksCleared,

    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PomodoroSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      type: type ?? this.type,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      pausedAt: pausedAt ?? this.pausedAt,
      elapsedSecondsBeforePause:
          elapsedSecondsBeforePause ?? this.elapsedSecondsBeforePause,
      status: status ?? this.status,
      tasksCleared: tasksCleared ?? this.tasksCleared,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isRunning =>
      status == PomodoroSessionStatus.running && endedAt == null;

  /// Get elapsed seconds based on current time
  /// FIXED: Proper time calculation for running, paused, and completed states
  int get elapsedSeconds {
    // If session has ended, calculate total elapsed time
    if (endedAt != null) {
      return endedAt!.difference(startedAt).inSeconds;
    }

    // If paused, return the elapsed time at pause
    if (status == PomodoroSessionStatus.paused) {
      return elapsedSecondsBeforePause;
    }

    // If running, calculate current elapsed time from startedAt
    // When we resume from pause, startedAt is already adjusted to account for
    // the previous elapsed time, so we just calculate from startedAt
    final now = DateTime.now();
    final currentElapsed = now.difference(startedAt).inSeconds;

    // Ensure non-negative (handles clock skew/timezone issues)
    return currentElapsed > 0 ? currentElapsed : 0;
  }

  int get remainingSeconds {
    final elapsed = elapsedSeconds;
    final remaining = durationSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  bool get isCompleted => status == PomodoroSessionStatus.completed;

  bool get isCanceled => status == PomodoroSessionStatus.canceled;

  bool get isStopwatch => type == PomodoroSessionType.stopwatch;

  double get progress {
    if (durationSeconds == 0) return 1.0;
    final elapsed = elapsedSeconds;
    final progress = elapsed / durationSeconds;
    return progress > 1.0 ? 1.0 : progress;
  }
}

enum PomodoroSessionType { pomodoro, shortBreak, longBreak, stopwatch }

enum PomodoroSessionStatus { running, paused, completed, canceled }

extension PomodoroSessionTypeExtension on PomodoroSessionType {
  String get name {
    switch (this) {
      case PomodoroSessionType.pomodoro:
        return 'pomodoro';
      case PomodoroSessionType.shortBreak:
        return 'short';
      case PomodoroSessionType.longBreak:
        return 'long';
      case PomodoroSessionType.stopwatch:
        return 'stopwatch';
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
      case PomodoroSessionType.stopwatch:
        return 'Stopwatch';
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
      case 'stopwatch':
        return PomodoroSessionType.stopwatch;
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
      case PomodoroSessionStatus.paused:
        return 'paused';
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
      case 'paused':
        return PomodoroSessionStatus.paused;
      case 'completed':
        return PomodoroSessionStatus.completed;
      case 'canceled':
        return PomodoroSessionStatus.canceled;
      default:
        return PomodoroSessionStatus.running;
    }
  }
}
