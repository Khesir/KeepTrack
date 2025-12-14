import 'package:flutter/material.dart';
import '../../../../core/ui/scoped_screen.dart';
import '../../../../core/routing/app_router.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';

/// Task list screen - Displays all tasks
class TaskListScreen extends ScopedScreen {
  const TaskListScreen({super.key});

  @override
  String? get scopeName => 'TaskList';

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ScopedScreenState<TaskListScreen> {
  late TaskRepository _taskRepository;
  List<Task> _tasks = [];
  bool _isLoading = false;
  TaskStatus? _filterStatus;

  @override
  void registerServices() {
    // Screen uses global task repository
  }

  @override
  void onReady() {
    _taskRepository = getService<TaskRepository>();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);

    try {
      final tasks = _filterStatus != null
          ? await _taskRepository.getTasksByStatus(_filterStatus!)
          : await _taskRepository.getTasks();

      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tasks: $e')),
        );
      }
    }
  }

  void _filterByStatus(TaskStatus? status) {
    setState(() => _filterStatus = status);
    _loadTasks();
  }

  void _createTask() {
    context.goToTaskCreate().then((_) => _loadTasks());
  }

  void _openTask(Task task) {
    context.goToTaskDetail(task).then((_) => _loadTasks());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          PopupMenuButton<TaskStatus?>(
            icon: const Icon(Icons.filter_list),
            onSelected: _filterByStatus,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Text('All'),
              ),
              ...TaskStatus.values.map((status) => PopupMenuItem(
                    value: status,
                    child: Text(status.displayName),
                  )),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.task_alt, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No tasks yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTasks,
                  child: ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return _TaskListItem(
                        task: task,
                        onTap: () => _openTask(task),
                        onToggleComplete: () => _toggleComplete(task),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTask,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _toggleComplete(Task task) async {
    try {
      final updated = task.copyWith(
        status: task.isCompleted ? TaskStatus.todo : TaskStatus.completed,
        completedAt: task.isCompleted ? null : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _taskRepository.updateTask(updated);
      _loadTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating task: $e')),
        );
      }
    }
  }
}

class _TaskListItem extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;

  const _TaskListItem({
    required this.task,
    required this.onTap,
    required this.onToggleComplete,
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
                    style: TextStyle(
                      fontSize: 12,
                      color: _getPriorityColor(),
                    ),
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
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }
}
