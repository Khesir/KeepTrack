import '../models/pomodoro_session_model.dart';

/// Pomodoro Session data source interface - Abstract database operations
abstract class PomodoroSessionDataSource {
  /// Get all sessions for a user
  Future<List<PomodoroSessionModel>> getSessions(String userId);

  /// Get active/running session for a user
  Future<PomodoroSessionModel?> getActiveSession(String userId);

  /// Get session by ID
  Future<PomodoroSessionModel?> getSessionById(String id);

  /// Create a new session
  Future<PomodoroSessionModel> createSession(PomodoroSessionModel session);

  /// Update an existing session
  Future<PomodoroSessionModel> updateSession(PomodoroSessionModel session);

  /// Delete a session
  Future<void> deleteSession(String id);

  /// Get sessions by date range
  Future<List<PomodoroSessionModel>> getSessionsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Get sessions by type
  Future<List<PomodoroSessionModel>> getSessionsByType(
    String userId,
    String type,
  );

  /// Get completed sessions count
  Future<int> getCompletedSessionsCount(String userId);
}
