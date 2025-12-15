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

  /// Get tasks filtered by status (excludes archived by default)
  Future<List<Task>> byStatus(TaskStatus status, {bool includeArchived = false}) async {
    final tasks = await _repository.getTasksByStatus(status);
    return _sortTasks(tasks, includeArchived: includeArchived);
  }

  /// Get tasks filtered by project (excludes archived by default)
  Future<List<Task>> byProject(String projectId, {bool includeArchived = false}) async {
    final tasks = await _repository.getTasksByProject(projectId);
    return _sortTasks(tasks, includeArchived: includeArchived);
  }

  /// Get tasks filtered by priority (excludes archived by default)
  Future<List<Task>> byPriority(TaskPriority priority, {bool includeArchived = false}) async {
    final allTasks = await _repository.getTasks();
    final filtered = allTasks.where((task) => task.priority == priority).toList();
    return _sortTasks(filtered, includeArchived: includeArchived);
  }

  /// Get overdue tasks (past due date and not completed, excludes archived)
  Future<List<Task>> overdue() async {
    final allTasks = await _repository.getTasks();
    final overdueTasks = allTasks.where((task) => task.isOverdue && !task.archived).toList();
    return _sortTasks(overdueTasks);
  }

  /// Get tasks due today (excludes archived)
  Future<List<Task>> dueToday() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final allTasks = await _repository.getTasks();
    final dueTodayTasks = allTasks.where((task) {
      if (task.dueDate == null || task.isCompleted || task.archived) return false;
      return task.dueDate!.isAfter(today) && task.dueDate!.isBefore(tomorrow);
    }).toList();

    return _sortTasks(dueTodayTasks);
  }

  /// Get tasks due this week (excludes archived)
  Future<List<Task>> dueThisWeek() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextWeek = today.add(const Duration(days: 7));

    final allTasks = await _repository.getTasks();
    final dueThisWeekTasks = allTasks.where((task) {
      if (task.dueDate == null || task.isCompleted || task.archived) return false;
      return task.dueDate!.isAfter(today) && task.dueDate!.isBefore(nextWeek);
    }).toList();

    return _sortTasks(dueThisWeekTasks);
  }

  /// Search tasks by query (excludes archived by default)
  Future<List<Task>> search(String query, {bool includeArchived = false}) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final results = await _repository.searchTasks(query);
    return _sortTasks(results, includeArchived: includeArchived);
  }

  /// Business rule: Sort tasks by priority, then due date
  /// Optionally filter out archived tasks
  List<Task> _sortTasks(List<Task> tasks, {bool includeArchived = false}) {
    // Filter out archived tasks by default
    final filtered = includeArchived
        ? tasks
        : tasks.where((task) => !task.archived).toList();

    final sorted = List<Task>.from(filtered);

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
        // Handle nullable createdAt
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      }

      if (a.dueDate == null) return 1; // a goes after b
      if (b.dueDate == null) return -1; // a goes before b

      return a.dueDate!.compareTo(b.dueDate!);
    });

    return sorted;
  }
}
