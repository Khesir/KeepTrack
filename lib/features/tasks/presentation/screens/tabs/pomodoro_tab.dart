import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/app_layout_controller.dart';
import 'package:keep_track/core/ui/ui.dart';
import 'package:keep_track/features/tasks/modules/pomodoro/domain/entities/pomodoro_session.dart';
import 'package:keep_track/features/tasks/modules/pomodoro/domain/entities/pomodoro_settings.dart'
    hide PomodoroSessionType;
import 'package:keep_track/features/tasks/modules/tasks/domain/entities/task.dart';
import 'package:keep_track/features/tasks/modules/projects/domain/entities/project.dart';
import 'package:keep_track/features/tasks/presentation/state/pomodoro_session_controller.dart';
import 'package:keep_track/features/tasks/presentation/state/task_controller.dart';
import 'package:keep_track/features/tasks/presentation/state/project_controller.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';

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
  late final SupabaseService _supabaseService;

  PomodoroSettings _settings = const PomodoroSettings();
  int _selectedTabIndex = 0; // 0 = Sessions, 1 = Tasks

  @override
  void registerServices() {
    _supabaseService = locator.get<SupabaseService>();
    _controller = locator.get<PomodoroSessionController>();
    _taskController = locator.get<TaskController>();
    _projectController = locator.get<ProjectController>();
  }

  @override
  void onReady() {
    configureLayout(title: 'Pomodoro', showBottomNav: true);
    _taskController.loadTasks();
    _controller
        .loadActiveSession(); // Load active/paused session when page loads
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: isDesktop ? AppColors.backgroundSecondary : null,
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      floatingActionButton: !isDesktop
          ? FloatingActionButton(
              onPressed: _showSettingsDialog,
              child: const Icon(Icons.settings),
            )
          : null,
    );
  }

  Widget _buildDesktopLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side - Timer (1/2)
              Expanded(
                child: Column(
                  children: [
                    _buildTimerCard(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildClearedTasksCard(),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              // Right side - Sessions/Tasks tabs (1/2)
              Expanded(child: _buildTabsSection()),
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

  Widget _buildTimerCard() {
    return AsyncStreamBuilder<PomodoroSessionState>(
      state: _controller,
      builder: (context, state) {
        final session = state.currentSession;
        final isRunning = state.isRunning;
        final isComplete = state.isComplete;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
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
                const SizedBox(height: 32),

                // Timer display
                _buildTimerDisplay(session, isRunning),

                const SizedBox(height: 32),

                // Session type selector
                if (session == null || !isRunning)
                  _buildSessionTypeSelector()
                else
                  Text(
                    session.type.displayName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                const SizedBox(height: 24),

                // Control buttons
                _buildControlButtons(session, isRunning, isComplete),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimerDisplay(PomodoroSession? session, bool isRunning) {
    int remainingSeconds = 0;
    double progress = 0.0;

    if (session != null) {
      remainingSeconds = session.remainingSeconds;
      progress = session.progress;
    }

    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;

    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress circle
          CustomPaint(
            size: const Size(280, 280),
            painter: TimerPainter(progress: progress, isRunning: isRunning),
          ),
          // Time text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 64,
                ),
              ),
              const SizedBox(height: 8),
              if (session != null)
                Text(
                  isRunning
                      ? 'In Progress'
                      : session.status == PomodoroSessionStatus.paused
                      ? 'Paused'
                      : 'Stopped',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 16,
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
      ],
    );
  }

  Widget _buildSessionTypeChip(
    String label,
    PomodoroSessionType type,
    Color color,
    String duration,
  ) {
    return ActionChip(
      avatar: CircleAvatar(
        backgroundColor: color,
        child: const Icon(Icons.timer, color: Colors.white, size: 18),
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
        // Show project selector for pomodoro type, otherwise start directly
        if (type == PomodoroSessionType.pomodoro) {
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
        if (session == null) {
          return const SizedBox();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Tasks Cleared',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${session.tasksCleared.length}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (session.tasksCleared.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  AsyncStreamBuilder<List<Task>>(
                    state: _taskController,
                    builder: (context, tasks) {
                      final clearedTasks = tasks
                          .where(
                            (t) =>
                                t.id != null &&
                                session.tasksCleared.contains(t.id),
                          )
                          .toList();

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: clearedTasks.length,
                        itemBuilder: (context, index) {
                          final task = clearedTasks[index];
                          return _buildClearedTaskItem(task);
                        },
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
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
          Expanded(
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
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: typeColor.withOpacity(0.2),
          child: Icon(Icons.timer, color: typeColor, size: 20),
        ),
        title: Text(session.title),
        subtitle: Text(
          '${_formatDateTime(session.startedAt)} • ${session.durationSeconds ~/ 60} min',
        ),
        trailing: Icon(statusIcon, color: statusColor, size: 20),
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
    final isOverdue =
        task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        !task.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isOverdue
            ? Colors.red.withOpacity(0.05)
            : Theme.of(context).colorScheme.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: isOverdue
            ? Border.all(color: Colors.red.withOpacity(0.5), width: 1.5)
            : null,
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
                color: _getPriorityColor(task.priority),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // Checkbox
            Checkbox(
              value: task.isCompleted,
              onChanged: session != null
                  ? (value) async {
                      if (value != null) {
                        final updated = task.copyWith(
                          status: value
                              ? TaskStatus.completed
                              : TaskStatus.todo,
                          completedAt: value ? DateTime.now() : null,
                        );
                        await _taskController.updateTask(updated);
                      }
                    }
                  : null,
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
                    spacing: 8,
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
                        _getPriorityColor(task.priority),
                        Icons.flag,
                      ),
                      _buildTaskBadge(
                        task.status.displayName,
                        _getStatusColor(task.status),
                        Icons.circle,
                      ),
                      if (task.dueDate != null)
                        _buildTaskBadge(
                          _formatDateTime(task.dueDate!),
                          isOverdue ? Colors.red : Colors.grey[700]!,
                          Icons.calendar_today,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Add to cleared button (only if session is active)
            if (session != null)
              IconButton(
                icon: const Icon(Icons.add_task),
                onPressed: () => _controller.addClearedTask(task.id!),
                tooltip: 'Mark as cleared',
                color: Theme.of(context).colorScheme.primary,
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
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return Colors.red[700]!;
      case TaskPriority.high:
        return Colors.orange[700]!;
      case TaskPriority.medium:
        return Colors.blue[700]!;
      case TaskPriority.low:
        return Colors.grey[700]!;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Colors.grey[600]!;
      case TaskStatus.inProgress:
        return Colors.blue[600]!;
      case TaskStatus.completed:
        return Colors.green[600]!;
      case TaskStatus.cancelled:
        return Colors.orange[600]!;
    }
  }

  Widget _buildClearedTaskItem(Task task) {
    final isOverdue =
        task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        !task.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3), width: 1.5),
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
                color: _getPriorityColor(task.priority),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // Check icon (instead of checkbox)
            const Icon(Icons.check_circle, color: Colors.green, size: 24),
            const SizedBox(width: 8),

            // Task info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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
                    spacing: 8,
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
                        _getPriorityColor(task.priority),
                        Icons.flag,
                      ),
                      _buildTaskBadge(
                        task.status.displayName,
                        _getStatusColor(task.status),
                        Icons.circle,
                      ),
                      if (task.dueDate != null)
                        _buildTaskBadge(
                          _formatDateTime(task.dueDate!),
                          isOverdue ? Colors.red : Colors.grey[700]!,
                          Icons.calendar_today,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Remove button
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => _controller.removeClearedTask(task.id!),
              tooltip: 'Remove from cleared',
              color: Colors.red[400],
            ),
          ],
        ),
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

    // For mobile, show full screen route
    if (isMobile) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => _SessionStartScreen(
            type: type,
            controller: _controller,
            projectController: _projectController,
          ),
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
              // Title field
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
              // Project list
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
                        // No project option
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
                        // Project list
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

                                // Parse color - remove # if present
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
                                    // Fallback to blue if parsing fails
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
}

/// Mobile full-screen session start widget
class _SessionStartScreen extends StatefulWidget {
  final PomodoroSessionType type;
  final PomodoroSessionController controller;
  final ProjectController projectController;

  const _SessionStartScreen({
    required this.type,
    required this.controller,
    required this.projectController,
  });

  @override
  State<_SessionStartScreen> createState() => _SessionStartScreenState();
}

class _SessionStartScreenState extends State<_SessionStartScreen> {
  final _titleController = TextEditingController();
  String? _selectedProjectId;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Start ${widget.type.displayName}'),
        actions: [
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title field
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
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
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Select Project (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            // Project list
            Expanded(
              child: AsyncStreamBuilder<List<Project>>(
                state: widget.projectController,
                builder: (context, projects) {
                  final activeProjects = projects
                      .where(
                        (p) =>
                            p.status == ProjectStatus.active && !p.isArchived,
                      )
                      .toList();

                  return ListView(
                    children: [
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
                      // Project list
                      if (activeProjects.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: Text('No active projects')),
                        )
                      else
                        ...activeProjects.map((project) {
                          // Parse color - remove # if present
                          Color projectColor = Colors.blue;
                          if (project.color != null) {
                            try {
                              final colorStr = project.color!.replaceAll(
                                '#',
                                '',
                              );
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
                        }),
                    ],
                  );
                },
                loadingBuilder: (_) =>
                    const Center(child: CircularProgressIndicator()),
                errorBuilder: (context, message) =>
                    Center(child: Text('Error loading projects: $message')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for timer circle
class TimerPainter extends CustomPainter {
  final double progress;
  final bool isRunning;

  TimerPainter({required this.progress, required this.isRunning});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    canvas.drawCircle(center, radius - 6, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = isRunning ? Colors.blue : Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(TimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isRunning != isRunning;
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
