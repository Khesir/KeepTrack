import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:persona_codex/core/di/service_locator.dart';
import 'package:persona_codex/core/state/stream_builder_widget.dart';
import 'package:persona_codex/features/tasks/modules/projects/domain/entities/project.dart';
import 'package:persona_codex/features/tasks/modules/tasks/domain/entities/task.dart';
import 'package:persona_codex/shared/infrastructure/supabase/supabase_service.dart';

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

  void _showTaskDialog({Task? task, List<Project>? projects, List<Task>? allTasks}) {
    // Filter to get only main tasks (not subtasks) for parent task selection
    final parentTasks = allTasks?.where((t) => !t.isSubtask).toList();

    showDialog(
      context: context,
      builder: (context) => TaskManagementDialog(
        task: task,
        userId: supabaseService.userId!,
        projects: projects,
        parentTasks: parentTasks,
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
          AsyncStreamBuilder<List<Task>>(
            state: _controller,
            builder: (context, tasks) {
              return AsyncStreamBuilder<List<Project>>(
                state: _projectController,
                builder: (context, projects) {
                  return IconButton(
                    onPressed: () => _showTaskDialog(
                      projects: projects,
                      allTasks: tasks,
                    ),
                    icon: const Icon(Icons.add),
                  );
                },
                loadingBuilder: (_) => IconButton(
                  onPressed: () => _showTaskDialog(allTasks: tasks),
                  icon: const Icon(Icons.add),
                ),
                errorBuilder: (_, __) => IconButton(
                  onPressed: () => _showTaskDialog(allTasks: tasks),
                  icon: const Icon(Icons.add),
                ),
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
      body: AsyncStreamBuilder<List<Task>>(
        state: _controller,
        builder: (context, tasks) {
          return AsyncStreamBuilder<List<Project>>(
            state: _projectController,
            builder: (context, projects) {
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
                    child: tasks.isEmpty
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
                            itemCount: tasks.length,
                            itemBuilder: (context, index) {
                              final task = tasks[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: Container(
                                    width: 4,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _getPriorityColor(task.priority),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  title: Text(task.title),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: Icon(
                                    task.isCompleted
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    color: task.isCompleted
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                  onTap: () => _showTaskDialog(
                                    task: task,
                                    projects: projects,
                                    allTasks: tasks,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
            loadingBuilder: (_) => const SizedBox.shrink(),
            errorBuilder: (_, __) => const SizedBox.shrink(),
          );
        },
        loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
        errorBuilder: (context, message) => Center(child: Text(message)),
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
