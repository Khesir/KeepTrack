import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:persona_codex/core/ui/app_layout_controller.dart';
import 'package:persona_codex/core/ui/ui.dart';

/// New Task Management Screen with Calendar View and Subtasks
class TasksHomeScreenNew extends ScopedScreen {
  const TasksHomeScreenNew({super.key});

  @override
  State<TasksHomeScreenNew> createState() => _TasksHomeScreenNewState();
}

class _TasksHomeScreenNewState extends ScopedScreenState<TasksHomeScreenNew>
    with AppLayoutControlled {
  CalendarViewMode _viewMode = CalendarViewMode.month;
  DateTime _selectedDate = DateTime.now();
  TaskItem? _selectedTask;
  bool _isPomodoroActive = false;
  int _pomodoroMinutesRemaining = 25;

  @override
  void registerServices() {
    // Services will be wired later
  }

  @override
  void onReady() {
    configureLayout(title: 'Tasks', showBottomNav: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // View Mode Selector
        _buildViewModeSelector(),

        // Pomodoro Session Widget (shows when active or for today's tasks)
        if (_isPomodoroActive || _isToday(_selectedDate))
          _buildPomodoroWidget(),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Calendar Grid View
                _buildCalendarGrid(),
                const SizedBox(height: 24),

                // Task List with Subtasks
                _buildTaskList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  Widget _buildViewModeSelector() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: _buildViewModeButton(
                'Month',
                CalendarViewMode.month,
                Icons.calendar_month,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildViewModeButton(
                'Week',
                CalendarViewMode.week,
                Icons.calendar_view_week,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildViewModeButton(
                'Day',
                CalendarViewMode.day,
                Icons.calendar_today,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeButton(String label, CalendarViewMode mode, IconData icon) {
    final isSelected = _viewMode == mode;
    return Material(
      color: isSelected
          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => setState(() => _viewMode = mode),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPomodoroWidget() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.timer, color: Colors.red[700]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isPomodoroActive ? 'Pomodoro Session' : 'Ready for Focus',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red[900],
                        ),
                      ),
                      Text(
                        _isPomodoroActive
                            ? '$_pomodoroMinutesRemaining minutes remaining'
                            : 'Start a pomodoro session',
                        style: TextStyle(fontSize: 12, color: Colors.red[700]),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _isPomodoroActive = !_isPomodoroActive);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_isPomodoroActive ? 'Stop' : 'Start'),
                ),
              ],
            ),
            if (_isPomodoroActive) ...[
              const SizedBox(height: 12),
              Text(
                'Today\'s Tasks Available',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[900],
                ),
              ),
              const SizedBox(height: 8),
              ...dummyTasks
                  .where((task) => task.parentId == null && _isToday(task.dueDate))
                  .take(3)
                  .map((task) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 8, color: Colors.red[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _getPreviousPeriod(_selectedDate, _viewMode);
                    });
                  },
                ),
                Text(
                  _getCalendarTitle(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _selectedDate = _getNextPeriod(_selectedDate, _viewMode);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Calendar Grid
            if (_viewMode == CalendarViewMode.month)
              _buildMonthGrid()
            else if (_viewMode == CalendarViewMode.week)
              _buildWeekGrid()
            else
              _buildDayView(),
          ],
        ),
      ),
    );
  }

  String _getCalendarTitle() {
    switch (_viewMode) {
      case CalendarViewMode.month:
        return DateFormat('MMMM yyyy').format(_selectedDate);
      case CalendarViewMode.week:
        final weekStart = _getWeekStart(_selectedDate);
        final weekEnd = weekStart.add(const Duration(days: 6));
        return '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d, yyyy').format(weekEnd)}';
      case CalendarViewMode.day:
        return DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate);
    }
  }

  DateTime _getPreviousPeriod(DateTime date, CalendarViewMode mode) {
    switch (mode) {
      case CalendarViewMode.month:
        return DateTime(date.year, date.month - 1, 1);
      case CalendarViewMode.week:
        return date.subtract(const Duration(days: 7));
      case CalendarViewMode.day:
        return date.subtract(const Duration(days: 1));
    }
  }

  DateTime _getNextPeriod(DateTime date, CalendarViewMode mode) {
    switch (mode) {
      case CalendarViewMode.month:
        return DateTime(date.year, date.month + 1, 1);
      case CalendarViewMode.week:
        return date.add(const Duration(days: 7));
      case CalendarViewMode.day:
        return date.add(const Duration(days: 1));
    }
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  Widget _buildMonthGrid() {
    final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final startOffset = firstDay.weekday - 1;
    final totalDays = lastDay.day;

    return Column(
      children: [
        // Day names header
        Row(
          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),

        // Calendar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: 42, // 6 weeks
          itemBuilder: (context, index) {
            final dayNumber = index - startOffset + 1;

            if (dayNumber < 1 || dayNumber > totalDays) {
              return Container(); // Empty cell
            }

            final date = DateTime(_selectedDate.year, _selectedDate.month, dayNumber);
            final tasksOnDay = dummyTasks
                .where((task) => _isSameDay(task.dueDate, date))
                .length;

            return _buildDayCell(date, tasksOnDay);
          },
        ),
      ],
    );
  }

  Widget _buildWeekGrid() {
    final weekStart = _getWeekStart(_selectedDate);

    return Row(
      children: List.generate(7, (index) {
        final date = weekStart.add(Duration(days: index));
        final tasksOnDay = dummyTasks
            .where((task) => _isSameDay(task.dueDate, date))
            .length;

        return Expanded(
          child: Column(
            children: [
              Text(
                DateFormat('E').format(date),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              _buildDayCell(date, tasksOnDay, height: 80),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDayView() {
    final tasksToday = dummyTasks
        .where((task) => _isSameDay(task.dueDate, _selectedDate))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${tasksToday.length} task${tasksToday.length == 1 ? '' : 's'} today',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
          ),
          child: tasksToday.isEmpty
              ? Center(
                  child: Text(
                    'No tasks for this day',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: tasksToday.length,
                  itemBuilder: (context, index) {
                    final task = tasksToday[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: _getPriorityColor(task.priority),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              task.title,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDayCell(DateTime date, int taskCount, {double? height}) {
    final isToday = _isToday(date);
    final isSelected = _isSameDay(date, _selectedDate);

    return InkWell(
      onTap: () => setState(() => _selectedDate = date),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : isToday
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                  : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isToday
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (taskCount > 0) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$taskCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  Widget _buildTaskList() {
    final tasksOnSelectedDate = dummyTasks
        .where((task) =>
            task.parentId == null &&
            _isSameDay(task.dueDate, _selectedDate))
        .toList();

    if (tasksOnSelectedDate.isEmpty) {
      return Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.task_alt,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 8),
                Text(
                  'No tasks for ${DateFormat('MMM d').format(_selectedDate)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                Text(
                  'Tasks for ${DateFormat('MMM d').format(_selectedDate)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasksOnSelectedDate.length,
            itemBuilder: (context, index) {
              final task = tasksOnSelectedDate[index];
              return _buildTaskItem(task, 0);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(TaskItem task, int indentLevel) {
    final subtasks = dummyTasks.where((t) => t.parentId == task.id).toList();
    final isExpanded = _selectedTask?.id == task.id;

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _selectedTask = isExpanded ? null : task;
            });
          },
          child: Padding(
            padding: EdgeInsets.only(
              left: 16.0 + (indentLevel * 24.0),
              right: 16.0,
              top: 12.0,
              bottom: 12.0,
            ),
            child: Row(
              children: [
                // Priority indicator
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getPriorityColor(task.priority),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),

                // Checkbox
                Checkbox(
                  value: task.isCompleted,
                  onChanged: (value) {
                    // Will be wired later
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
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.flag,
                            size: 12,
                            color: _getPriorityColor(task.priority),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.priority,
                            style: TextStyle(
                              fontSize: 11,
                              color: _getPriorityColor(task.priority),
                            ),
                          ),
                          if (task.pomodoroSessions > 0) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.timer,
                              size: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${task.pomodoroSessions} sessions',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                          if (subtasks.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.subdirectory_arrow_right,
                              size: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${subtasks.length} subtask${subtasks.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Expand/collapse icon
                if (subtasks.isNotEmpty || isExpanded)
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
              ],
            ),
          ),
        ),

        // Metadata when expanded
        if (isExpanded) ...[
          Container(
            margin: EdgeInsets.only(
              left: 16.0 + (indentLevel * 24.0),
              right: 16.0,
              bottom: 12.0,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetadataRow('Created', DateFormat('MMM d, yyyy').format(task.createdAt)),
                _buildMetadataRow('Due', DateFormat('MMM d, yyyy HH:mm').format(task.dueDate)),
                _buildMetadataRow('Status', task.status),
                _buildMetadataRow('Priority', task.priority),
                if (task.tags.isNotEmpty)
                  _buildMetadataRow('Tags', task.tags.join(', ')),
                if (task.estimatedMinutes != null)
                  _buildMetadataRow('Estimated', '${task.estimatedMinutes} min'),
                if (task.pomodoroSessions > 0)
                  _buildMetadataRow('Pomodoro Sessions', '${task.pomodoroSessions}'),
              ],
            ),
          ),
        ],

        // Subtasks (indented)
        ...subtasks.map((subtask) => _buildTaskItem(subtask, indentLevel + 1)),

        if (indentLevel == 0)
          const Divider(height: 1),
      ],
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
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

enum CalendarViewMode { month, week, day }

// Dummy Data Classes
class TaskItem {
  final String id;
  final String? parentId;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final DateTime createdAt;
  final DateTime dueDate;
  final bool isCompleted;
  final List<String> tags;
  final int? estimatedMinutes;
  final int pomodoroSessions;

  TaskItem({
    required this.id,
    this.parentId,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.dueDate,
    this.isCompleted = false,
    this.tags = const [],
    this.estimatedMinutes,
    this.pomodoroSessions = 0,
  });
}

// Dummy Data
final dummyTasks = [
  TaskItem(
    id: '1',
    title: 'Complete project proposal',
    description: 'Write and submit Q1 project proposal',
    status: 'In Progress',
    priority: 'Urgent',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    dueDate: DateTime.now(),
    tags: ['work', 'important'],
    estimatedMinutes: 120,
    pomodoroSessions: 3,
  ),
  TaskItem(
    id: '1.1',
    parentId: '1',
    title: 'Research market trends',
    status: 'Completed',
    priority: 'High',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    dueDate: DateTime.now(),
    isCompleted: true,
    pomodoroSessions: 2,
  ),
  TaskItem(
    id: '1.2',
    parentId: '1',
    title: 'Draft executive summary',
    status: 'In Progress',
    priority: 'High',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    dueDate: DateTime.now(),
    pomodoroSessions: 1,
  ),
  TaskItem(
    id: '1.3',
    parentId: '1',
    title: 'Get approval from stakeholders',
    status: 'To Do',
    priority: 'Urgent',
    createdAt: DateTime.now(),
    dueDate: DateTime.now(),
  ),
  TaskItem(
    id: '2',
    title: 'Team meeting at 2 PM',
    description: 'Discuss sprint retrospective',
    status: 'To Do',
    priority: 'Medium',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    dueDate: DateTime.now(),
    tags: ['meeting'],
    estimatedMinutes: 60,
  ),
  TaskItem(
    id: '3',
    title: 'Review code changes',
    description: 'Review PR #234 and PR #235',
    status: 'To Do',
    priority: 'High',
    createdAt: DateTime.now(),
    dueDate: DateTime.now().add(const Duration(days: 1)),
    tags: ['code-review', 'urgent'],
    estimatedMinutes: 45,
  ),
  TaskItem(
    id: '3.1',
    parentId: '3',
    title: 'Review PR #234',
    status: 'To Do',
    priority: 'High',
    createdAt: DateTime.now(),
    dueDate: DateTime.now().add(const Duration(days: 1)),
  ),
  TaskItem(
    id: '3.2',
    parentId: '3',
    title: 'Review PR #235',
    status: 'To Do',
    priority: 'High',
    createdAt: DateTime.now(),
    dueDate: DateTime.now().add(const Duration(days: 1)),
  ),
  TaskItem(
    id: '4',
    title: 'Update documentation',
    status: 'To Do',
    priority: 'Low',
    createdAt: DateTime.now(),
    dueDate: DateTime.now().add(const Duration(days: 3)),
    tags: ['docs'],
    estimatedMinutes: 90,
  ),
  TaskItem(
    id: '5',
    title: 'Design system updates',
    description: 'Update color palette and typography',
    status: 'To Do',
    priority: 'Medium',
    createdAt: DateTime.now(),
    dueDate: DateTime.now().add(const Duration(days: 5)),
    tags: ['design', 'ui'],
    estimatedMinutes: 180,
    pomodoroSessions: 1,
  ),
];
