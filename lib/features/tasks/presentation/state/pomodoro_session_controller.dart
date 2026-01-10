import 'dart:async';
import 'package:keep_track/core/error/result.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/features/tasks/modules/pomodoro/domain/entities/pomodoro_settings.dart';
import '../../modules/pomodoro/domain/entities/pomodoro_session.dart';
import '../../modules/pomodoro/domain/entities/pomodoro_settings.dart'
    hide PomodoroSessionType;
import '../../modules/pomodoro/domain/repositories/pomodoro_session_repository.dart';

/// Controller for managing Pomodoro session state
class PomodoroSessionController
    extends StreamState<AsyncState<PomodoroSessionState>> {
  final PomodoroSessionRepository _repository;
  final String userId;

  Timer? _timer;
  PomodoroSettings _settings = const PomodoroSettings();

  PomodoroSessionController(this._repository, this.userId)
    : super(const AsyncLoading()) {
    loadActiveSession();
  }

  PomodoroSettings get settings => _settings;

  /// Update settings
  void updateSettings(PomodoroSettings newSettings) {
    _settings = newSettings;
  }

  /// Load active session (if any exists)
  Future<void> loadActiveSession() async {
    await execute(() async {
      final result = await _repository.getActiveSession(userId);
      final activeSession = result.unwrap();

      if (activeSession != null && activeSession.isRunning) {
        // Resume timer if session is still running
        _startTimer(activeSession);
        return PomodoroSessionState(
          currentSession: activeSession,
          isRunning: true,
        );
      }

      return const PomodoroSessionState();
    });
  }

  /// Start a new session
  Future<void> startSession(PomodoroSessionType type) async {
    await execute(() async {
      // Create new session
      final session = PomodoroSession(
        userId: userId,
        type: type,
        durationSeconds: _settings.getDurationSeconds(type),
        startedAt: DateTime.now(),
        status: PomodoroSessionStatus.running,
      );

      final result = await _repository.createSession(session);
      final createdSession = result.unwrap();

      // Start timer
      _startTimer(createdSession);

      return PomodoroSessionState(
        currentSession: createdSession,
        isRunning: true,
      );
    });
  }

  /// Resume existing session
  Future<void> resumeSession(PomodoroSession session) async {
    await execute(() async {
      _startTimer(session);
      return PomodoroSessionState(currentSession: session, isRunning: true);
    });
  }

  /// Pause the current session
  void pauseSession() {
    _timer?.cancel();
    _timer = null;

    if (data != null && data!.currentSession != null) {
      emit(AsyncData(data!.copyWith(isRunning: false)));
    }
  }

  /// Complete the current session
  Future<void> completeSession({List<String>? tasksCleared}) async {
    if (data?.currentSession == null) return;

    await execute(() async {
      _timer?.cancel();
      _timer = null;

      final session = data!.currentSession!;
      final updatedSession = session.copyWith(
        endedAt: DateTime.now(),
        status: PomodoroSessionStatus.completed,
        tasksCleared: tasksCleared ?? session.tasksCleared,
      );

      await _repository.updateSession(updatedSession);

      return const PomodoroSessionState();
    });
  }

  /// Cancel the current session
  Future<void> cancelSession() async {
    if (data?.currentSession == null) return;

    await execute(() async {
      _timer?.cancel();
      _timer = null;

      final session = data!.currentSession!;
      final updatedSession = session.copyWith(
        endedAt: DateTime.now(),
        status: PomodoroSessionStatus.canceled,
      );

      await _repository.updateSession(updatedSession);

      return const PomodoroSessionState();
    });
  }

  /// Add task to cleared tasks
  Future<void> addClearedTask(String taskId) async {
    if (data?.currentSession == null) return;

    await execute(() async {
      final session = data!.currentSession!;
      final updatedTasks = [...session.tasksCleared, taskId];

      final updatedSession = session.copyWith(tasksCleared: updatedTasks);
      await _repository.updateSession(updatedSession);

      return data!.copyWith(currentSession: updatedSession);
    });
  }

  /// Remove task from cleared tasks
  Future<void> removeClearedTask(String taskId) async {
    if (data?.currentSession == null) return;

    await execute(() async {
      final session = data!.currentSession!;
      final updatedTasks = session.tasksCleared
          .where((id) => id != taskId)
          .toList();

      final updatedSession = session.copyWith(tasksCleared: updatedTasks);
      await _repository.updateSession(updatedSession);

      return data!.copyWith(currentSession: updatedSession);
    });
  }

  /// Get all sessions
  Future<List<PomodoroSession>> getSessions() async {
    final result = await _repository.getSessions(userId);
    return result.unwrap();
  }

  /// Get sessions by date range
  Future<List<PomodoroSession>> getSessionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final result = await _repository.getSessionsByDateRange(
      userId,
      startDate,
      endDate,
    );
    return result.unwrap();
  }

  /// Private: Start timer for session
  void _startTimer(PomodoroSession session) {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (data?.currentSession == null) {
        timer.cancel();
        return;
      }

      final currentSession = data!.currentSession!;

      // Check if timer is complete
      if (currentSession.remainingSeconds <= 0) {
        timer.cancel();
        _onTimerComplete();
        return;
      }

      // Emit updated state with current session
      emit(AsyncData(data!.copyWith(currentSession: currentSession)));
    });
  }

  /// Private: Handle timer completion
  void _onTimerComplete() async {
    if (data?.currentSession == null) return;

    final session = data!.currentSession!;

    // Auto-complete the session
    final updatedSession = session.copyWith(
      endedAt: session.startedAt.add(
        Duration(seconds: session.durationSeconds),
      ),
      status: PomodoroSessionStatus.completed,
    );

    await _repository.updateSession(updatedSession);

    emit(
      AsyncData(
        PomodoroSessionState(
          currentSession: updatedSession,
          isRunning: false,
          isComplete: true,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// State for Pomodoro sessions
class PomodoroSessionState {
  final PomodoroSession? currentSession;
  final bool isRunning;
  final bool isComplete;

  const PomodoroSessionState({
    this.currentSession,
    this.isRunning = false,
    this.isComplete = false,
  });

  PomodoroSessionState copyWith({
    PomodoroSession? currentSession,
    bool? isRunning,
    bool? isComplete,
  }) {
    return PomodoroSessionState(
      currentSession: currentSession ?? this.currentSession,
      isRunning: isRunning ?? this.isRunning,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}
