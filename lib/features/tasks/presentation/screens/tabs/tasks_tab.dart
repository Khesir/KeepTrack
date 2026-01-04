import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/features/tasks/modules/tasks/domain/entities/task.dart';
import 'package:keep_track/features/tasks/presentation/state/task_controller.dart';

/// Tasks Tab with List View
class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  late final TaskController _controller;
  Task? _selectedTask;

  @override
  void initState() {
    super.initState();
    _controller = locator.get<TaskController>();
  }

  @override
  Widget build(BuildContext context) {
    return AsyncStreamBuilder<List<Task>>(
      state: _controller,
      builder: (context, tasks) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Tasks',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${tasks.length} task${tasks.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Empty State or Task List
              if (tasks.isEmpty) _buildEmptyState() else _buildTaskList(tasks),
            ],
          ),
        );
      },
      loadingBuilder: (_) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      ),
      errorBuilder: (context, message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error loading tasks',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _controller.loadTasks(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64.0),
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
              'No tasks yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first task to get started',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    // Filter to show only main tasks (not subtasks) at top level
    final mainTasks = tasks.where((t) => !t.isSubtask).toList();

    return Card(
      elevation: 0,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: mainTasks.length,
        itemBuilder: (context, index) {
          final task = mainTasks[index];
          return _buildTaskWithSubtasks(task, tasks, 0);
        },
      ),
    );
  }

  /// Recursively builds a task and all its subtasks
  Widget _buildTaskWithSubtasks(Task task, List<Task> allTasks, int level) {
    final subtasks = allTasks.where((t) => t.parentTaskId == task.id).toList();
    final indentPadding = level * 24.0;

    return Padding(
      padding: EdgeInsets.only(left: indentPadding),
      child: Column(
        children: [
          _buildTaskItem(task, allTasks, level),
          // Recursively render subtasks
          ...subtasks.map(
            (subtask) => _buildTaskWithSubtasks(subtask, allTasks, level + 1),
          ),
        ],
      ),
    );
  }

  /// Get all descendant tasks (subtasks, sub-subtasks, etc.)
  List<Task> _getAllDescendants(Task task, List<Task> allTasks) {
    final descendants = <Task>[];
    final directChildren = allTasks.where((t) => t.parentTaskId == task.id).toList();

    for (final child in directChildren) {
      descendants.add(child);
      descendants.addAll(_getAllDescendants(child, allTasks));
    }

    return descendants;
  }

  /// Toggle task completion with cascading to subtasks
  Future<void> _toggleTaskCompletion(Task task, List<Task> allTasks, bool? value) async {
    if (value == null) return;

    // Update the task itself
    final updatedTask = task.copyWith(
      status: value ? TaskStatus.completed : TaskStatus.todo,
      completedAt: value ? DateTime.now() : null,
    );
    await _controller.updateTask(updatedTask);

    // If checking (completing), cascade to all descendants
    if (value) {
      final descendants = _getAllDescendants(task, allTasks);
      for (final descendant in descendants) {
        final updatedDescendant = descendant.copyWith(
          status: TaskStatus.completed,
          completedAt: DateTime.now(),
        );
        await _controller.updateTask(updatedDescendant);
      }
    }
  }

  Widget _buildTaskItem(Task task, List<Task> allTasks, int level) {
    final isExpanded = _selectedTask?.id == task.id;
    final isSubtask = level > 0;
    final subtaskCount = allTasks.where((t) => t.parentTaskId == task.id).length;

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _selectedTask = isExpanded ? null : task;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                  onChanged: (value) => _toggleTaskCompletion(task, allTasks, value),
                ),
                const SizedBox(width: 8),

                // Task info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isSubtask) ...[
                            Icon(
                              Icons.subdirectory_arrow_right,
                              size: 14.0 + (2.0 * (3 - level.clamp(0, 3))),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ],
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
                            task.priority.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              color: _getPriorityColor(task.priority),
                            ),
                          ),
                          if (task.dueDate != null) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM d').format(task.dueDate!),
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                          if (subtaskCount > 0) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.list, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 2),
                            Text(
                              '$subtaskCount',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Expand/collapse icon
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

        // Metadata when expanded
        if (isExpanded) ...[
          Container(
            margin: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 12.0,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.createdAt != null)
                  _buildMetadataRow(
                    'Created',
                    DateFormat('MMM d, yyyy').format(task.createdAt!),
                  ),
                if (task.dueDate != null)
                  _buildMetadataRow(
                    'Due',
                    DateFormat('MMM d, yyyy HH:mm').format(task.dueDate!),
                  ),
                _buildMetadataRow('Status', task.status.displayName),
                _buildMetadataRow('Priority', task.priority.displayName),
                if (task.tags.isNotEmpty)
                  _buildMetadataRow('Tags', task.tags.join(', ')),
                if (task.isMoneyRelated) ...[
                  _buildMetadataRow('Money Related', 'Yes'),
                  if (task.expectedAmount != null)
                    _buildMetadataRow(
                      'Expected Amount',
                      '₱${task.expectedAmount!.toStringAsFixed(2)}',
                    ),
                  if (task.transactionType != null)
                    _buildMetadataRow(
                      'Transaction Type',
                      task.transactionType!.displayName,
                    ),
                ],
              ],
            ),
          ),
        ],

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
            width: 120,
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
}
