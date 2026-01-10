import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/ui/app_layout_controller.dart';
import 'package:keep_track/core/ui/ui.dart';
import 'package:keep_track/core/routing/app_router.dart';
import 'package:keep_track/features/tasks/modules/tasks/domain/entities/task.dart';
import 'package:keep_track/features/tasks/modules/projects/domain/entities/project.dart';
import 'package:keep_track/features/tasks/presentation/state/task_controller.dart';
import 'package:keep_track/features/tasks/presentation/state/project_controller.dart';

import '../module_selection/task_module_screen.dart';

import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/responsive/desktop_aware_screen.dart';

/// Task-focused Home Screen for Task Management Module
class TaskHomeScreen extends ScopedScreen {
  const TaskHomeScreen({super.key});

  @override
  State<TaskHomeScreen> createState() => _TaskHomeScreenState();
}

class _TaskHomeScreenState extends ScopedScreenState<TaskHomeScreen>
    with AppLayoutControlled {
  late final TaskController _taskController;
  late final ProjectController _projectController;

  @override
  void registerServices() {
    _taskController = locator.get<TaskController>();
    _projectController = locator.get<ProjectController>();
  }

  @override
  void onReady() {
    configureLayout(title: 'Home', showBottomNav: true);
    _taskController.loadTasks();
    _projectController.loadProjects();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return Icons.wb_sunny;
    if (hour < 17) return Icons.wb_sunny_outlined;
    return Icons.nightlight_round;
  }

  @override
  Widget build(BuildContext context) {
    return DesktopAwareScreen(
      builder: (context, isDesktop) {
        return Scaffold(
          backgroundColor: isDesktop ? AppColors.backgroundSecondary : null,
          body: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? AppSpacing.xl : 16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 1400 : double.infinity,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header on Desktop
                    if (isDesktop)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Task Dashboard', style: AppTextStyles.h1),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.taskCreate,
                              );
                            },
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text('Add Task'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (isDesktop) SizedBox(height: AppSpacing.xl),

                    // Welcome Section
                    _buildWelcomeSection(isDesktop),
                    SizedBox(height: isDesktop ? AppSpacing.xl : 24),

                    // Desktop: Two-column layout
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column - Task Snapshot & Current Tasks
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _buildTaskSnapshot(),
                                const SizedBox(height: AppSpacing.xl),
                                _buildCurrentTasks(),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xl),
                          // Right Column - Projects & Quick Actions
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                _buildProjectOverview(),
                                const SizedBox(height: AppSpacing.xl),
                                _buildQuickActions(context, isDesktop),
                              ],
                            ),
                          ),
                        ],
                      )
                    else ...[
                      // Mobile: Stack vertically
                      _buildTaskSnapshot(),
                      const SizedBox(height: 24),
                      _buildCurrentTasks(),
                      const SizedBox(height: 24),
                      _buildProjectOverview(),
                      const SizedBox(height: 24),
                      _buildQuickActions(context, isDesktop),
                    ],

                    const SizedBox(height: 24),
                    // Extra bottom padding for mobile FAB
                    if (!isDesktop) const SizedBox(height: 80),
                  ],
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
                  backgroundColor: Colors.blue,
                ),
        );
      },
    );
  }

  Widget _buildWelcomeSection(bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getGreetingIcon(),
                color: Colors.white,
                size: isDesktop ? 32 : 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isDesktop ? 28 : 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Welcome back!',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.today, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: isDesktop ? 20 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isDesktop ? 16 : 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isDesktop ? 1 : 2,
          childAspectRatio: isDesktop ? 3 : 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildActionCard(
              'New Task',
              Icons.add_task,
              Colors.blue,
              () => Navigator.pushNamed(context, AppRoutes.taskCreate),
              isDesktop,
            ),
            _buildActionCard('View Projects', Icons.folder, Colors.purple, () {
              TaskModuleInherited.of(context)?.changeTab(2);
            }, isDesktop),
            _buildActionCard(
              'Manage Tasks',
              Icons.settings,
              Colors.orange,
              () => Navigator.pushNamed(context, AppRoutes.taskManagement),
              isDesktop,
            ),
            _buildActionCard(
              'Manage Projects',
              Icons.folder_open,
              Colors.teal,
              () => Navigator.pushNamed(context, AppRoutes.projectManagement),
              isDesktop,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isDesktop,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: isDesktop
            ? Row(
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTaskSnapshot() {
    return AsyncStreamBuilder(
      state: _taskController,
      builder: (context, tasks) {
        final totalTasks = tasks.where((t) => !t.isArchived).length;
        final completedTasks = tasks
            .where((t) => t.isCompleted && !t.isArchived)
            .length;
        final inProgressTasks = tasks
            .where((t) => t.status == TaskStatus.inProgress && !t.isArchived)
            .length;
        final todayTasks = tasks.where((t) {
          if (t.dueDate == null || t.isArchived) return false;
          final today = DateTime.now();
          return t.dueDate!.year == today.year &&
              t.dueDate!.month == today.month &&
              t.dueDate!.day == today.day;
        }).length;
        final overdueTasks = tasks.where((t) {
          if (t.dueDate == null || t.isArchived || t.isCompleted) return false;
          return t.dueDate!.isBefore(DateTime.now());
        }).length;
        final noDateTasks = tasks
            .where((t) => t.dueDate == null && !t.isArchived && !t.isCompleted)
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Task Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Tasks',
                    totalTasks.toString(),
                    Icons.task_alt,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'In Progress',
                    inProgressTasks.toString(),
                    Icons.play_circle_outline,
                    Colors.blue[700]!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Completed',
                    completedTasks.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Due Today',
                    todayTasks.toString(),
                    Icons.today,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Overdue',
                    overdueTasks.toString(),
                    Icons.warning_amber_rounded,
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'No Date',
                    noDateTasks.toString(),
                    Icons.event_busy,
                    Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildCurrentTasks() {
    return AsyncStreamBuilder<List<Task>>(
      state: _taskController,
      builder: (context, tasks) {
        final currentTasks = tasks
            .where((t) => t.status == TaskStatus.inProgress && !t.isArchived)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Tasks',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${currentTasks.length} task${currentTasks.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (currentTasks.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.task_alt,
                        size: 48,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No tasks in progress',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: currentTasks.length > 5 ? 5 : currentTasks.length,
                itemBuilder: (context, index) {
                  final task = currentTasks[index];
                  return _buildTaskItem(task);
                },
              ),
            // if (currentTasks.length > 5)
            //   Padding(
            //     padding: const EdgeInsets.only(top: 8),
            //     child: TextButton(
            //       onPressed: () =>
            //           Navigator.pushNamed(context, AppRoutes.taskList),
            //       child: Text('View all ${currentTasks.length} tasks'),
            //     ),
            //   ),
          ],
        );
      },
    );
  }

  Widget _buildTaskItem(Task task) {
    Color priorityColor;
    switch (task.priority) {
      case TaskPriority.urgent:
        priorityColor = Colors.red[700]!;
        break;
      case TaskPriority.high:
        priorityColor = Colors.orange[700]!;
        break;
      case TaskPriority.medium:
        priorityColor = Colors.blue[700]!;
        break;
      case TaskPriority.low:
        priorityColor = Colors.grey[700]!;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Checkbox to mark task as complete
            Checkbox(
              value: task.isCompleted,
              onChanged: (value) async {
                if (value != null) {
                  final updatedTask = task.copyWith(
                    status: value
                        ? TaskStatus.completed
                        : TaskStatus.inProgress,
                    completedAt: value ? DateTime.now() : null,
                  );
                  await _taskController.updateTask(updatedTask);
                }
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: priorityColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: task.isCompleted
                          ? Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5)
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (task.description != null &&
                      task.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (task.dueDate != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Due: ${_formatDate(task.dueDate!)}',
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
      ),
    );
  }

  Widget _buildProjectOverview() {
    return AsyncStreamBuilder(
      state: _projectController,
      builder: (context, projects) {
        final activeProjects = projects
            .where((p) => p.status == ProjectStatus.active && !p.isArchived)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Active Projects',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${activeProjects.length} project${activeProjects.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (activeProjects.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 48,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No active projects',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: activeProjects.length,
                  itemBuilder: (context, index) {
                    final project = activeProjects[index];
                    return _buildProjectCard(project);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildProjectCard(project) {
    final projectColor = project.color != null
        ? Color(int.parse(project.color!.replaceFirst('#', '0xff')))
        : Colors.blue[700]!;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [projectColor, projectColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.projectDetail,
              arguments: project,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.folder, color: Colors.white, size: 32),
                const SizedBox(height: 12),
                Text(
                  project.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                if (project.description != null &&
                    project.description!.isNotEmpty)
                  Text(
                    project.description!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);

    final difference = taskDate.difference(today).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference < 0) {
      return '${-difference} days ago';
    } else if (difference < 7) {
      return 'in $difference days';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
