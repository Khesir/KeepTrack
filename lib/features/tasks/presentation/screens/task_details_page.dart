import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/features/tasks/modules/tasks/domain/entities/task.dart';
import 'package:keep_track/features/tasks/presentation/state/task_controller.dart';
import 'package:keep_track/features/tasks/presentation/screens/configuration/widgets/task_management_dialog.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';

class TaskDetailsPage extends StatefulWidget {
  final Task task;

  const TaskDetailsPage({super.key, required this.task});

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  late final TaskController _controller;
  late final SupabaseService _supabaseService;

  @override
  void initState() {
    super.initState();
    _controller = locator.get<TaskController>();
    _supabaseService = locator.get<SupabaseService>();
  }

  void _showTaskEditDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => TaskManagementDialog(
        task: task,
        userId: _supabaseService.userId!,
        onSave: (updatedTask) async {
          try {
            await _controller.updateTask(updatedTask);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Task updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
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
        onDelete: () async {
          try {
            await _controller.deleteTask(task.id!);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Task deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
              Navigator.pop(context);
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
      ),
    );
  }

  void _showCreateSubtaskDialog(Task parentTask) {
    showDialog(
      context: context,
      builder: (context) => TaskManagementDialog(
        userId: _supabaseService.userId!,
        parentTaskId: parentTask.id,
        onSave: (newTask) async {
          try {
            await _controller.createTask(newTask);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Subtask created successfully'),
                  backgroundColor: Colors.green,
                ),
              );
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

  Widget _buildDetailSection(String title, IconData icon, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: content,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AsyncStreamBuilder<List<Task>>(
      state: _controller,
      builder: (context, allTasks) {
        final task = allTasks.firstWhere(
          (t) => t.id == widget.task.id,
          orElse: () => widget.task,
        );
        final subtasks = allTasks.where((t) => t.parentTaskId == task.id).toList();
        final isOverdue = task.dueDate != null &&
            task.dueDate!.isBefore(DateTime.now()) &&
            !task.isCompleted;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Task Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showCreateSubtaskDialog(task),
                tooltip: 'Create Subtask',
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showTaskEditDialog(task),
                tooltip: 'Edit Task',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task Title
                Row(
                  children: [
                    Checkbox(
                      value: task.isCompleted,
                      onChanged: (value) async {
                        if (value != null) {
                          final updatedTask = task.copyWith(
                            status: value ? TaskStatus.completed : TaskStatus.todo,
                            completedAt: value ? DateTime.now() : null,
                          );
                          await _controller.updateTask(updatedTask);
                        }
                      },
                    ),
                    Expanded(
                      child: Text(
                        task.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Priority Indicator
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(task.priority).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getPriorityColor(task.priority).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.flag,
                        color: _getPriorityColor(task.priority),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Priority: ${task.priority.displayName}',
                        style: TextStyle(
                          color: _getPriorityColor(task.priority),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Status Badge
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (isOverdue)
                      Chip(
                        avatar: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                          size: 18,
                        ),
                        label: const Text('OVERDUE'),
                        backgroundColor: Colors.red.withOpacity(0.1),
                        side: BorderSide(color: Colors.red.withOpacity(0.5)),
                      ),
                    Chip(
                      avatar: Icon(
                        Icons.circle,
                        color: _getStatusColor(task.status),
                        size: 18,
                      ),
                      label: Text(task.status.displayName),
                      backgroundColor: _getStatusColor(task.status).withOpacity(0.1),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                if (task.description != null && task.description!.isNotEmpty) ...[
                  _buildDetailSection(
                    'Description',
                    Icons.subject,
                    Text(task.description!),
                  ),
                  const SizedBox(height: 16),
                ],

                // Due Date
                if (task.dueDate != null) ...[
                  _buildDetailSection(
                    'Due Date',
                    Icons.calendar_today,
                    Text(
                      DateFormat('EEEE, MMMM d, y - h:mm a').format(task.dueDate!),
                      style: TextStyle(
                        color: isOverdue ? Colors.red : null,
                        fontWeight: isOverdue ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Created Date
                if (task.createdAt != null) ...[
                  _buildDetailSection(
                    'Created',
                    Icons.add_circle_outline,
                    Text(DateFormat('MMMM d, y - h:mm a').format(task.createdAt!)),
                  ),
                  const SizedBox(height: 16),
                ],

                // Completed Date
                if (task.completedAt != null) ...[
                  _buildDetailSection(
                    'Completed',
                    Icons.check_circle,
                    Text(DateFormat('MMMM d, y - h:mm a').format(task.completedAt!)),
                  ),
                  const SizedBox(height: 16),
                ],

                // Tags
                if (task.tags.isNotEmpty) ...[
                  _buildDetailSection(
                    'Tags',
                    Icons.label,
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: task.tags
                          .map(
                            (tag) => Chip(
                              label: Text(tag, style: const TextStyle(fontSize: 12)),
                              backgroundColor: Colors.blue.withOpacity(0.1),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Subtasks
                if (subtasks.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtasks (${subtasks.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Subtask'),
                        onPressed: () => _showCreateSubtaskDialog(task),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...subtasks.map(
                    (subtask) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Checkbox(
                          value: subtask.isCompleted,
                          onChanged: (value) async {
                            if (value != null) {
                              final updated = subtask.copyWith(
                                status: value ? TaskStatus.completed : TaskStatus.todo,
                                completedAt: value ? DateTime.now() : null,
                              );
                              await _controller.updateTask(updated);
                            }
                          },
                        ),
                        title: Text(
                          subtask.title,
                          style: TextStyle(
                            decoration: subtask.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: subtask.description != null
                            ? Text(subtask.description!)
                            : null,
                        trailing: Icon(
                          Icons.circle,
                          color: _getStatusColor(subtask.status),
                          size: 12,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.list_alt,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No subtasks yet',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Create Subtask'),
                          onPressed: () => _showCreateSubtaskDialog(task),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
