import 'package:flutter/material.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/features/tasks/modules/tasks/domain/entities/task.dart';
import 'package:keep_track/features/tasks/modules/projects/domain/entities/project.dart';
import 'package:keep_track/features/tasks/modules/pomodoro/domain/entities/pomodoro_session.dart';
import 'package:keep_track/features/tasks/presentation/state/task_controller.dart';
import 'package:keep_track/features/tasks/presentation/state/project_controller.dart';
import 'package:keep_track/features/tasks/presentation/state/pomodoro_session_controller.dart';
import 'package:keep_track/features/profile/domain/contribution_data.dart';
import 'package:keep_track/features/profile/domain/contribution_calculator.dart';
import 'package:keep_track/features/profile/presentation/widgets/contribution_heatmap.dart';
import 'package:keep_track/features/profile/presentation/widgets/contribution_activity_feed.dart';

/// GitHub-style contribution card with heatmap and activity feed
class ContributionCard extends StatefulWidget {
  const ContributionCard({super.key});

  @override
  State<ContributionCard> createState() => _ContributionCardState();
}

class _ContributionCardState extends State<ContributionCard> {
  late final TaskController _taskController;
  late final ProjectController _projectController;
  late final PomodoroSessionController _pomodoroController;

  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _taskController = locator.get<TaskController>();
    _projectController = locator.get<ProjectController>();
    _pomodoroController = locator.get<PomodoroSessionController>();

    _taskController.loadTasks();
    _projectController.loadProjects();
  }

  @override
  Widget build(BuildContext context) {
    return AsyncStreamBuilder<List<Task>>(
      state: _taskController,
      loadingBuilder: (_) => _buildLoadingCard(),
      errorBuilder: (context, message) => _buildErrorCard(message),
      builder: (context, tasks) {
        return AsyncStreamBuilder<List<Project>>(
          state: _projectController,
          loadingBuilder: (_) => _buildLoadingCard(),
          errorBuilder: (context, message) => _buildStatsCard(tasks, [], []),
          builder: (context, projects) {
            return FutureBuilder<List<PomodoroSession>>(
              future: _pomodoroController.getSessions(),
              builder: (context, snapshot) {
                final sessions = snapshot.data ?? [];
                return _buildStatsCard(tasks, projects, sessions);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      elevation: 0,
      child: Container(
        height: 300,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text('Error: $message'),
      ),
    );
  }

  Widget _buildStatsCard(
    List<Task> tasks,
    List<Project> projects,
    List<PomodoroSession> sessions,
  ) {
    // Calculate yearly contributions
    final summary = ContributionCalculator.getYearlyContributions(
      year: _selectedYear,
      tasks: tasks,
      projects: projects,
      sessions: sessions,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Contribution heatmap card with year selector
        IntrinsicWidth(
          child: Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header row with title and year selector
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_view_month,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Contributions',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 16),
                      // Year navigation
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 20),
                        onPressed: () {
                          setState(() {
                            _selectedYear--;
                          });
                        },
                        tooltip: 'Previous year',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          '$_selectedYear',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 20),
                        onPressed: () {
                          setState(() {
                            _selectedYear++;
                          });
                        },
                        tooltip: 'Next year',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Heatmap
                  ContributionHeatmap(summary: summary),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Activity feed
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ContributionActivityFeed(summary: summary, itemsPerPage: 10),
          ),
        ),
      ],
    );
  }
}
