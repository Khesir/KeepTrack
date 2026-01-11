import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/features/tasks/modules/projects/domain/entities/project.dart';
import 'package:keep_track/features/tasks/modules/tasks/domain/entities/task.dart';
import 'package:keep_track/features/tasks/presentation/state/project_controller.dart';
import 'package:keep_track/features/tasks/presentation/state/task_controller.dart';
import 'package:keep_track/features/tasks/presentation/screens/tabs/task/components/task_management_dialog.dart';
import 'package:keep_track/features/tasks/presentation/screens/tabs/task/create_task_page.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';

class TaskDetailsPage extends StatefulWidget {
  final Task task;
  final bool isDrawerMode;
  const TaskDetailsPage({
    super.key,
    required this.task,
    this.isDrawerMode = false,
  });

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  late final TaskController _controller;
  late final ProjectController _projectController;
  late final SupabaseService _supabaseService;

  @override
  void initState() {
    super.initState();
    _controller = locator.get<TaskController>();
    _projectController = locator.get<ProjectController>();
    _supabaseService = locator.get<SupabaseService>();
    _projectController.loadActiveProjects();
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

  void _handleEditTask(Task task) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    if (isDesktop) {
      // Show dialog on desktop
      _showEditTaskDialog(task);
    } else {
      // Navigate to full page on mobile
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CreateTaskPage(task: task)),
      );
    }
  }

  void _showEditTaskDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => AsyncStreamBuilder<List<Project>>(
        state: _projectController,
        builder: (context, projects) {
          // Filter to only active projects
          final activeProjects = projects
              .where((p) => p.status == ProjectStatus.active && !p.isArchived)
              .toList();

          return Dialog(
            child: Container(
              width: 600,
              constraints: const BoxConstraints(maxHeight: 700),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Edit Task',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: TaskManagementDialog(
                      task: task,
                      userId: _supabaseService.userId!,
                      projects: activeProjects,
                      useDialogContent: true,
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
                            Navigator.pop(context); // Close dialog
                            Navigator.pop(context); // Close drawer
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
                  ),
                ],
              ),
            ),
          );
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
        Padding(padding: const EdgeInsets.only(left: 28), child: content),
      ],
    );
  }

  Widget _buildEditableDetailSection(
    String title,
    IconData icon,
    Widget content,
  ) {
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
        Padding(padding: const EdgeInsets.only(left: 28), child: content),
      ],
    );
  }

  void _showAddTagDialog(Task task) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Tag name',
            hintText: 'Enter tag name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final tagName = controller.text.trim();
              if (tagName.isNotEmpty) {
                if (!task.tags.contains(tagName)) {
                  final updatedTask = task.copyWith(
                    tags: [...task.tags, tagName],
                  );
                  await _controller.updateTask(updatedTask);
                }
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeTag(Task task, String tag) async {
    final updatedTask = task.copyWith(
      tags: task.tags.where((t) => t != tag).toList(),
    );
    await _controller.updateTask(updatedTask);
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
        final subtasks = allTasks
            .where((t) => t.parentTaskId == task.id)
            .toList();
        final isOverdue =
            task.dueDate != null &&
            task.dueDate!.isBefore(DateTime.now()) &&
            !task.isCompleted;

        final content = Column(
          children: [
            // Header (for drawer mode) or AppBar replacement
            if (widget.isDrawerMode)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Task Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _handleEditTask(task),
                      tooltip: 'Edit Task',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Task Title with Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: task.isCompleted,
                        onChanged: (value) async {
                          if (value != null) {
                            final updatedTask = task.copyWith(
                              status: value
                                  ? TaskStatus.completed
                                  : TaskStatus.todo,
                              completedAt: value ? DateTime.now() : null,
                            );
                            await _controller.updateTask(updatedTask);
                          }
                        },
                      ),
                      Expanded(
                        child: Text(
                          task.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
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

                  // Overdue Badge
                  if (isOverdue) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'OVERDUE',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Priority - Editable
                  _buildEditableDetailSection(
                    'Priority',
                    Icons.flag,
                    DropdownButton<TaskPriority>(
                      value: task.priority,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: TaskPriority.values.map((priority) {
                        return DropdownMenuItem(
                          value: priority,
                          child: Row(
                            children: [
                              Icon(
                                Icons.flag,
                                color: _getPriorityColor(priority),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                priority.displayName,
                                style: TextStyle(
                                  color: _getPriorityColor(priority),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (newPriority) async {
                        if (newPriority != null) {
                          final updatedTask = task.copyWith(
                            priority: newPriority,
                          );
                          await _controller.updateTask(updatedTask);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status - Editable
                  _buildEditableDetailSection(
                    'Status',
                    Icons.circle,
                    DropdownButton<TaskStatus>(
                      value: task.status,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: TaskStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Row(
                            children: [
                              Icon(
                                Icons.circle,
                                color: _getStatusColor(status),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                status.displayName,
                                style: TextStyle(
                                  color: _getStatusColor(status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (newStatus) async {
                        if (newStatus != null) {
                          final updatedTask = task.copyWith(
                            status: newStatus,
                            completedAt: newStatus == TaskStatus.completed
                                ? DateTime.now()
                                : null,
                          );
                          await _controller.updateTask(updatedTask);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Project - Editable
                  AsyncStreamBuilder<List<Project>>(
                    state: _projectController,
                    builder: (context, projects) {
                      final activeProjects = projects
                          .where(
                            (p) =>
                                p.status == ProjectStatus.active &&
                                !p.isArchived,
                          )
                          .toList();
                      final currentProject = task.projectId != null
                          ? projects.firstWhere(
                              (p) => p.id == task.projectId,
                              orElse: () => projects.first,
                            )
                          : null;

                      return _buildEditableDetailSection(
                        'Project',
                        Icons.folder,
                        DropdownButton<String?>(
                          value: task.projectId,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.remove_circle_outline,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'No Project',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...activeProjects.map((project) {
                              final projectColor = project.color != null
                                  ? Color(int.parse(
                                      project.color!.replaceFirst('#', '0xff')))
                                  : Colors.blue[700]!;

                              return DropdownMenuItem<String?>(
                                value: project.id,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.folder,
                                      color: projectColor,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        project.name,
                                        style: TextStyle(
                                          color: projectColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                          onChanged: (newProjectId) async {
                            final updatedTask = task.copyWith(
                              projectId: newProjectId,
                            );
                            await _controller.updateTask(updatedTask);
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Due Date - Editable
                  _buildEditableDetailSection(
                    'Due Date',
                    Icons.calendar_today,
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: task.dueDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(
                              task.dueDate ?? DateTime.now(),
                            ),
                          );
                          if (time != null) {
                            final newDueDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                            final updatedTask = task.copyWith(
                              dueDate: newDueDate,
                            );
                            await _controller.updateTask(updatedTask);
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.dueDate != null
                                    ? DateFormat(
                                        'EEEE, MMMM d, y - h:mm a',
                                      ).format(task.dueDate!)
                                    : 'No due date set - Click to add',
                                style: TextStyle(
                                  color: task.dueDate != null && isOverdue
                                      ? Colors.red
                                      : task.dueDate == null
                                      ? Colors.grey[500]
                                      : null,
                                  fontWeight: task.dueDate != null && isOverdue
                                      ? FontWeight.w600
                                      : null,
                                ),
                              ),
                            ),
                            const Icon(Icons.edit, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  _buildDetailSection(
                    'Description',
                    Icons.subject,
                    Text(
                      task.description ?? 'No description',
                      style: TextStyle(
                        color: task.description == null
                            ? Colors.grey[500]
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Created Date
                  _buildDetailSection(
                    'Created',
                    Icons.add_circle_outline,
                    Text(
                      task.createdAt != null
                          ? DateFormat(
                              'MMMM d, y - h:mm a',
                            ).format(task.createdAt!)
                          : 'Unknown',
                      style: TextStyle(
                        color: task.createdAt == null ? Colors.grey[500] : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Completed Date
                  _buildDetailSection(
                    'Completed',
                    Icons.check_circle,
                    Text(
                      task.completedAt != null
                          ? DateFormat(
                              'MMMM d, y - h:mm a',
                            ).format(task.completedAt!)
                          : 'Not completed',
                      style: TextStyle(
                        color: task.completedAt == null
                            ? Colors.grey[500]
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tags - Editable
                  _buildEditableDetailSection(
                    'Tags',
                    Icons.label,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (task.tags.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: task.tags
                                .map(
                                  (tag) => Chip(
                                    label: Text(
                                      tag,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: Colors.blue.withOpacity(
                                      0.1,
                                    ),
                                    deleteIcon: const Icon(
                                      Icons.close,
                                      size: 16,
                                    ),
                                    onDeleted: () => _removeTag(task, tag),
                                  ),
                                )
                                .toList(),
                          ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => _showAddTagDialog(task),
                          icon: const Icon(Icons.add, size: 16),
                          label: Text(
                            task.tags.isEmpty ? 'Add Tag' : 'Add Another Tag',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Subtasks - Always shown
                  Text(
                    'Subtasks (${subtasks.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (subtasks.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'No subtasks yet',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ),
                    )
                  else
                    ...subtasks.map(
                      (subtask) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Checkbox(
                            value: subtask.isCompleted,
                            onChanged: (value) async {
                              if (value != null) {
                                final updated = subtask.copyWith(
                                  status: value
                                      ? TaskStatus.completed
                                      : TaskStatus.todo,
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
                ],
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Create Subtask'),
                      onPressed: () {
                        if (widget.isDrawerMode) {
                          Navigator.pop(context);
                        }
                        _showCreateSubtaskDialog(task);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (widget.isDrawerMode) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.open_in_full),
                        label: const Text('View Full Page'),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskDetailsPage(task: task),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );

        // Return either with AppBar (full page mode) or without (drawer mode)
        if (widget.isDrawerMode) {
          return content;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Task Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showCreateSubtaskDialog(task),
                tooltip: 'Create Subtask',
              ),
            ],
          ),
          body: content,
        );
      },
    );
  }
}
