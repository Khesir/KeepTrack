import 'package:flutter/material.dart';
import 'dart:async';

/// Pomodoro Session Tab
class PomodoroTab extends StatefulWidget {
  const PomodoroTab({super.key});

  @override
  State<PomodoroTab> createState() => _PomodoroTabState();
}

class _PomodoroTabState extends State<PomodoroTab> {
  bool _isActive = false;
  bool _isBreak = false;
  int _seconds = 25 * 60; // 25 minutes in seconds
  int _completedSessions = 0;
  Timer? _timer;
  String? _selectedTaskId;

  static const int workDuration = 25 * 60;
  static const int shortBreakDuration = 5 * 60;
  static const int longBreakDuration = 15 * 60;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _isActive = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        setState(() => _seconds--);
      } else {
        _onTimerComplete();
      }
    });
  }

  void _pauseTimer() {
    setState(() => _isActive = false);
    _timer?.cancel();
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isActive = false;
      _seconds = _isBreak ? shortBreakDuration : workDuration;
    });
  }

  void _onTimerComplete() {
    _timer?.cancel();
    setState(() {
      _isActive = false;
      if (_isBreak) {
        // Break completed, start work session
        _isBreak = false;
        _seconds = workDuration;
      } else {
        // Work session completed
        _completedSessions++;
        _isBreak = true;
        // Every 4 sessions, take a long break
        _seconds = (_completedSessions % 4 == 0) ? longBreakDuration : shortBreakDuration;
      }
    });
    // Show notification (would implement later)
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Pomodoro Timer Card
          _buildTimerCard(),
          const SizedBox(height: 24),

          // Session Stats
          _buildSessionStats(),
          const SizedBox(height: 24),

          // Available Tasks
          _buildAvailableTasks(),
        ],
      ),
    );
  }

  Widget _buildTimerCard() {
    final progress = _isBreak
        ? 1.0 - (_seconds / (_completedSessions % 4 == 0 ? longBreakDuration : shortBreakDuration))
        : 1.0 - (_seconds / workDuration);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            // Timer Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isBreak ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isBreak ? Icons.coffee : Icons.work,
                    size: 16,
                    color: _isBreak ? Colors.green[700] : Colors.red[700],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isBreak ? 'Break Time' : 'Focus Time',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isBreak ? Colors.green[900] : Colors.red[900],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Timer Display
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor: (_isBreak ? Colors.green : Colors.red).withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isBreak ? Colors.green[700]! : Colors.red[700]!,
                    ),
                  ),
                ),
                Text(
                  _formatTime(_seconds),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Timer Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isActive) ...[
                  ElevatedButton.icon(
                    onPressed: _pauseTimer,
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: _startTimer,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(_seconds == workDuration || _seconds == shortBreakDuration || _seconds == longBreakDuration
                        ? 'Start'
                        : 'Resume'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isBreak ? Colors.green[700] : Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ],
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: _resetTimer,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),

            // Session Info
            if (_selectedTaskId != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.task_alt,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Working on: ${_getTaskById(_selectedTaskId!)?.title ?? 'Unknown task'}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSessionStats() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Today\'s Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Sessions',
                    '$_completedSessions',
                    Icons.timer,
                    Colors.red[700]!,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Focus Time',
                    '${(_completedSessions * 25)} min',
                    Icons.access_time,
                    Colors.blue[700]!,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Next Break',
                    _completedSessions % 4 == 3 ? 'Long' : 'Short',
                    Icons.coffee,
                    Colors.green[700]!,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableTasks() {
    final todayTasks = pomodoroTasks.where((task) => !task.isCompleted).toList();

    return Card(
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.list,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Available Tasks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (todayTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No tasks available',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: todayTasks.length,
              itemBuilder: (context, index) {
                final task = todayTasks[index];
                final isSelected = _selectedTaskId == task.id;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedTaskId = isSelected ? null : task.id;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                          : null,
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: task.id,
                          groupValue: _selectedTaskId,
                          onChanged: (value) {
                            setState(() => _selectedTaskId = value);
                          },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.timer,
                                    size: 14,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${task.estimatedPomodoros} sessions',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getPriorityColor(task.priority).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      task.priority,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: _getPriorityColor(task.priority),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  PomodoroTaskItem? _getTaskById(String id) {
    try {
      return pomodoroTasks.firstWhere((task) => task.id == id);
    } catch (e) {
      return null;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red[700]!;
      case 'high':
        return Colors.orange[700]!;
      case 'medium':
        return Colors.blue[700]!;
      case 'low':
        return Colors.grey[600]!;
      default:
        return Colors.grey[600]!;
    }
  }
}

// Pomodoro Task Data Class
class PomodoroTaskItem {
  final String id;
  final String title;
  final String priority;
  final int estimatedPomodoros;
  final bool isCompleted;

  PomodoroTaskItem({
    required this.id,
    required this.title,
    required this.priority,
    required this.estimatedPomodoros,
    this.isCompleted = false,
  });
}

// Dummy Pomodoro Tasks
final pomodoroTasks = [
  PomodoroTaskItem(
    id: '1',
    title: 'Complete project proposal',
    priority: 'Urgent',
    estimatedPomodoros: 3,
  ),
  PomodoroTaskItem(
    id: '2',
    title: 'Team meeting preparation',
    priority: 'High',
    estimatedPomodoros: 2,
  ),
  PomodoroTaskItem(
    id: '3',
    title: 'Review code changes',
    priority: 'Medium',
    estimatedPomodoros: 1,
  ),
  PomodoroTaskItem(
    id: '4',
    title: 'Update documentation',
    priority: 'Low',
    estimatedPomodoros: 2,
  ),
  PomodoroTaskItem(
    id: '5',
    title: 'Design system updates',
    priority: 'Medium',
    estimatedPomodoros: 4,
  ),
];
