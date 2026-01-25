import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/routing/app_router.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/ui/app_layout_controller.dart';
import 'package:keep_track/core/ui/ui.dart';
import 'package:keep_track/features/tasks/modules/projects/domain/entities/project.dart';
import 'package:keep_track/features/tasks/modules/tasks/domain/entities/task.dart';
import 'package:keep_track/features/tasks/modules/pomodoro/domain/entities/pomodoro_session.dart';
import 'package:keep_track/features/tasks/presentation/state/project_controller.dart';
import 'package:keep_track/features/tasks/presentation/state/task_controller.dart';
import 'package:keep_track/features/tasks/presentation/state/pomodoro_session_controller.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/responsive/desktop_aware_screen.dart';

enum ProjectTaskFilter { all, todo, inProgress, completed, cancelled }

/// Project Details Screen - Shows project info, metadata, and tasks
class ProjectDetailsScreen extends ScopedScreen {
  final Project project;

  const ProjectDetailsScreen({super.key, required this.project});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends ScopedScreenState<ProjectDetailsScreen>
    with AppLayoutControlled {
  late final TaskController _taskController;
  late final ProjectController _projectController;
  late final PomodoroSessionController _pomodoroController;

  ProjectTaskFilter _taskFilter = ProjectTaskFilter.all;
  final Set<String> _expandedTaskIds = {};

  @override
  void registerServices() {
    _taskController = locator.get<TaskController>();
    _projectController = locator.get<ProjectController>();
    _pomodoroController = locator.get<PomodoroSessionController>();
  }

  @override
  void onReady() {
    configureLayout(title: widget.project.name, showBottomNav: false);
    _taskController.loadTasks();
    _projectController.loadProjects();
  }

  void _toggleTaskCompletion(Task task, bool? value) async {
    if (value == null) return;

    final updatedTask = task.copyWith(
      status: value ? TaskStatus.completed : TaskStatus.todo,
      completedAt: value ? DateTime.now() : null,
    );

    await _taskController.updateTask(updatedTask);
    _taskController.loadTasks();
  }

  // Get all tasks that belong to this project, including all subtasks recursively
  List<Task> _getAllProjectTasks(List<Task> allTasks) {
    // Get direct project tasks (tasks with projectId set)
    final directProjectTasks = allTasks
        .where(
          (task) => task.projectId == widget.project.id && !task.isArchived,
        )
        .toList();

    // Recursively collect all subtasks
    final Set<String> projectTaskIds = {};
    final List<Task> allProjectTasks = [];

    void collectTasksRecursively(Task task) {
      if (task.id != null && !projectTaskIds.contains(task.id)) {
        projectTaskIds.add(task.id!);
        allProjectTasks.add(task);

        // Find and add all subtasks
        final subtasks = allTasks
            .where((t) => t.parentTaskId == task.id)
            .toList();
        for (final subtask in subtasks) {
          collectTasksRecursively(subtask);
        }
      }
    }

    // Collect all tasks starting from direct project tasks
    for (final task in directProjectTasks) {
      collectTasksRecursively(task);
    }

    return allProjectTasks;
  }

  List<Task> _filterTasks(List<Task> tasks) {
    // Get all tasks for this project (including subtasks recursively)
    var filtered = _getAllProjectTasks(tasks);

    // Filter by status
    if (_taskFilter != ProjectTaskFilter.all) {
      filtered = filtered.where((task) {
        switch (_taskFilter) {
          case ProjectTaskFilter.todo:
            return task.status == TaskStatus.todo;
          case ProjectTaskFilter.inProgress:
            return task.status == TaskStatus.inProgress;
          case ProjectTaskFilter.completed:
            return task.status == TaskStatus.completed;
          case ProjectTaskFilter.cancelled:
            return task.status == TaskStatus.cancelled;
          case ProjectTaskFilter.all:
            return true;
        }
      }).toList();
    }

    // Sort by priority
    return _sortTasksByPriority(filtered);
  }

  List<Task> _sortTasksByPriority(List<Task> tasks) {
    final sorted = List<Task>.from(tasks);
    sorted.sort((a, b) {
      final priorityOrder = {
        TaskPriority.urgent: 0,
        TaskPriority.high: 1,
        TaskPriority.medium: 2,
        TaskPriority.low: 3,
      };

      final priorityCompare = priorityOrder[a.priority]!.compareTo(
        priorityOrder[b.priority]!,
      );
      if (priorityCompare != 0) return priorityCompare;

      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      } else if (a.dueDate != null) {
        return -1;
      } else if (b.dueDate != null) {
        return 1;
      }
      return 0;
    });
    return sorted;
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
        return Colors.green[700]!;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Colors.grey[700]!;
      case TaskStatus.inProgress:
        return Colors.blue[700]!;
      case TaskStatus.completed:
        return Colors.green[700]!;
      case TaskStatus.cancelled:
        return Colors.red[700]!;
    }
  }

  /// Get all completed pomodoro sessions for this project
  List<PomodoroSession> _getProjectSessions(List<PomodoroSession> allSessions) {
    return allSessions
        .where(
          (session) =>
              session.projectId == widget.project.id &&
              session.status == PomodoroSessionStatus.completed &&
              session.type == PomodoroSessionType.pomodoro,
        )
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt)); // Most recent first
  }

  /// Calculate total minutes invested in this project from completed pomodoro sessions
  int _calculateTotalMinutes(List<PomodoroSession> sessions) {
    final projectSessions = _getProjectSessions(sessions);
    if (projectSessions.isEmpty) return 0;

    final totalSeconds = projectSessions.fold<int>(0, (sum, session) {
      // Use absolute value to handle sessions where startedAt was adjusted during pause/resume
      final elapsed = session.elapsedSeconds.abs();
      return sum + elapsed;
    });

    return (totalSeconds / 60).round();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopAwareScreen(
      builder: (context, isDesktop) {
        return AsyncStreamBuilder<List<Project>>(
          state: _projectController,
          builder: (context, projects) {
            final currentProject = projects.firstWhere(
              (p) => p.id == widget.project.id,
              orElse: () => widget.project,
            );

            return Scaffold(
              backgroundColor: isDesktop ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF09090B) : AppColors.backgroundSecondary) : null,
              appBar: AppBar(
                title: Text(currentProject.name),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit Project',
                    onPressed: () => _showEditProjectDialog(currentProject),
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? AppSpacing.xl : 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 1400 : double.infinity,
                    ),
                    child: isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Column - Project Info
                              Expanded(
                                flex: 1,
                                child: FutureBuilder<List<PomodoroSession>>(
                                  future: _pomodoroController.getSessions(),
                                  builder: (context, snapshot) {
                                    final sessions = snapshot.data ?? [];
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildProjectHeader(
                                          currentProject,
                                          isDesktop,
                                        ),
                                        const SizedBox(height: AppSpacing.sm),

                                        Row(
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.pushNamed(
                                                  context,
                                                  AppRoutes.taskCreate,
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.add,
                                                size: 20,
                                              ),
                                              label: const Text('Add Task'),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: AppSpacing.xl),
                                        _buildMetadataSection(
                                          currentProject,
                                          sessions,
                                        ),
                                        const SizedBox(height: AppSpacing.xl),
                                        _buildSessionHistorySection(sessions),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xl),
                              // Right Column - Tasks
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildTaskFilters(),
                                    const SizedBox(height: 16),
                                    _buildTasksList(),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : FutureBuilder<List<PomodoroSession>>(
                            future: _pomodoroController.getSessions(),
                            builder: (context, snapshot) {
                              final sessions = snapshot.data ?? [];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildProjectHeader(
                                    currentProject,
                                    isDesktop,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildMetadataSection(
                                    currentProject,
                                    sessions,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildSessionHistorySection(sessions),
                                  const SizedBox(height: 24),
                                  _buildTaskFilters(),
                                  const SizedBox(height: 16),
                                  _buildTasksList(),
                                  // Extra padding for FAB on mobile
                                  const SizedBox(height: 80),
                                ],
                              );
                            },
                          ),
                  ),
                ),
              ),
              floatingActionButton: isDesktop
                  ? null
                  : FloatingActionButton.extended(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.taskCreate);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Task'),
                    ),
            );
          },
          loadingBuilder: (_) =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          errorBuilder: (context, message) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading project: $message'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProjectHeader(Project project, bool isDesktop) {
    final statusColor = project.status == ProjectStatus.active
        ? Colors.green
        : project.status == ProjectStatus.postponed
        ? Colors.orange
        : Colors.grey;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            project.color != null
                ? Color(
                    int.parse(project.color!.replaceFirst('#', '0xff')),
                  ).withOpacity(0.7)
                : Colors.blue[700]!,
            project.color != null
                ? Color(
                    int.parse(project.color!.replaceFirst('#', '0xff')),
                  ).withOpacity(0.5)
                : Colors.blue[500]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  project.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isDesktop ? 28 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white),
                ),
                child: Text(
                  project.status.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (project.description != null) ...[
            const SizedBox(height: 8),
            Text(
              project.description!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetadataSection(
    Project project,
    List<PomodoroSession> sessions,
  ) {
    final hasMetadata = project.metadata.isNotEmpty;
    final projectSessions = _getProjectSessions(sessions);
    final totalMinutes = _calculateTotalMinutes(sessions);
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Project Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () {
                  _showMetadataEditor(project);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Time Invested
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time Invested',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        projectSessions.isEmpty
                            ? 'No sessions yet'
                            : hours > 0
                            ? '$hours hr $minutes min'
                            : '$minutes min',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (projectSessions.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${projectSessions.length} session${projectSessions.length > 1 ? 's' : ''} completed',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (hasMetadata) const SizedBox(height: 8),
          if (hasMetadata)
            ...project.metadata.entries.map((entry) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getMetadataIcon(entry.key),
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entry.value,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isUrl(entry.value))
                      IconButton(
                        icon: const Icon(Icons.open_in_new, size: 18),
                        onPressed: () => _launchUrl(entry.value),
                      ),
                  ],
                ),
              );
            }).toList()
          else
            Text(
              'No additional information. Tap edit to add project links, ERD, documentation, etc.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSessionHistorySection(List<PomodoroSession> allSessions) {
    final projectSessions = _getProjectSessions(allSessions);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Session History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${projectSessions.length} sessions',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (projectSessions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(
                    Icons.timer_off,
                    size: 48,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No pomodoro sessions yet',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: projectSessions.length > 10
                  ? 10
                  : projectSessions.length,
              itemBuilder: (context, index) {
                final session = projectSessions[index];
                return _buildSessionItem(session);
              },
            ),
          if (projectSessions.length > 10)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  '+ ${projectSessions.length - 10} more sessions',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSessionItem(PomodoroSession session) {
    // Use absolute value to handle sessions where startedAt was adjusted during pause/resume
    final duration = session.elapsedSeconds.abs() ~/ 60;
    final sessionDate = session.startedAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle,
              size: 20,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$duration min',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, h:mm a').format(sessionDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                if (session.tasksCleared.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.task_alt,
                        size: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${session.tasksCleared.length} task${session.tasksCleared.length > 1 ? 's' : ''} cleared',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tasks',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', ProjectTaskFilter.all),
                const SizedBox(width: 8),
                _buildFilterChip('To-do', ProjectTaskFilter.todo),
                const SizedBox(width: 8),
                _buildFilterChip('In Progress', ProjectTaskFilter.inProgress),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', ProjectTaskFilter.completed),
                const SizedBox(width: 8),
                _buildFilterChip('Cancelled', ProjectTaskFilter.cancelled),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getMetadataIcon(String key) {
    final lowerKey = key.toLowerCase();
    if (lowerKey.contains('link') || lowerKey.contains('url')) {
      return Icons.link;
    } else if (lowerKey.contains('erd') || lowerKey.contains('diagram')) {
      return Icons.schema;
    } else if (lowerKey.contains('doc') || lowerKey.contains('documentation')) {
      return Icons.description;
    } else if (lowerKey.contains('repo') || lowerKey.contains('github')) {
      return Icons.code;
    } else {
      return Icons.info;
    }
  }

  bool _isUrl(String text) {
    return text.startsWith('http://') || text.startsWith('https://');
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditProjectDialog(Project project) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _ProjectEditorDialog(
        project: project,
        onSave: (updatedProject) async {
          await _projectController.updateProject(updatedProject);
          return true;
        },
      ),
    );

    if (result == true && mounted) {
      await _projectController.loadProjects();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project updated successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showMetadataEditor(Project project) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _MetadataEditorDialog(
        project: project,
        onSave: (updatedMetadata) async {
          final updatedProject = project.copyWith(metadata: updatedMetadata);
          await _projectController.updateProject(updatedProject);
          return true;
        },
      ),
    );

    if (result == true && mounted) {
      // Reload the project data - stream will update automatically
      await _projectController.loadProjects();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project information saved successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildFilterChip(String label, ProjectTaskFilter filter) {
    final isSelected = _taskFilter == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _taskFilter = filter;
        });
      },
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
    );
  }

  Widget _buildTasksList() {
    return AsyncStreamBuilder(
      state: _taskController,
      builder: (context, tasks) {
        // Get ALL tasks for this project including all subtasks recursively
        final allProjectTasks = _getAllProjectTasks(tasks);

        // Filter the main tasks by status
        final filteredTasks = _filterTasks(tasks);
        // Only show main tasks (not subtasks) at top level
        final mainTasks = filteredTasks.where((t) => !t.isSubtask).toList();

        if (mainTasks.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    Icons.task_alt,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tasks found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Pass allProjectTasks so subtasks can be found recursively
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: mainTasks.length,
          itemBuilder: (context, index) {
            final task = mainTasks[index];
            return _buildTaskItem(task, allProjectTasks);
          },
        );
      },
    );
  }

  Widget _buildTaskItem(Task task, List<Task> allTasks, {int depth = 0}) {
    final isExpanded = task.id != null && _expandedTaskIds.contains(task.id);
    final subtasks = allTasks.where((t) => t.parentTaskId == task.id).toList();
    final subtaskCount = subtasks.length;

    return Column(
      children: [
        // Task row with indentation based on depth
        Container(
          margin: EdgeInsets.only(bottom: 8, left: depth * 24.0),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surface.withOpacity(0.3 - (depth * 0.05)),
            borderRadius: BorderRadius.circular(8),
            border: depth > 0
                ? Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.2),
                  )
                : null,
          ),
          child: InkWell(
            onTap: subtaskCount > 0
                ? () {
                    setState(() {
                      if (task.id != null) {
                        if (isExpanded) {
                          _expandedTaskIds.remove(task.id);
                        } else {
                          _expandedTaskIds.add(task.id!);
                        }
                      }
                    });
                  }
                : null,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Priority indicator (smaller for deeper levels)
                  Container(
                    width: depth > 0 ? 3 : 4,
                    height: depth > 0 ? 40 : 50,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(task.priority),
                      borderRadius: BorderRadius.circular(depth > 0 ? 1.5 : 2),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Checkbox
                  SizedBox(
                    width: depth > 0 ? 24 : null,
                    height: depth > 0 ? 24 : null,
                    child: Checkbox(
                      value: task.isCompleted,
                      onChanged: (value) => _toggleTaskCompletion(task, value),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Task info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: depth > 0 ? 14 : 15,
                            fontWeight: depth > 0
                                ? FontWeight.w500
                                : FontWeight.w600,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (task.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description!,
                            style: TextStyle(
                              fontSize: depth > 0 ? 11 : 12,
                              color: Theme.of(context).colorScheme.onSurface
                                  .withOpacity(depth > 0 ? 0.5 : 0.6),
                            ),
                            maxLines: depth > 0 ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: depth > 0 ? 6 : 8,
                          runSpacing: depth > 0 ? 2 : 4,
                          children: [
                            if (depth == 0)
                              _buildTaskBadge(
                                task.priority.displayName,
                                _getPriorityColor(task.priority),
                                Icons.flag,
                              ),
                            _buildTaskBadge(
                              task.status.displayName,
                              _getStatusColor(task.status),
                              Icons.circle,
                            ),
                            _buildTaskBadge(
                              task.dueDate != null
                                  ? DateFormat(
                                      'MMM d, h:mm a',
                                    ).format(task.dueDate!)
                                  : 'No date',
                              task.dueDate != null
                                  ? Colors.grey[700]!
                                  : Colors.grey[400]!,
                              Icons.calendar_today,
                            ),
                            if (subtaskCount > 0)
                              _buildTaskBadge(
                                '$subtaskCount subtask${subtaskCount > 1 ? 's' : ''}',
                                Colors.blue[700]!,
                                Icons.list,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Expand icon (only show if there are subtasks)
                  if (subtaskCount > 0)
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Subtasks (shown when expanded) - RECURSIVE
        if (isExpanded && subtaskCount > 0)
          ...subtasks.map(
            (subtask) => _buildTaskItem(subtask, allTasks, depth: depth + 1),
          ),
      ],
    );
  }

  Widget _buildTaskBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Metadata Editor Dialog - Allows adding/editing/deleting project metadata
class _MetadataEditorDialog extends StatefulWidget {
  final Project project;
  final Future<bool> Function(Map<String, String>) onSave;

  const _MetadataEditorDialog({required this.project, required this.onSave});

  @override
  State<_MetadataEditorDialog> createState() => _MetadataEditorDialogState();
}

class _MetadataEditorDialogState extends State<_MetadataEditorDialog> {
  late Map<String, String> _metadata;
  final _formKey = GlobalKey<FormState>();
  String? _newKey;
  String? _newValue;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _metadata = Map<String, String>.from(widget.project.metadata);
  }

  void _addNewEntry() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (_newKey != null && _newValue != null) {
        setState(() {
          _metadata[_newKey!] = _newValue!;
          _newKey = null;
          _newValue = null;
        });
        _formKey.currentState!.reset();
      }
    }
  }

  void _deleteEntry(String key) {
    setState(() {
      _metadata.remove(key);
    });
  }

  void _editEntry(String oldKey, String newKey, String newValue) {
    setState(() {
      if (oldKey != newKey) {
        _metadata.remove(oldKey);
      }
      _metadata[newKey] = newValue;
    });
  }

  Future<void> _saveMetadata() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final success = await widget.onSave(_metadata);
      if (mounted) {
        Navigator.pop(context, success);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving metadata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Project Information',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Add dynamic information like links, documentation, ERD, etc.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),

            // Existing entries
            if (_metadata.isNotEmpty) ...[
              const Text(
                'Current Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _metadata.length,
                  itemBuilder: (context, index) {
                    final entry = _metadata.entries.elementAt(index);
                    return _buildMetadataEntry(entry.key, entry.value);
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Add new entry form
            const Text(
              'Add New Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText:
                          'Label (e.g., Project Link, ERD, Documentation)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a label';
                      }
                      if (_metadata.containsKey(value) && _newKey != value) {
                        return 'This label already exists';
                      }
                      return null;
                    },
                    onSaved: (value) => _newKey = value,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Value (e.g., https://..., Description)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.text_fields),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a value';
                      }
                      return null;
                    },
                    onSaved: (value) => _newValue = value,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _addNewEntry,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Entry'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveMetadata,
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataEntry(String key, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getMetadataIcon(key),
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          key,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showEditDialog(key, value),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20),
              onPressed: () => _deleteEntry(key),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(String oldKey, String oldValue) {
    final keyController = TextEditingController(text: oldKey);
    final valueController = TextEditingController(text: oldValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyController,
              decoration: const InputDecoration(
                labelText: 'Label',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valueController,
              decoration: const InputDecoration(
                labelText: 'Value',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _editEntry(oldKey, keyController.text, valueController.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  IconData _getMetadataIcon(String key) {
    final lowerKey = key.toLowerCase();
    if (lowerKey.contains('link') || lowerKey.contains('url')) {
      return Icons.link;
    } else if (lowerKey.contains('erd') || lowerKey.contains('diagram')) {
      return Icons.schema;
    } else if (lowerKey.contains('doc') || lowerKey.contains('documentation')) {
      return Icons.description;
    } else if (lowerKey.contains('repo') || lowerKey.contains('github')) {
      return Icons.code;
    } else {
      return Icons.info;
    }
  }
}

/// Project Editor Dialog - Allows editing project name, description, status, and color
class _ProjectEditorDialog extends StatefulWidget {
  final Project project;
  final Future<bool> Function(Project) onSave;

  const _ProjectEditorDialog({required this.project, required this.onSave});

  @override
  State<_ProjectEditorDialog> createState() => _ProjectEditorDialogState();
}

class _ProjectEditorDialogState extends State<_ProjectEditorDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late ProjectStatus _status;
  late Color _selectedColor;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _descriptionController = TextEditingController(
      text: widget.project.description ?? '',
    );
    _status = widget.project.status;
    _selectedColor = widget.project.color != null
        ? Color(int.parse(widget.project.color!.replaceFirst('#', '0xff')))
        : Colors.blue[700]!;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveProject() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project name cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final colorHex =
          '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}';
      final updatedProject = widget.project.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        status: _status,
        color: colorHex,
      );

      final success = await widget.onSave(updatedProject);
      if (mounted) {
        Navigator.pop(context, success);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving project: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a Color'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() {
                _selectedColor = color;
              });
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Project',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Project Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Project Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.folder),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            // Status
            DropdownButtonFormField<ProjectStatus>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag),
              ),
              items: ProjectStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Row(
                    children: [
                      Icon(
                        status == ProjectStatus.active
                            ? Icons.play_circle
                            : status == ProjectStatus.postponed
                            ? Icons.pause_circle
                            : Icons.check_circle,
                        color: status == ProjectStatus.active
                            ? Colors.green
                            : status == ProjectStatus.postponed
                            ? Colors.orange
                            : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(status.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _status = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Color Picker
            InkWell(
              onTap: _showColorPicker,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.color_lens,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Project Color',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _selectedColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveProject,
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
