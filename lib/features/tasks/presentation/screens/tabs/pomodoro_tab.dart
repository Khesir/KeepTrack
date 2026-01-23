import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/app_layout_controller.dart';
import 'package:keep_track/core/ui/responsive/desktop_aware_screen.dart';
import 'package:keep_track/core/ui/ui.dart';
import 'package:keep_track/features/tasks/modules/pomodoro/domain/entities/pomodoro_session.dart';
import 'package:keep_track/features/tasks/modules/pomodoro/domain/entities/pomodoro_settings.dart';
import 'package:keep_track/features/tasks/modules/tasks/domain/entities/task.dart';
import 'package:keep_track/features/tasks/modules/projects/domain/entities/project.dart';
import 'package:keep_track/features/tasks/presentation/state/pomodoro_session_controller.dart';
import 'package:keep_track/features/tasks/presentation/state/task_controller.dart';
import 'package:keep_track/features/tasks/presentation/state/project_controller.dart';

import '../../../../../core/state/stream_state.dart';

/// Pomodoro Session Tab - Focus timer with session tracking
class PomodoroTab extends ScopedScreen {
  const PomodoroTab({super.key});

  @override
  State<PomodoroTab> createState() => _PomodoroTabState();
}

class _PomodoroTabState extends ScopedScreenState<PomodoroTab>
    with AppLayoutControlled, TickerProviderStateMixin {
  late final PomodoroSessionController _controller;
  late final TaskController _taskController;
  late final ProjectController _projectController;

  PomodoroSettings _settings = const PomodoroSettings();
  int _selectedTabIndex = 0; // 0 = Sessions, 1 = Tasks
  Key _sessionsKey = UniqueKey(); // Force rebuild of sessions list

  @override
  void registerServices() {
    _controller = locator.get<PomodoroSessionController>();
    _taskController = locator.get<TaskController>();
    _projectController = locator.get<ProjectController>();
  }

  @override
  void onReady() {
    configureLayout(title: 'Pomodoro', showBottomNav: true);
    _taskController.loadTasks();
    _controller.loadActiveSession();

    // Listen to controller state changes to refresh sessions list
    // Only refresh when session is completed/created, not on timer ticks
    PomodoroSession? lastSession;
    _controller.stream.listen((state) {
      if (state is AsyncData<PomodoroSessionState>) {
        final currentSession = state.data.currentSession;

        // Only refresh if session changed (completed, created, or cancelled)
        // Not on timer ticks (when session is same but time changed)
        if (lastSession?.id != currentSession?.id ||
            lastSession?.status != currentSession?.status) {
          if (mounted) {
            setState(() {
              _sessionsKey = UniqueKey(); // Refresh sessions list
            });
          }
        }
        lastSession = currentSession;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DesktopAwareScreen(
      builder: (context, isDesktop) {
        return Scaffold(
          backgroundColor: isDesktop ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF09090B) : AppColors.backgroundSecondary) : null,
          body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
          floatingActionButton: !isDesktop
              ? FloatingActionButton(
                  onPressed: _showSettingsDialog,
                  child: const Icon(Icons.settings),
                )
              : null,
        );
      },
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Row - Timer (full width, prominent)
              _buildTimerCard(),
              const SizedBox(height: AppSpacing.xl),

              // Middle Row - Cleared Tasks (full width)
              SizedBox(
                height: 350,
                child: _buildClearedTasksCard(),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Bottom Row - Sessions and Available Tasks (equal split)
              SizedBox(
                height: 500,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left side - Sessions History
                    Expanded(child: _buildSessionsCard()),
                    const SizedBox(width: AppSpacing.xl),
                    // Right side - Available Tasks
                    Expanded(child: _buildAvailableTasksCard()),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTimerCard(),
          const SizedBox(height: 16),
          _buildClearedTasksCard(),
          const SizedBox(height: 16),
          _buildTabsSection(),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildAvailableTasksCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.task_alt,
                    size: 24,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Available Tasks',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildTasksTab()),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.history,
                    size: 24,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Session History',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildSessionsTab()),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerCard() {
    return AsyncStreamBuilder<PomodoroSessionState>(
      state: _controller,
      builder: (context, state) {
        final session = state.currentSession;
        final isRunning = state.isRunning;
        final isComplete = state.isComplete;

        Color sessionColor = Colors.blue;
        if (session != null) {
          switch (session.type) {
            case PomodoroSessionType.pomodoro:
              sessionColor = Colors.red;
              break;
            case PomodoroSessionType.shortBreak:
              sessionColor = Colors.green;
              break;
            case PomodoroSessionType.longBreak:
              sessionColor = Colors.blue;
              break;
            case PomodoroSessionType.stopwatch:
              sessionColor = Colors.amber;
              break;
          }
        }

        return Card(
          elevation: 8,
          shadowColor: session != null ? sessionColor.withOpacity(0.3) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: session != null
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        sessionColor.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    )
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  // Header with settings
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Focus Timer',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: _showSettingsDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Session title if exists
                  if (session != null) ...[
                    Text(
                      session.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: sessionColor,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Timer display
                  _buildTimerDisplay(session, isRunning, sessionColor),

                  const SizedBox(height: 32),

                  // Session type selector or display
                  if (session == null || !isRunning)
                    _buildSessionTypeSelector()
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: sessionColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sessionColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        session.type.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: sessionColor,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Control buttons
                  _buildControlButtons(session, isRunning, isComplete),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimerDisplay(
    PomodoroSession? session,
    bool isRunning,
    Color sessionColor,
  ) {
    int displaySeconds = 0;
    double progress = 0.0;
    bool isStopwatch = session?.isStopwatch ?? false;

    if (session != null) {
      if (isStopwatch) {
        // Stopwatch: show elapsed time (counting up)
        displaySeconds = session.elapsedSeconds;
        progress = 1.0; // Full circle for stopwatch
      } else {
        // Regular timer: show remaining time (counting down)
        displaySeconds = session.remainingSeconds;
        progress = session.progress;
      }
    }

    // Handle hour display for long stopwatch sessions
    final hours = displaySeconds ~/ 3600;
    final minutes = (displaySeconds % 3600) ~/ 60;
    final seconds = displaySeconds % 60;

    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress circle
          CustomPaint(
            size: const Size(300, 300),
            painter: TimerPainter(
              progress: progress,
              isRunning: isRunning,
              color: sessionColor,
            ),
          ),
          // Time text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                hours > 0
                    ? '${hours.toString()}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}'
                    : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: hours > 0 ? 56 : 72,
                  color: session != null ? sessionColor : null,
                ),
              ),
              const SizedBox(height: 12),
              if (session != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isRunning
                        ? sessionColor.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isRunning
                          ? sessionColor.withOpacity(0.3)
                          : Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    isRunning
                        ? 'In Progress'
                        : session.status == PomodoroSessionStatus.paused
                        ? 'Paused'
                        : 'Stopped',
                    style: TextStyle(
                      color: isRunning ? sessionColor : Colors.orange,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTypeSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _buildSessionTypeChip(
          'Pomodoro',
          PomodoroSessionType.pomodoro,
          Colors.red,
          '${_settings.pomodoroDuration} min',
        ),
        _buildSessionTypeChip(
          'Short Break',
          PomodoroSessionType.shortBreak,
          Colors.green,
          '${_settings.shortBreakDuration} min',
        ),
        _buildSessionTypeChip(
          'Long Break',
          PomodoroSessionType.longBreak,
          Colors.blue,
          '${_settings.longBreakDuration} min',
        ),
        _buildSessionTypeChip(
          'Stopwatch',
          PomodoroSessionType.stopwatch,
          Colors.amber,
          'No limit',
          icon: Icons.timer_outlined,
        ),
      ],
    );
  }

  Widget _buildSessionTypeChip(
    String label,
    PomodoroSessionType type,
    Color color,
    String duration, {
    IconData icon = Icons.timer,
  }) {
    return ActionChip(
      avatar: CircleAvatar(
        backgroundColor: color,
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          Text(
            duration,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
      onPressed: () {
        if (type == PomodoroSessionType.pomodoro ||
            type == PomodoroSessionType.stopwatch) {
          _showProjectSelectorDialog(type);
        } else {
          _controller.startSession(type);
        }
      },
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }

  Widget _buildControlButtons(
    PomodoroSession? session,
    bool isRunning,
    bool isComplete,
  ) {
    if (isComplete) {
      return ElevatedButton.icon(
        onPressed: () {
          _controller.loadActiveSession();
        },
        icon: const Icon(Icons.refresh),
        label: const Text('Start New Session'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      );
    }

    if (session == null) {
      return const SizedBox();
    }

    // Check if mobile for responsive layout
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      // Mobile: Stack buttons vertically
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: isRunning
                ? ElevatedButton.icon(
                    onPressed: _controller.pauseSession,
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: () => _controller.resumeSession(session),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Resume'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showCompleteDialog(session),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Complete'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    foregroundColor: Colors.green,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _controller.cancelSession,
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Desktop: Horizontal layout
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isRunning)
          ElevatedButton.icon(
            onPressed: _controller.pauseSession,
            icon: const Icon(Icons.pause),
            label: const Text('Pause'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: () => _controller.resumeSession(session),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Resume'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () => _showCompleteDialog(session),
          icon: const Icon(Icons.check_circle),
          label: const Text('Complete'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            foregroundColor: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: _controller.cancelSession,
          icon: const Icon(Icons.cancel),
          label: const Text('Cancel'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            foregroundColor: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildClearedTasksCard() {
    return AsyncStreamBuilder<PomodoroSessionState>(
      state: _controller,
      builder: (context, state) {
        final session = state.currentSession;

        // If there's no session, show a friendly message
        if (session == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 400,
                child: Center(
                  child: Text(
                    'Create a session to start clearing tasks!',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        size: 24,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Tasks Cleared',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${session.tasksCleared.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: AsyncStreamBuilder<List<Task>>(
                    state: _taskController,
                    builder: (context, tasks) {
                      if (tasks.isEmpty) {
                        return Center(
                          child: Text(
                            'No tasks available. Add some to start!',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      final clearedTasks = tasks
                          .where(
                            (t) =>
                                t.id != null &&
                                session.tasksCleared.contains(t.id),
                          )
                          .toList();

                      if (clearedTasks.isEmpty) {
                        return Center(
                          child: Text(
                            'No tasks cleared yet.',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: clearedTasks.length,
                        itemBuilder: (context, index) {
                          final task = clearedTasks[index];
                          return _buildClearedTaskItem(task, session);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClearedTaskItem(Task task, PomodoroSession session) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (task.description != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      task.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => _controller.removeClearedTask(task.id!),
              tooltip: 'Remove from cleared',
              color: Colors.red[400],
              iconSize: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabsSection() {
    return Card(
      child: Column(
        children: [
          // Tab buttons
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTabIndex = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: _selectedTabIndex == 0
                            ? Border(
                                bottom: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              )
                            : null,
                      ),
                      child: Text(
                        'Sessions',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: _selectedTabIndex == 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedTabIndex == 0
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTabIndex = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: _selectedTabIndex == 1
                            ? Border(
                                bottom: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              )
                            : null,
                      ),
                      child: Text(
                        'Tasks',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: _selectedTabIndex == 1
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedTabIndex == 1
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab content
          SizedBox(
            height: 400, // Fixed height for the tab content
            child: _selectedTabIndex == 0
                ? _buildSessionsTab()
                : _buildTasksTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsTab() {
    return FutureBuilder<List<PomodoroSession>>(
      key: _sessionsKey, // Force rebuild when key changes
      future: _controller.getSessions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No sessions yet',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }

        final sessions = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return _buildSessionItem(session);
          },
        );
      },
    );
  }

  Widget _buildSessionItem(PomodoroSession session) {
    Color typeColor;
    switch (session.type) {
      case PomodoroSessionType.pomodoro:
        typeColor = Colors.red;
        break;
      case PomodoroSessionType.shortBreak:
        typeColor = Colors.green;
        break;
      case PomodoroSessionType.longBreak:
        typeColor = Colors.blue;
        break;
      case PomodoroSessionType.stopwatch:
        typeColor = Colors.amber;
        break;
    }

    IconData statusIcon;
    Color statusColor;
    switch (session.status) {
      case PomodoroSessionStatus.completed:
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        break;
      case PomodoroSessionStatus.running:
        statusIcon = Icons.play_circle;
        statusColor = Colors.blue;
        break;
      case PomodoroSessionStatus.paused:
        statusIcon = Icons.pause_circle;
        statusColor = Colors.orange;
        break;
      case PomodoroSessionStatus.canceled:
        statusIcon = Icons.cancel;
        statusColor = Colors.red;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: typeColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.timer, color: typeColor, size: 24),
        ),
        title: Text(
          session.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            session.isStopwatch
                ? '${_formatDateTime(session.startedAt)} • ${_formatElapsedTime(session.elapsedSeconds)}'
                : '${_formatDateTime(session.startedAt)} • ${session.durationSeconds ~/ 60} min',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(statusIcon, color: statusColor, size: 22),
        ),
      ),
    );
  }

  Widget _buildTasksTab() {
    return AsyncStreamBuilder<PomodoroSessionState>(
      state: _controller,
      builder: (context, state) {
        final session = state.currentSession;

        return AsyncStreamBuilder<List<Task>>(
          state: _taskController,
          builder: (context, tasks) {
            final activeTasks = tasks
                .where(
                  (t) =>
                      t.id != null &&
                      !t.isCompleted &&
                      !t.isArchived &&
                      (session == null || !session.tasksCleared.contains(t.id)),
                )
                .toList();

            if (activeTasks.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.task_alt,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No active tasks',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activeTasks.length,
              itemBuilder: (context, index) {
                final task = activeTasks[index];
                return _buildTaskItem(task, session);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTaskItem(Task task, PomodoroSession? session) {
    Color priorityColor;
    switch (task.priority) {
      case TaskPriority.urgent:
        priorityColor = Colors.red[700]!;
        break;
      case TaskPriority.high:
        priorityColor = Colors.orange[700]!;
        break;
      case TaskPriority.medium:
        priorityColor = Colors.blue[700]!;
        break;
      case TaskPriority.low:
        priorityColor = Colors.grey[700]!;
        break;
    }

    final isOverdue =
        task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        !task.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isOverdue
            ? Colors.red.withOpacity(0.05)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: isOverdue
            ? Border.all(color: Colors.red.withOpacity(0.4), width: 2)
            : Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                width: 1.5,
              ),
        boxShadow: [
          BoxShadow(
            color: isOverdue
                ? Colors.red.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Priority indicator
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // Checkbox
            Checkbox(
              value: task.isCompleted,
              onChanged: (value) async {
                if (value != null) {
                  final updatedTask = task.copyWith(
                    status: value ? TaskStatus.completed : TaskStatus.todo,
                    completedAt: value ? DateTime.now() : null,
                  );
                  await _taskController.updateTask(updatedTask);

                  // If marking as completed and there's an active session, add to cleared tasks
                  if (value && session != null && task.id != null) {
                    await _controller.addClearedTask(task.id!);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${task.title} completed and cleared!'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                }
              },
            ),
            const SizedBox(width: 8),

            // Task info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (task.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (isOverdue)
                        _buildTaskBadge(
                          'OVERDUE',
                          Colors.red,
                          Icons.warning_amber_rounded,
                        ),
                      _buildTaskBadge(
                        task.priority.displayName,
                        priorityColor,
                        Icons.flag,
                      ),
                      if (task.dueDate != null)
                        _buildTaskBadge(
                          DateFormat('MMM d, h:mm a').format(task.dueDate!),
                          isOverdue ? Colors.red : Colors.grey[700]!,
                          Icons.calendar_today,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Action button
            if (session != null)
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add_task),
                  onPressed: () {
                    _controller.addClearedTask(task.id!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${task.title} cleared!'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  tooltip: 'Mark as cleared',
                  color: Theme.of(context).colorScheme.primary,
                  iconSize: 28,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => _SettingsDialog(
        settings: _settings,
        onSave: (newSettings) {
          setState(() {
            _settings = newSettings;
            _controller.updateSettings(newSettings);
          });
        },
      ),
    );
  }

  void _showCompleteDialog(PomodoroSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Session'),
        content: Text(
          'Complete this ${session.type.displayName.toLowerCase()} session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _controller.completeSession(tasksCleared: session.tasksCleared);
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _showProjectSelectorDialog(PomodoroSessionType type) {
    final titleController = TextEditingController();
    final isMobile = MediaQuery.of(context).size.width < 600;

    // For mobile, show full screen bottom sheet
    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return _SessionStartSheet(
              type: type,
              controller: _controller,
              projectController: _projectController,
              scrollController: scrollController,
            );
          },
        ),
      );
      return;
    }

    // For desktop, show dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start ${type.displayName}'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Session Title (Optional)',
                  hintText: 'Leave empty for default title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.edit),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Project (Optional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: AsyncStreamBuilder<List<Project>>(
                  state: _projectController,
                  builder: (context, projects) {
                    final activeProjects = projects
                        .where(
                          (p) =>
                              p.status == ProjectStatus.active && !p.isArchived,
                        )
                        .toList();

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.timer),
                          title: const Text('No Project'),
                          subtitle: const Text(
                            'Start without project tracking',
                          ),
                          onTap: () {
                            final title = titleController.text.trim();
                            Navigator.pop(context);
                            _controller.startSession(
                              type,
                              title: title.isEmpty ? null : title,
                            );
                          },
                        ),
                        const Divider(),
                        if (activeProjects.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No active projects'),
                          )
                        else
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: activeProjects.length,
                              itemBuilder: (context, index) {
                                final project = activeProjects[index];
                                Color projectColor = Colors.blue;
                                if (project.color != null) {
                                  try {
                                    final colorStr = project.color!.replaceAll(
                                      '#',
                                      '',
                                    );
                                    projectColor = Color(
                                      int.parse('0xFF$colorStr'),
                                    );
                                  } catch (e) {
                                    projectColor = Colors.blue;
                                  }
                                }

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: projectColor,
                                    child: Text(
                                      project.name[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  title: Text(project.name),
                                  subtitle: project.description != null
                                      ? Text(project.description!)
                                      : null,
                                  onTap: () {
                                    final title = titleController.text.trim();
                                    Navigator.pop(context);
                                    _controller.startSession(
                                      type,
                                      projectId: project.id,
                                      title: title.isEmpty ? null : title,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                  loadingBuilder: (_) => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorBuilder: (context, message) =>
                      Center(child: Text('Error loading projects: $message')),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final difference = taskDate.difference(today).inDays;

    final timeStr =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    if (difference == 0) {
      return 'Today at $timeStr';
    } else if (difference == -1) {
      return 'Yesterday at $timeStr';
    } else {
      return '${dateTime.month}/${dateTime.day} at $timeStr';
    }
  }

  String _formatElapsedTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}

/// Mobile bottom sheet for session start
class _SessionStartSheet extends StatefulWidget {
  final PomodoroSessionType type;
  final PomodoroSessionController controller;
  final ProjectController projectController;
  final ScrollController scrollController;

  const _SessionStartSheet({
    required this.type,
    required this.controller,
    required this.projectController,
    required this.scrollController,
  });

  @override
  State<_SessionStartSheet> createState() => _SessionStartSheetState();
}

class _SessionStartSheetState extends State<_SessionStartSheet> {
  final _titleController = TextEditingController();
  String? _selectedProjectId;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Start ${widget.type.displayName}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final title = _titleController.text.trim();
                    Navigator.pop(context);
                    widget.controller.startSession(
                      widget.type,
                      projectId: _selectedProjectId,
                      title: title.isEmpty ? null : title,
                    );
                  },
                  child: const Text(
                    'START',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // Content
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Session Title (Optional)',
                    hintText: 'Leave empty for default title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.edit),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Project (Optional)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                // No project option
                ListTile(
                  leading: const Icon(Icons.timer),
                  title: const Text('No Project'),
                  subtitle: const Text('Start without project tracking'),
                  trailing: _selectedProjectId == null
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedProjectId = null;
                    });
                  },
                ),
                const Divider(),

                // Projects
                AsyncStreamBuilder<List<Project>>(
                  state: widget.projectController,
                  builder: (context, projects) {
                    final activeProjects = projects
                        .where(
                          (p) =>
                              p.status == ProjectStatus.active && !p.isArchived,
                        )
                        .toList();

                    if (activeProjects.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: Text('No active projects')),
                      );
                    }

                    return Column(
                      children: activeProjects.map((project) {
                        Color projectColor = Colors.blue;
                        if (project.color != null) {
                          try {
                            final colorStr = project.color!.replaceAll('#', '');
                            projectColor = Color(int.parse('0xFF$colorStr'));
                          } catch (e) {
                            projectColor = Colors.blue;
                          }
                        }

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: projectColor,
                            child: Text(
                              project.name[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(project.name),
                          subtitle: project.description != null
                              ? Text(project.description!)
                              : null,
                          trailing: _selectedProjectId == project.id
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedProjectId = project.id;
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                  loadingBuilder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                  errorBuilder: (context, message) =>
                      Center(child: Text('Error loading projects: $message')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for timer circle
class TimerPainter extends CustomPainter {
  final double progress;
  final bool isRunning;
  final Color color;

  TimerPainter({
    required this.progress,
    required this.isRunning,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;

    canvas.drawCircle(center, radius - 8, bgPaint);

    // Progress arc with gradient effect
    final progressPaint = Paint()
      ..color = isRunning ? color : Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    // Draw shadow/glow effect
    final shadowPaint = Paint()
      ..color = (isRunning ? color : Colors.orange).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 8),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      shadowPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 8),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(TimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isRunning != isRunning ||
        oldDelegate.color != color;
  }
}

/// Settings dialog
class _SettingsDialog extends StatefulWidget {
  final PomodoroSettings settings;
  final Function(PomodoroSettings) onSave;

  const _SettingsDialog({required this.settings, required this.onSave});

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late int _pomodoroDuration;
  late int _shortBreakDuration;
  late int _longBreakDuration;

  @override
  void initState() {
    super.initState();
    _pomodoroDuration = widget.settings.pomodoroDuration;
    _shortBreakDuration = widget.settings.shortBreakDuration;
    _longBreakDuration = widget.settings.longBreakDuration;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pomodoro Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDurationSlider(
            'Pomodoro Duration',
            _pomodoroDuration,
            (value) => setState(() => _pomodoroDuration = value.round()),
          ),
          const SizedBox(height: 16),
          _buildDurationSlider(
            'Short Break Duration',
            _shortBreakDuration,
            (value) => setState(() => _shortBreakDuration = value.round()),
          ),
          const SizedBox(height: 16),
          _buildDurationSlider(
            'Long Break Duration',
            _longBreakDuration,
            (value) => setState(() => _longBreakDuration = value.round()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final newSettings = PomodoroSettings(
              pomodoroDuration: _pomodoroDuration,
              shortBreakDuration: _shortBreakDuration,
              longBreakDuration: _longBreakDuration,
            );
            widget.onSave(newSettings);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildDurationSlider(
    String label,
    int value,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $value minutes'),
        Slider(
          value: value.toDouble(),
          min: 1,
          max: 60,
          divisions: 59,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
