/// REFACTORED TaskListScreen using custom StreamState
/// This is an example - compare with task_list_screen.dart
library;

import 'package:flutter/material.dart';
import '../../../../core/state/stream_builder_widget.dart';
import '../../../../core/ui/scoped_screen.dart';
import '../../../../core/routing/app_router.dart';
import '../../domain/entities/task.dart';
import '../state/task_list_controller.dart';

/// Task list screen using StreamState - Clean, reactive, no setState!
class TaskListScreenRefactored extends ScopedScreen {
  const TaskListScreenRefactored({super.key});

  @override
  String? get scopeName => 'TaskListRefactored';

  @override
  State<TaskListScreenRefactored> createState() =>
      _TaskListScreenRefactoredState();
}

class _TaskListScreenRefactoredState
    extends ScopedScreenState<TaskListScreenRefactored> {
  late TaskListController _controller;

  @override
  void registerServices() {
    // Register controller in scoped DI
    scope.registerFactory<TaskListController>(
      () => createTaskListController(scope),
    );
  }

  @override
  void onReady() {
    _controller = getService<TaskListController>();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          PopupMenuButton<TaskStatus?>(
            icon: const Icon(Icons.filter_list),
            onSelected: _controller.filterByStatus,
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All')),
              ...TaskStatus.values.map(
                (status) => PopupMenuItem(
                  value: status,
                  child: Text(status.displayName),
                ),
              ),
            ],
          ),
        ],
      ),
      body: AsyncStreamBuilder<List<Task>>(
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
                  onToggleComplete: () =>
                      _controller.toggleTaskCompletion(task),
                  onDelete: () => _controller.deleteTask(task.id),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTask,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TaskListItem extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;

  const _TaskListItem({
    required this.task,
    required this.onTap,
    required this.onToggleComplete,
    required this.onDelete,
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
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => onToggleComplete(),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
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
              ),
            const SizedBox(height: 4),
            Row(
              children: [
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
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }
}
