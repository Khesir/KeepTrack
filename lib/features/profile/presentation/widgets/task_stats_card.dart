import 'package:flutter/material.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/features/tasks/modules/tasks/domain/entities/task.dart';
import 'package:keep_track/features/tasks/modules/projects/domain/entities/project.dart';
import 'package:keep_track/features/tasks/presentation/state/task_controller.dart';
import 'package:keep_track/features/tasks/presentation/state/project_controller.dart';

class TaskStatsCard extends StatefulWidget {
  const TaskStatsCard({super.key});

  @override
  State<TaskStatsCard> createState() => _TaskStatsCardState();
}

class _TaskStatsCardState extends State<TaskStatsCard> {
  late final TaskController _taskController;
  late final ProjectController _projectController;

  @override
  void initState() {
    super.initState();
    _taskController = locator.get<TaskController>();
    _projectController = locator.get<ProjectController>();
    _taskController.loadTasks();
    _projectController.loadProjects();
  }

  @override
  Widget build(BuildContext context) {
    return AsyncStreamBuilder<List<Task>>(
      state: _taskController,
      loadingBuilder: (_) => Card(
        elevation: 0,
        child: Container(
          height: 300,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        ),
      ),
      errorBuilder: (context, message) => Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Error loading tasks: $message'),
        ),
      ),
      builder: (context, tasks) {
        return AsyncStreamBuilder<List<Project>>(
          state: _projectController,
          loadingBuilder: (_) => Card(
            elevation: 0,
            child: Container(
              height: 300,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),
          ),
          errorBuilder: (context, message) => _buildStatsCard(tasks, []),
          builder: (context, projects) {
            return _buildStatsCard(tasks, projects);
          },
        );
      },
    );
  }

  Widget _buildStatsCard(List<Task> tasks, List<Project> projects) {
    // Calculate task statistics
    final totalTasks = tasks.where((t) => !t.isArchived).length;
    final completedTasks = tasks.where((t) => t.isCompleted && !t.isArchived).length;
    final inProgressTasks = tasks.where((t) => t.status == TaskStatus.inProgress && !t.isArchived).length;
    final todoTasks = tasks.where((t) => t.status == TaskStatus.todo && !t.isArchived).length;
    final overdueTasks = tasks.where((t) {
      if (t.dueDate == null || t.isArchived || t.isCompleted) return false;
      return t.dueDate!.isBefore(DateTime.now());
    }).length;

    // Calculate project statistics
    final activeProjects = projects.where((p) => p.status == ProjectStatus.active && !p.isArchived).length;
    final totalProjects = projects.where((p) => !p.isArchived).length;

    // Calculate completion rate
    final completionRate = totalTasks > 0 ? (completedTasks / totalTasks * 100) : 0.0;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Completion rate display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Completion Rate',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${completionRate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completedTasks of $totalTasks tasks',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.task_alt,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Task breakdown
            Text(
              'Task Breakdown',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatRow('To Do', todoTasks, Icons.circle_outlined, Colors.grey),
            _buildStatRow('In Progress', inProgressTasks, Icons.play_circle_outline, Colors.blue),
            _buildStatRow('Completed', completedTasks, Icons.check_circle, Colors.green),
            _buildStatRow('Overdue', overdueTasks, Icons.warning_amber_rounded, Colors.red),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // Project statistics
            Text(
              'Project Overview',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatRow('Active Projects', activeProjects, Icons.folder_open, Colors.purple),
            _buildStatRow('Total Projects', totalProjects, Icons.folder, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, int count, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
