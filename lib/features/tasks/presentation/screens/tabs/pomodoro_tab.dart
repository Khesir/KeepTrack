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
import 'package:keep_track/features/tasks/presentation/state/pomodoro_session_controller.dart';
import 'package:keep_track/features/tasks/presentation/state/task_controller.dart';
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
  late final SupabaseService _supabaseService;

  PomodoroSettings _settings = const PomodoroSettings();
  int _selectedTabIndex = 0; // 0 = Sessions, 1 = Tasks

  @override
  void registerServices() {
    _supabaseService = locator.get<SupabaseService>();
    _controller = locator.get<PomodoroSessionController>();
    _taskController = locator.get<TaskController>();
  }

  @override
  void onReady() {
    configureLayout(title: 'Pomodoro', showBottomNav: true);
    _taskController.loadTasks();
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
                  isRunning ? 'In Progress' : 'Paused',
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
      onPressed: () => _controller.startSession(type),
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
                          .where((t) => session.tasksCleared.contains(t.id))
                          .toList();

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: clearedTasks.length,
                        itemBuilder: (context, index) {
                          final task = clearedTasks[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.check,
                              color: Colors.green,
                              size: 20,
                            ),
                            title: Text(task.title),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                size: 20,
                              ),
                              onPressed: () =>
                                  _controller.removeClearedTask(task.id!),
                            ),
                          );
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
        title: Text(session.type.displayName),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: priorityColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(task.title),
        subtitle: task.description != null ? Text(task.description!) : null,
        trailing: session != null
            ? IconButton(
                icon: const Icon(Icons.add_task),
                onPressed: () => _controller.addClearedTask(task.id!),
                tooltip: 'Mark as cleared',
              )
            : null,
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
