import 'dart:async';
import 'package:keep_track/core/error/result.dart';
import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/features/tasks/modules/pomodoro/domain/entities/pomodoro_settings.dart';
import '../../modules/pomodoro/domain/entities/pomodoro_session.dart';
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
    // Cancel any existing timer first to prevent duplicates
    _timer?.cancel();
    _timer = null;

    try {
      final result = await _repository.getActiveSession(userId);
      final activeSession = result.unwrap();

      if (activeSession != null) {
        // Check if session time has expired
        if (activeSession.remainingSeconds <= 0 &&
            (activeSession.isRunning ||
                activeSession.status == PomodoroSessionStatus.paused)) {
          // Session expired while user was away - auto-complete it
          final completedSession = activeSession.copyWith(
            endedAt: DateTime.now(),
            status: PomodoroSessionStatus.completed,
          );
          await _repository
              .updateSession(completedSession)
              .then((r) => r.unwrap());

          emit(
            AsyncData(
              PomodoroSessionState(
                currentSession: completedSession,
                isRunning: false,
                isComplete: true,
              ),
            ),
          );
          return;
        }

        // If session is running, start the timer
        if (activeSession.isRunning) {
          _startTimer(activeSession);
          return;
        }

        // If session is paused, show it but don't start timer
        if (activeSession.status == PomodoroSessionStatus.paused) {
          emit(
            AsyncData(
              PomodoroSessionState(
                currentSession: activeSession,
                isRunning: false,
              ),
            ),
          );
          return;
        }
      }

      emit(const AsyncData(PomodoroSessionState()));
    } catch (e) {
      emit(AsyncError('Failed to load session: $e'));
    }
  }

  /// Start a new session
  Future<void> startSession(
    PomodoroSessionType type, {
    String? projectId,
    String? title,
  }) async {
    try {
      // Create new session
      final session = PomodoroSession(
        userId: userId,
        projectId: projectId, // Only set for pomodoro type
        title: title, // Custom title, uses default if null
        type: type,
        durationSeconds: _settings.getDurationSeconds(type),
        startedAt: DateTime.now(),
        status: PomodoroSessionStatus.running,
      );

      final result = await _repository.createSession(session);
      final createdSession = result.unwrap();

      // Start timer (this will emit state)
      _startTimer(createdSession);
    } catch (e) {
      emit(AsyncError('Failed to start session: $e'));
    }
  }

  /// Resume existing session
  Future<void> resumeSession(PomodoroSession session) async {
    try {
      final now = DateTime.now();

      // When resuming from pause, we need to adjust startedAt so that
      // the elapsed time calculation continues from where it was paused
      //
      // Formula: new_startedAt = now - elapsedSecondsBeforePause
      // This way, when we calculate now.difference(startedAt), we get the elapsed time
      final newStartedAt = now.subtract(
        Duration(seconds: session.elapsedSecondsBeforePause),
      );

      final resumedSession = session.copyWith(
        startedAt: newStartedAt,
        status: PomodoroSessionStatus.running,
        pausedAt: null,
        elapsedSecondsBeforePause: 0, // Reset since startedAt is now adjusted
      );

      // Update in database
      await _repository.updateSession(resumedSession).then((r) => r.unwrap());

      // Start timer with resumed session - this will emit state, no need to emit again
      _startTimer(resumedSession);
    } catch (e) {
      emit(AsyncError('Failed to resume session: $e'));
    }
  }

  /// Pause the current session
  Future<void> pauseSession() async {
    if (data?.currentSession == null) return;

    final session = data!.currentSession!;

    _timer?.cancel();
    _timer = null;

    try {
      // Calculate elapsed time and update session
      final elapsedNow = session.elapsedSeconds;
      final pausedSession = session.copyWith(
        status: PomodoroSessionStatus.paused,
        pausedAt: DateTime.now(),
        elapsedSecondsBeforePause: elapsedNow,
      );

      // Update in database (don't use execute to avoid loading state)
      await _repository.updateSession(pausedSession).then((r) => r.unwrap());

      // Update state directly
      emit(
        AsyncData(
          data!.copyWith(currentSession: pausedSession, isRunning: false),
        ),
      );
    } catch (e) {
      emit(AsyncError('Failed to pause session: $e'));
    }
  }

  /// Complete the current session
  Future<void> completeSession({List<String>? tasksCleared}) async {
    if (data?.currentSession == null) return;

    final session = data!.currentSession!;

    _timer?.cancel();
    _timer = null;

    try {
      final updatedSession = session.copyWith(
        endedAt: DateTime.now(),
        status: PomodoroSessionStatus.completed,
        tasksCleared: tasksCleared ?? session.tasksCleared,
      );

      // Update in database (don't use execute to avoid loading state)
      await _repository.updateSession(updatedSession).then((r) => r.unwrap());

      // Clear session
      emit(const AsyncData(PomodoroSessionState()));
    } catch (e) {
      emit(AsyncError('Failed to complete session: $e'));
    }
  }

  /// Cancel the current session
  Future<void> cancelSession() async {
    if (data?.currentSession == null) return;

    final session = data!.currentSession!;

    _timer?.cancel();
    _timer = null;

    try {
      final updatedSession = session.copyWith(
        endedAt: DateTime.now(),
        status: PomodoroSessionStatus.canceled,
      );

      // Update in database (don't use execute to avoid loading state)
      await _repository.updateSession(updatedSession).then((r) => r.unwrap());

      // Clear session
      emit(const AsyncData(PomodoroSessionState()));
    } catch (e) {
      emit(AsyncError('Failed to cancel session: $e'));
    }
  }

  /// Add task to cleared tasks
  Future<void> addClearedTask(String taskId) async {
    if (data?.currentSession == null) return;

    final currentState = data!;
    final session = currentState.currentSession!;

    try {
      final updatedTasks = [...session.tasksCleared, taskId];
      final updatedSession = session.copyWith(tasksCleared: updatedTasks);

      // Update in database (don't use execute to avoid loading state)
      await _repository.updateSession(updatedSession).then((r) => r.unwrap());

      // Update state directly
      emit(AsyncData(currentState.copyWith(currentSession: updatedSession)));
    } catch (e) {
      emit(AsyncError('Failed to add task: $e'));
    }
  }

  /// Remove task from cleared tasks
  Future<void> removeClearedTask(String taskId) async {
    if (data?.currentSession == null) return;

    final currentState = data!;
    final session = currentState.currentSession!;

    try {
      final updatedTasks = session.tasksCleared
          .where((id) => id != taskId)
          .toList();
      final updatedSession = session.copyWith(tasksCleared: updatedTasks);

      // Update in database (don't use execute to avoid loading state)
      await _repository.updateSession(updatedSession).then((r) => r.unwrap());

      // Update state directly
      emit(AsyncData(currentState.copyWith(currentSession: updatedSession)));
    } catch (e) {
      emit(AsyncError('Failed to remove task: $e'));
    }
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
  /// This just triggers UI updates every second - time calculation is in the entity
  void _startTimer(PomodoroSession session) {
    _timer?.cancel();
    _timer = null;

    // Immediately emit state with the session
    emit(
      AsyncData(
        PomodoroSessionState(
          currentSession: session,
          isRunning: true,
          isComplete: false,
        ),
      ),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Get the latest session from state
      final currentSession = data?.currentSession;
      if (currentSession == null) {
        timer.cancel();
        return;
      }

      // Check if session is no longer running (completed or cancelled)
      if (currentSession.status != PomodoroSessionStatus.running) {
        timer.cancel();
        return;
      }

      // The session entity calculates elapsed/remaining from database startedAt
      final remaining = currentSession.remainingSeconds;

      // Check if timer is complete
      if (remaining <= 0) {
        timer.cancel();
        _autoCompleteSession(currentSession);
        return;
      }

      // Force rebuild by creating a new state object
      // The session entity recalculates time from startedAt, so we just need to trigger rebuild
      emit(
        AsyncData(
          PomodoroSessionState(
            currentSession: currentSession,
            isRunning: true,
            isComplete: false,
          ),
        ),
      );
    });
  }

  /// Private: Auto-complete session when timer reaches 0
  void _autoCompleteSession(PomodoroSession session) async {
    // Auto-complete the session
    final updatedSession = session.copyWith(
      endedAt: DateTime.now(),
      status: PomodoroSessionStatus.completed,
    );

    try {
      // Update in database
      await _repository.updateSession(updatedSession).then((r) => r.unwrap());

      // Show completed state
      emit(
        AsyncData(
          PomodoroSessionState(
            currentSession: updatedSession,
            isRunning: false,
            isComplete: true,
          ),
        ),
      );
    } catch (e) {
      // If update fails, still show completed state locally
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
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
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
