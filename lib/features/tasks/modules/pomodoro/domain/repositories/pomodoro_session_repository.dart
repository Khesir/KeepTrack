import 'package:keep_track/core/error/result.dart';

import '../entities/pomodoro_session.dart';

/// Pomodoro Session repository interface - Defines data access contract
abstract class PomodoroSessionRepository {
  /// Get all sessions for a user
  Future<Result<List<PomodoroSession>>> getSessions(String userId);

  /// Get active/running session for a user
  Future<Result<PomodoroSession?>> getActiveSession(String userId);

  /// Get session by ID
  Future<Result<PomodoroSession>> getSessionById(String id);

  /// Create a new session
  Future<Result<PomodoroSession>> createSession(PomodoroSession session);

  /// Update an existing session
  Future<Result<PomodoroSession>> updateSession(PomodoroSession session);

  /// Delete a session
  Future<Result<void>> deleteSession(String id);

  /// Get sessions by date range
  Future<Result<List<PomodoroSession>>> getSessionsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Get sessions by type
  Future<Result<List<PomodoroSession>>> getSessionsByType(
    String userId,
    PomodoroSessionType type,
  );

  /// Get completed sessions count
  Future<Result<int>> getCompletedSessionsCount(String userId);
}
