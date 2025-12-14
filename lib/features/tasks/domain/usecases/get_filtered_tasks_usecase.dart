/// Get filtered tasks use case
library;

import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// Use case for getting tasks with filters applied
///
/// Business Rules:
/// - Results are sorted by priority (urgent > high > medium > low)
/// - Within same priority, sort by due date
/// - Tasks without due date appear last
class GetFilteredTasksUseCase {
  final TaskRepository _repository;

  GetFilteredTasksUseCase(this._repository);

  /// Get tasks filtered by status
  Future<List<Task>> byStatus(TaskStatus status) async {
    final tasks = await _repository.getTasksByStatus(status);
    return _sortTasks(tasks);
  }

  /// Get tasks filtered by project
  Future<List<Task>> byProject(String projectId) async {
    final tasks = await _repository.getTasksByProject(projectId);
    return _sortTasks(tasks);
  }

  /// Get tasks filtered by priority
  Future<List<Task>> byPriority(TaskPriority priority) async {
    final allTasks = await _repository.getTasks();
    final filtered = allTasks.where((task) => task.priority == priority).toList();
    return _sortTasks(filtered);
  }

  /// Get overdue tasks (past due date and not completed)
  Future<List<Task>> overdue() async {
    final allTasks = await _repository.getTasks();
    final overdueTasks = allTasks.where((task) => task.isOverdue).toList();
    return _sortTasks(overdueTasks);
  }

  /// Get tasks due today
  Future<List<Task>> dueToday() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final allTasks = await _repository.getTasks();
    final dueTodayTasks = allTasks.where((task) {
      if (task.dueDate == null || task.isCompleted) return false;
      return task.dueDate!.isAfter(today) && task.dueDate!.isBefore(tomorrow);
    }).toList();

    return _sortTasks(dueTodayTasks);
  }

  /// Get tasks due this week
  Future<List<Task>> dueThisWeek() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextWeek = today.add(const Duration(days: 7));

    final allTasks = await _repository.getTasks();
    final dueThisWeekTasks = allTasks.where((task) {
      if (task.dueDate == null || task.isCompleted) return false;
      return task.dueDate!.isAfter(today) && task.dueDate!.isBefore(nextWeek);
    }).toList();

    return _sortTasks(dueThisWeekTasks);
  }

  /// Search tasks by query
  Future<List<Task>> search(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final results = await _repository.searchTasks(query);
    return _sortTasks(results);
  }

  /// Business rule: Sort tasks by priority, then due date
  List<Task> _sortTasks(List<Task> tasks) {
    final sorted = List<Task>.from(tasks);

    sorted.sort((a, b) {
      // First: Sort by priority (urgent > high > medium > low)
      final priorityOrder = {
        TaskPriority.urgent: 0,
        TaskPriority.high: 1,
        TaskPriority.medium: 2,
        TaskPriority.low: 3,
      };

      final priorityComparison = priorityOrder[a.priority]!
          .compareTo(priorityOrder[b.priority]!);

      if (priorityComparison != 0) {
        return priorityComparison;
      }

      // Second: Sort by due date (earlier first)
      if (a.dueDate == null && b.dueDate == null) {
        // Both null - sort by creation date (newer first)
        return b.createdAt.compareTo(a.createdAt);
      }

      if (a.dueDate == null) return 1; // a goes after b
      if (b.dueDate == null) return -1; // a goes before b

      return a.dueDate!.compareTo(b.dueDate!);
    });

    return sorted;
  }
}
