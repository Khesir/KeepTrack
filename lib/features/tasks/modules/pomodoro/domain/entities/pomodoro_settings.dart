import 'pomodoro_session.dart';

/// Pomodoro Settings entity - Timer configuration
class PomodoroSettings {
  final int pomodoroDuration; // in minutes
  final int shortBreakDuration; // in minutes
  final int longBreakDuration; // in minutes
  final int sessionsUntilLongBreak; // number of pomodoro sessions before long break

  const PomodoroSettings({
    this.pomodoroDuration = 25,
    this.shortBreakDuration = 5,
    this.longBreakDuration = 25,
    this.sessionsUntilLongBreak = 4,
  });

  /// Copy with method for immutability
  PomodoroSettings copyWith({
    int? pomodoroDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    int? sessionsUntilLongBreak,
  }) {
    return PomodoroSettings(
      pomodoroDuration: pomodoroDuration ?? this.pomodoroDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      sessionsUntilLongBreak: sessionsUntilLongBreak ?? this.sessionsUntilLongBreak,
    );
  }

  /// Get duration in seconds for a specific session type
  int getDurationSeconds(PomodoroSessionType type) {
    switch (type) {
      case PomodoroSessionType.pomodoro:
        return pomodoroDuration * 60;
      case PomodoroSessionType.shortBreak:
        return shortBreakDuration * 60;
      case PomodoroSessionType.longBreak:
        return longBreakDuration * 60;
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'pomodoroDuration': pomodoroDuration,
      'shortBreakDuration': shortBreakDuration,
      'longBreakDuration': longBreakDuration,
      'sessionsUntilLongBreak': sessionsUntilLongBreak,
    };
  }

  /// Create from JSON
  factory PomodoroSettings.fromJson(Map<String, dynamic> json) {
    return PomodoroSettings(
      pomodoroDuration: json['pomodoroDuration'] ?? 25,
      shortBreakDuration: json['shortBreakDuration'] ?? 5,
      longBreakDuration: json['longBreakDuration'] ?? 25,
      sessionsUntilLongBreak: json['sessionsUntilLongBreak'] ?? 4,
    );
  }
}
