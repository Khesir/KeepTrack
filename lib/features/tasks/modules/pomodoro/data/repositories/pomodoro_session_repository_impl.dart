import 'package:keep_track/core/error/failure.dart';
import 'package:keep_track/core/error/result.dart';

import '../../domain/entities/pomodoro_session.dart';
import '../../domain/repositories/pomodoro_session_repository.dart';
import '../datasources/pomodoro_session_datasource.dart';
import '../models/pomodoro_session_model.dart';

/// Pomodoro Session repository implementation
class PomodoroSessionRepositoryImpl implements PomodoroSessionRepository {
  final PomodoroSessionDataSource dataSource;

  PomodoroSessionRepositoryImpl(this.dataSource);

  @override
  Future<Result<List<PomodoroSession>>> getSessions(String userId) async {
    final sessionModels = await dataSource.getSessions(userId);
    final sessions = sessionModels.cast<PomodoroSession>();
    return Result.success(sessions);
  }

  @override
  Future<Result<PomodoroSession?>> getActiveSession(String userId) async {
    final session = await dataSource.getActiveSession(userId);
    return Result.success(session);
  }

  @override
  Future<Result<PomodoroSession>> getSessionById(String id) async {
    final session = await dataSource.getSessionById(id);
    if (session == null) {
      return Result.error(NotFoundFailure(message: 'Session not found: $id'));
    }
    return Result.success(session);
  }

  @override
  Future<Result<PomodoroSession>> createSession(PomodoroSession session) async {
    final model = PomodoroSessionModel.fromEntity(session);
    final created = await dataSource.createSession(model);
    return Result.success(created);
  }

  @override
  Future<Result<PomodoroSession>> updateSession(PomodoroSession session) async {
    final model = PomodoroSessionModel.fromEntity(session);
    final updated = await dataSource.updateSession(model);
    return Result.success(updated);
  }

  @override
  Future<Result<void>> deleteSession(String id) async {
    await dataSource.deleteSession(id);
    return Result.success(null);
  }

  @override
  Future<Result<List<PomodoroSession>>> getSessionsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final sessionModels = await dataSource.getSessionsByDateRange(
      userId,
      startDate,
      endDate,
    );
    final sessions = sessionModels.cast<PomodoroSession>();
    return Result.success(sessions);
  }

  @override
  Future<Result<List<PomodoroSession>>> getSessionsByType(
    String userId,
    PomodoroSessionType type,
  ) async {
    final sessionModels = await dataSource.getSessionsByType(
      userId,
      type.name,
    );
    final sessions = sessionModels.cast<PomodoroSession>();
    return Result.success(sessions);
  }

  @override
  Future<Result<int>> getCompletedSessionsCount(String userId) async {
    final count = await dataSource.getCompletedSessionsCount(userId);
    return Result.success(count);
  }
}
