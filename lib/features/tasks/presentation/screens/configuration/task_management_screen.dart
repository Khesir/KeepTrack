import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/ui/app_layout_controller.dart';
import 'package:keep_track/core/ui/ui.dart';
import 'package:keep_track/features/tasks/modules/projects/domain/entities/project.dart';
import 'package:keep_track/features/tasks/modules/tasks/domain/entities/task.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';

import '../../state/project_controller.dart';
import '../../state/task_controller.dart';
import '../tabs/task/components/task_management_dialog.dart';

enum StatusFilter { all, todo, inProgress, completed, cancelled }

enum DueDateFilter { all, dueNow, dueThisWeek, dueThisMonth }

class TaskManagementScreen extends ScopedScreen {
  const TaskManagementScreen({super.key});

  @override
  State<TaskManagementScreen> createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState
    extends ScopedScreenState<TaskManagementScreen> {
  late final TaskController _controller;
  late final ProjectController _projectController;
  late final SupabaseService supabaseService;

  StatusFilter _statusFilter = StatusFilter.all;
  DueDateFilter _dueDateFilter = DueDateFilter.all;
  final Set<String> _expandedTaskIds = {};

  @override
  void registerServices() {
    _controller = locator.get<TaskController>();
    _projectController = locator.get<ProjectController>();
    supabaseService = locator.get<SupabaseService>();
  }

  void _showTaskDialog({
    Task? task,
    List<Project>? projects,
    String? parentTaskId,
  }) {
    showDialog(
      context: context,
      builder: (context) => TaskManagementDialog(
        task: task,
        userId: supabaseService.userId!,
        projects: projects,
        parentTaskId: parentTaskId,
        onSave: (updatedTask) async {
          try {
            if (task != null) {
              await _controller.updateTask(updatedTask);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Task updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else {
              await _controller.createTask(updatedTask);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Task created successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        onDelete: task != null
            ? () async {
                try {
                  await _controller.deleteTask(task.id!);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Task deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting task: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            : null,
      ),
    );
  }

  List<Task> _filterTasks(List<Task> tasks) {
    var filtered = tasks.where((task) => !task.isArchived).toList();

    // Filter by status
    if (_statusFilter != StatusFilter.all) {
      filtered = filtered.where((task) {
        switch (_statusFilter) {
          case StatusFilter.todo:
            return task.status == TaskStatus.todo;
          case StatusFilter.inProgress:
            return task.status == TaskStatus.inProgress;
          case StatusFilter.completed:
            return task.status == TaskStatus.completed;
          case StatusFilter.cancelled:
            return task.status == TaskStatus.cancelled;
          case StatusFilter.all:
            return true;
        }
      }).toList();
    }

    // Filter by due date
    if (_dueDateFilter != DueDateFilter.all) {
      final now = DateTime.now();
      filtered = filtered.where((task) {
        if (task.dueDate == null) return false;

        switch (_dueDateFilter) {
          case DueDateFilter.dueNow:
            return task.dueDate!.isBefore(now) ||
                _isSameDay(task.dueDate!, now);
          case DueDateFilter.dueThisWeek:
            final weekEnd = now.add(const Duration(days: 7));
            return task.dueDate!.isBefore(weekEnd);
          case DueDateFilter.dueThisMonth:
            return task.dueDate!.year == now.year &&
                task.dueDate!.month == now.month;
          case DueDateFilter.all:
            return true;
        }
      }).toList();
    }

    return filtered;
  }

  List<Task> _sortTasksByPriority(List<Task> tasks) {
    final sorted = List<Task>.from(tasks);
    sorted.sort((a, b) {
      // Sort by priority first
      final priorityOrder = {
        TaskPriority.urgent: 0,
        TaskPriority.high: 1,
        TaskPriority.medium: 2,
        TaskPriority.low: 3,
      };
      final priorityCompare = priorityOrder[a.priority]!.compareTo(
        priorityOrder[b.priority]!,
      );
      if (priorityCompare != 0) return priorityCompare;

      // Then by due date
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      }
      if (a.dueDate != null) return -1;
      if (b.dueDate != null) return 1;

      return 0;
    });
    return sorted;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Tasks'),
        actions: [
          AsyncStreamBuilder<List<Project>>(
            state: _projectController,
            builder: (context, projects) {
              return IconButton(
                onPressed: () => _showTaskDialog(projects: projects),
                icon: const Icon(Icons.add),
              );
            },
            loadingBuilder: (_) => IconButton(
              onPressed: () => _showTaskDialog(),
              icon: const Icon(Icons.add),
            ),
            errorBuilder: (_, __) => IconButton(
              onPressed: () => _showTaskDialog(),
              icon: const Icon(Icons.add),
            ),
          ),
        ],
      ),
      body: AsyncStreamBuilder<List<Project>>(
        state: _projectController,
        builder: (context, projects) {
          return AsyncStreamBuilder<List<Task>>(
            state: _controller,
            builder: (context, tasks) {
              final filteredTasks = _filterTasks(tasks);
              final sortedTasks = _sortTasksByPriority(filteredTasks);
              final mainTasks = sortedTasks.where((t) => !t.isSubtask).toList();

              return Column(
                children: [
                  // Summary Card
                  _buildSummaryCard(tasks),

                  // Filters Section
                  _buildFiltersSection(),

                  // Tasks list or empty state
                  Expanded(
                    child: mainTasks.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: mainTasks.length,
                            itemBuilder: (context, index) {
                              final task = mainTasks[index];
                              return _buildTaskWithSubtasks(
                                task,
                                projects,
                                tasks,
                                0,
                              );
                            },
                          ),
                  ),
                ],
              );
            },
            loadingBuilder: (_) =>
                const Center(child: CircularProgressIndicator()),
            errorBuilder: (context, message) => Center(child: Text(message)),
          );
        },
        loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, message) => Center(child: Text(message)),
      ),
    );
  }

  Widget _buildSummaryCard(List<Task> tasks) {
    final totalTasks = tasks.length;
    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final inProgressTasks = tasks
        .where((t) => t.status == TaskStatus.inProgress)
        .length;
    final todoTasks = tasks.where((t) => t.status == TaskStatus.todo).length;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Overview',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatChip('Total', totalTasks, Colors.blue),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatChip('To-do', todoTasks, Colors.orange),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatChip(
                    'In Progress',
                    inProgressTasks,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatChip('Done', completedTasks, Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Filter
          Text(
            'Status',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', _statusFilter == StatusFilter.all, () {
                  setState(() => _statusFilter = StatusFilter.all);
                }),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'To-do',
                  _statusFilter == StatusFilter.todo,
                  () {
                    setState(() => _statusFilter = StatusFilter.todo);
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'In Progress',
                  _statusFilter == StatusFilter.inProgress,
                  () {
                    setState(() => _statusFilter = StatusFilter.inProgress);
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Completed',
                  _statusFilter == StatusFilter.completed,
                  () {
                    setState(() => _statusFilter = StatusFilter.completed);
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Cancelled',
                  _statusFilter == StatusFilter.cancelled,
                  () {
                    setState(() => _statusFilter = StatusFilter.cancelled);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Due Date Filter
          Text(
            'Due Date',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  'All Tasks',
                  _dueDateFilter == DueDateFilter.all,
                  () {
                    setState(() => _dueDateFilter = DueDateFilter.all);
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Due Now',
                  _dueDateFilter == DueDateFilter.dueNow,
                  () {
                    setState(() => _dueDateFilter = DueDateFilter.dueNow);
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Due This Week',
                  _dueDateFilter == DueDateFilter.dueThisWeek,
                  () {
                    setState(() => _dueDateFilter = DueDateFilter.dueThisWeek);
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Due This Month',
                  _dueDateFilter == DueDateFilter.dueThisMonth,
                  () {
                    setState(() => _dueDateFilter = DueDateFilter.dueThisMonth);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: Theme.of(context).colorScheme.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or tap + to create a task',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  /// Recursively builds a task and all its subtasks
  Widget _buildTaskWithSubtasks(
    Task task,
    List<Project> projects,
    List<Task> allTasks,
    int level,
  ) {
    final isExpanded = task.id != null && _expandedTaskIds.contains(task.id);
    final subtasks = allTasks.where((t) => t.parentTaskId == task.id).toList();
    final subtaskCount = subtasks.length;

    return Column(
      children: [
        _buildTaskCard(
          task,
          projects,
          allTasks,
          level,
          isExpanded,
          subtaskCount,
        ),

        // Show subtasks when expanded
        if (isExpanded && subtaskCount > 0)
          ...subtasks.map(
            (subtask) =>
                _buildTaskWithSubtasks(subtask, projects, allTasks, level + 1),
          ),
      ],
    );
  }

  Widget _buildTaskCard(
    Task task,
    List<Project> projects,
    List<Task> allTasks,
    int level,
    bool isExpanded,
    int subtaskCount,
  ) {
    final indentPadding = level * 24.0;

    return Container(
      margin: EdgeInsets.only(bottom: 8, left: indentPadding),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surface.withOpacity(0.3 - (level * 0.05)),
        borderRadius: BorderRadius.circular(8),
        border: level > 0
            ? Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              )
            : null,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: subtaskCount > 0
                ? () {
                    setState(() {
                      if (task.id != null) {
                        if (isExpanded) {
                          _expandedTaskIds.remove(task.id);
                        } else {
                          _expandedTaskIds.add(task.id!);
                        }
                      }
                    });
                  }
                : () => _showTaskDialog(task: task, projects: projects),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Priority indicator
                  Container(
                    width: level > 0 ? 3 : 4,
                    height: level > 0 ? 40 : 50,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(task.priority),
                      borderRadius: BorderRadius.circular(level > 0 ? 1.5 : 2),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Checkbox
                  SizedBox(
                    width: level > 0 ? 24 : null,
                    height: level > 0 ? 24 : null,
                    child: Checkbox(
                      value: task.isCompleted,
                      onChanged: (value) =>
                          _toggleTaskCompletion(task, allTasks, value),
                    ),
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
                            fontSize: level > 0 ? 14 : 15,
                            fontWeight: level > 0
                                ? FontWeight.w500
                                : FontWeight.w600,
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
                              fontSize: level > 0 ? 11 : 12,
                              color: Theme.of(context).colorScheme.onSurface
                                  .withOpacity(level > 0 ? 0.5 : 0.6),
                            ),
                            maxLines: level > 0 ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: level > 0 ? 6 : 8,
                          runSpacing: level > 0 ? 2 : 4,
                          children: [
                            if (level == 0)
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
                            _buildTaskBadge(
                              task.dueDate != null
                                  ? DateFormat(
                                      'MMM d, h:mm a',
                                    ).format(task.dueDate!)
                                  : 'No date',
                              task.dueDate != null
                                  ? Colors.grey[700]!
                                  : Colors.grey[400]!,
                              Icons.calendar_today,
                            ),
                            if (subtaskCount > 0)
                              _buildTaskBadge(
                                '$subtaskCount subtask${subtaskCount > 1 ? 's' : ''}',
                                Colors.blue[700]!,
                                Icons.list,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Edit button for tasks without subtasks
                  if (subtaskCount == 0)
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () =>
                          _showTaskDialog(task: task, projects: projects),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),

                  // Expand icon for tasks with subtasks
                  if (subtaskCount > 0)
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                ],
              ),
            ),
          ),

          // Add Subtask button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => _showTaskDialog(
                    projects: projects,
                    parentTaskId: task.id,
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Subtask'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleTaskCompletion(
    Task task,
    List<Task> allTasks,
    bool? value,
  ) async {
    if (value == null) return;

    final updatedTask = task.copyWith(
      status: value ? TaskStatus.completed : TaskStatus.todo,
      completedAt: value ? DateTime.now() : null,
    );
    await _controller.updateTask(updatedTask);
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
        return Colors.grey[600]!;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Colors.orange[700]!;
      case TaskStatus.inProgress:
        return Colors.purple[700]!;
      case TaskStatus.completed:
        return Colors.green[700]!;
      case TaskStatus.cancelled:
        return Colors.red[700]!;
    }
  }
}
