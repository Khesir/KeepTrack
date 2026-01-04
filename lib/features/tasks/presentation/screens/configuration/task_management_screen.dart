import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/features/tasks/modules/projects/domain/entities/project.dart';
import 'package:keep_track/features/tasks/modules/tasks/domain/entities/task.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';

import '../../state/project_controller.dart';
import '../../state/task_controller.dart';
import 'widgets/task_management_dialog.dart';

class TaskManagementScreen extends StatefulWidget {
  const TaskManagementScreen({super.key});

  @override
  State<TaskManagementScreen> createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends State<TaskManagementScreen> {
  late final TaskController _controller;
  late final ProjectController _projectController;
  late final SupabaseService supabaseService;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
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
              // Filter to show only main tasks (not subtasks) at top level
              final mainTasks = tasks.where((t) => !t.isSubtask).toList();

              return Column(
                children: [
                  // Stats card - always shown
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: ListTile(
                      title: const Text('Total Tasks'),
                      subtitle: Text(
                        '${tasks.where((t) => t.status == TaskStatus.completed).length} completed',
                      ),
                      trailing: Text(
                        '${tasks.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),

                  // Tasks list or empty state
                  Expanded(
                    child: mainTasks.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.task_alt,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text('No tasks found.'),
                                SizedBox(height: 8),
                                Text(
                                  'Tap + to create your first task',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: mainTasks.length,
                            itemBuilder: (context, index) {
                              final task = mainTasks[index];
                              return _buildTaskWithSubtasks(
                                task,
                                projects,
                                tasks,
                                0, // Start at level 0 (no indentation)
                              );
                            },
                          ),
                  ),
                ],
              );
            },
            loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
            errorBuilder: (context, message) => Center(child: Text(message)),
          );
        },
        loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, message) => Center(child: Text(message)),
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
    final subtasks = allTasks.where((t) => t.parentTaskId == task.id).toList();
    final indentPadding = level * 24.0;

    return Padding(
      padding: EdgeInsets.only(left: indentPadding),
      child: Column(
        children: [
          _buildTaskCard(task, projects, allTasks, level),
          // Recursively render subtasks
          ...subtasks.map(
            (subtask) => _buildTaskWithSubtasks(
              subtask,
              projects,
              allTasks,
              level + 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(
    Task task,
    List<Project> projects,
    List<Task> allTasks,
    int level,
  ) {
    final subtaskCount = allTasks.where((t) => t.parentTaskId == task.id).length;
    final isSubtask = level > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: _getPriorityColor(task.priority),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            title: Row(
              children: [
                if (isSubtask) ...[
                  Icon(
                    Icons.subdirectory_arrow_right,
                    size: 14.0 + (2.0 * (3 - level.clamp(0, 3))), // Smaller for deeper levels
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(child: Text(task.title)),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.description != null)
                  Text(
                    task.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      task.status.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (task.dueDate != null)
                      Text(
                        'Due: ${DateFormat('MMM d, yyyy').format(task.dueDate!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                      ),
                    if (subtaskCount > 0) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.list, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 2),
                      Text(
                        '$subtaskCount',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: Icon(
              task.isCompleted
                  ? Icons.check_circle
                  : Icons.circle_outlined,
              color: task.isCompleted ? Colors.green : Colors.grey,
            ),
            onTap: () => _showTaskDialog(
              task: task,
              projects: projects,
            ),
          ),
          // Add Subtask button for all tasks
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
