/// REFACTORED TaskListScreen using custom StreamState
/// This is an example - compare with task_list_screen.dart
library;

import 'package:flutter/material.dart';
import 'package:persona_codex/core/ui/app_layout_controller.dart';
import 'package:persona_codex/features/tasks/domain/repositories/task_repository.dart';
import 'package:persona_codex/features/tasks/domain/usecases/usecases.dart';
import '../../../../core/state/stream_builder_widget.dart';
import '../../../../core/ui/scoped_screen.dart';
import '../../../../core/routing/app_router.dart';
import '../../domain/entities/task.dart';
import '../state/task_list_controller.dart';

/// Task list screen using StreamState - Clean, reactive, no setState!
class TaskListScreen extends ScopedScreen {
  const TaskListScreen({super.key});

  @override
  String? get scopeName => 'TaskListRefactored';

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ScopedScreenState<TaskListScreen>
    with AppLayoutControlled {
  late final TaskListController _controller;

  @override
  void registerServices() {
    final taskRepo = scope.get<TaskRepository>();
    scope.registerFactory<TaskListController>(
      () => TaskListController(
        getTasksUseCase: GetTasksUseCase(taskRepo),
        getFilteredTasksUseCase: GetFilteredTasksUseCase(taskRepo),
        updateTaskStatusUseCase: UpdateTaskStatusUseCase(taskRepo),
        deleteTaskUseCase: DeleteTaskUseCase(taskRepo),
        archiveTaskUseCase: ArchiveTaskUseCase(taskRepo),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _controller = scope.get<TaskListController>();
  }

  @override
  void onReady() async {
    configureLayout(
      title: 'Tasks',
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.filter_list),
          onSelected: _handleFilterSelection,
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'all', child: Text('All')),
            const PopupMenuItem(
              value: 'divider1',
              enabled: false,
              child: Divider(),
            ),
            ...TaskStatus.values.map(
              (status) => PopupMenuItem(
                value: 'status_${status.name}',
                child: Text(status.displayName),
              ),
            ),
            const PopupMenuItem(
              value: 'divider2',
              enabled: false,
              child: Divider(),
            ),
            const PopupMenuItem(value: 'archived', child: Text('📦 Archived')),
            const PopupMenuItem(
              value: 'toggle_show_archived',
              child: Text('👁️ Toggle Show Archived'),
            ),
          ],
        ),
      ],
      fab: FloatingActionButton(
        onPressed: _createTask,
        child: const Icon(Icons.add),
      ),
      showBottomNav: true,
    );
  }

  void _handleFilterSelection(String value) {
    if (value == 'all') {
      _controller.filterByStatus(null);
    } else if (value.startsWith('status_')) {
      final statusName = value.replaceFirst('status_', '');
      final status = TaskStatus.values.firstWhere((e) => e.name == statusName);
      _controller.filterByStatus(status);
    } else if (value == 'archived') {
      _controller.showArchivedTasks();
    } else if (value == 'toggle_show_archived') {
      _controller.toggleShowArchived();
    }
  }

  @override
  void dispose() {
    _controller.dispose(); // Clean up streams
    super.dispose();
  }

  void _createTask() {
    context.goToTaskCreate().then((_) => _controller.loadTasks());
  }

  void _openTask(Task task) {
    context.goToTaskDetail(task).then((_) => _controller.loadTasks());
  }

  @override
  Widget build(BuildContext context) {
    return AsyncStreamBuilder<List<Task>>(
      state: _controller,
      builder: (context, tasks) {
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.task_alt, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No tasks yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _controller.loadTasks,
          child: ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _TaskListItem(
                task: task,
                onTap: () => _openTask(task),
                onToggleComplete: () => _controller.toggleTaskCompletion(task),
                onDelete: task.id != null
                    ? () => _controller.deleteTask(task.id!)
                    : () {}, // Should never happen, but handle gracefully
                onArchive: task.id != null
                    ? () => _controller.toggleArchive(task)
                    : () {},
              );
            },
          ),
        );
      },
      // Custom error UI
      errorBuilder: (context, message) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error loading tasks',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _controller.loadTasks,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskListItem extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;
  final VoidCallback onArchive;

  const _TaskListItem({
    required this.task,
    required this.onTap,
    required this.onToggleComplete,
    required this.onDelete,
    required this.onArchive,
  });

  Color _getPriorityColor() {
    switch (task.priority) {
      case TaskPriority.urgent:
        return Colors.red;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.medium:
        return Colors.blue;
      case TaskPriority.low:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: task.archived ? Colors.grey[100] : null,
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: task.archived ? null : (_) => onToggleComplete(),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.archived ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null && task.description!.isNotEmpty)
              Text(
                task.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: task.archived ? Colors.grey : null),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (task.archived) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.archive, size: 12, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          'Archived',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    task.priority.displayName,
                    style: TextStyle(fontSize: 12, color: _getPriorityColor()),
                  ),
                ),
                if (task.dueDate != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: task.isOverdue ? Colors.red : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${task.dueDate!.month}/${task.dueDate!.day}',
                    style: TextStyle(
                      fontSize: 12,
                      color: task.isOverdue ? Colors.red : Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                task.archived ? Icons.unarchive : Icons.archive,
                size: 20,
                color: task.archived ? Colors.green : Colors.grey,
              ),
              onPressed: onArchive,
              tooltip: task.archived ? 'Unarchive' : 'Archive',
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
