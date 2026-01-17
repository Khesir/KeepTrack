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
import 'package:keep_track/features/tasks/presentation/screens/tabs/task/task_details_page.dart';
import 'package:keep_track/features/tasks/presentation/screens/tabs/task/components/task_management_dialog.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';

import '../module_selection/task_module_screen.dart';

import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/responsive/desktop_aware_screen.dart';

import '../tasks/modules/buckets/domain/entities/bucket.dart';
import '../tasks/presentation/screens/tabs/task/create_task_page.dart';
import '../tasks/presentation/state/bucket_controller.dart';

enum TaskTimeFilter { today, sevenDays, thirtyDays, all }

enum TaskSortOption { priority, dueDate, status }

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
  late final BucketController _bucketController;
  late final SupabaseService _supabaseService;

  TaskTimeFilter _timeFilter = TaskTimeFilter.today;
  TaskSortOption _sortOption = TaskSortOption.priority;
  @override
  void registerServices() {
    _taskController = locator.get<TaskController>();
    _projectController = locator.get<ProjectController>();
    _supabaseService = locator.get<SupabaseService>();
    _bucketController = locator.get<BucketController>();

    _bucketController.loadBuckets();
  }

  @override
  void onReady() {
    configureLayout(title: 'Home', showBottomNav: true);
    _taskController.loadTasks();
    _projectController.loadActiveProjects(); // Load only active projects
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

  void _showCreateTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AsyncStreamBuilder<List<Project>>(
        state: _projectController,
        builder: (context, projects) {
          // Filter to only active projects
          final activeProjects = projects
              .where((p) => p.status == ProjectStatus.active && !p.isArchived)
              .toList();

          return AsyncStreamBuilder<List<Bucket>>(
            state: _bucketController,
            builder: (context, buckets) {
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
                                'Create Task',
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
                          userId: _supabaseService.userId!,
                          projects: activeProjects,
                          buckets: buckets,
                          useDialogContent: true,
                          onSave: (newTask) async {
                            try {
                              await _taskController.createTask(newTask);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Task created successfully'),
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
                        ),
                      ),

                      // Footer with "View Full Page" button
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.open_in_full),
                            label: const Text('View Full Page'),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CreateTaskPage(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _handleCreateTask() {
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    if (isDesktop) {
      // Show dialog with "View Full Page" option on desktop
      _showCreateTaskDialog();
    } else {
      // Navigate directly to full page on mobile
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreateTaskPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DesktopAwareScreen(
      builder: (context, isDesktop) {
        return Scaffold(
          backgroundColor: isDesktop
              ? (Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF09090B)
                    : AppColors.backgroundSecondary)
              : null,
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
                                _buildTaskSnapshot(isDesktop),
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
                      _buildTaskSnapshot(isDesktop),
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
                  label: const Text('New Task'),
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

  Widget _buildTaskSnapshot(bool isDesktop) {
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
            if (isDesktop)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Task Overview',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: _handleCreateTask,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('New Task'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              )
            else
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

  List<Task> _filterTasks(List<Task> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayEnd = today.add(const Duration(days: 1));

    switch (_timeFilter) {
      case TaskTimeFilter.today:
        return tasks.where((t) {
          if (t.isArchived) return false;
          if (t.dueDate == null) return false;
          final taskDate = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
          return taskDate.isAtSameMomentAs(today) ||
                 (t.dueDate!.isAfter(today) && t.dueDate!.isBefore(todayEnd));
        }).toList();
      case TaskTimeFilter.sevenDays:
        final endDate = today.add(const Duration(days: 7));
        return tasks.where((t) {
          if (t.isArchived) return false;
          if (t.dueDate == null) return false;
          final taskDate = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
          return (taskDate.isAtSameMomentAs(today) || taskDate.isAfter(today)) &&
                 taskDate.isBefore(endDate);
        }).toList();
      case TaskTimeFilter.thirtyDays:
        final endDate = today.add(const Duration(days: 30));
        return tasks.where((t) {
          if (t.isArchived) return false;
          if (t.dueDate == null) return false;
          final taskDate = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
          return (taskDate.isAtSameMomentAs(today) || taskDate.isAfter(today)) &&
                 taskDate.isBefore(endDate);
        }).toList();
      case TaskTimeFilter.all:
        return tasks.where((t) => !t.isArchived).toList();
    }
  }

  List<Task> _sortTasks(List<Task> tasks) {
    final sortedTasks = List<Task>.from(tasks);

    switch (_sortOption) {
      case TaskSortOption.priority:
        sortedTasks.sort((a, b) {
          final priorityOrder = {
            TaskPriority.urgent: 0,
            TaskPriority.high: 1,
            TaskPriority.medium: 2,
            TaskPriority.low: 3,
          };
          return priorityOrder[a.priority]!.compareTo(
            priorityOrder[b.priority]!,
          );
        });
        break;
      case TaskSortOption.dueDate:
        sortedTasks.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case TaskSortOption.status:
        sortedTasks.sort((a, b) => a.status.index.compareTo(b.status.index));
        break;
    }

    return sortedTasks;
  }

  Widget _buildCurrentTasks() {
    return AsyncStreamBuilder<List<Task>>(
      state: _taskController,
      builder: (context, tasks) {
        final filteredTasks = _filterTasks(tasks);
        final sortedTasks = _sortTasks(filteredTasks);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tasks',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${sortedTasks.length} task${sortedTasks.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Filter and Sort Options
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Time Filter
                DropdownButton<TaskTimeFilter>(
                  value: _timeFilter,
                  isDense: true,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: TaskTimeFilter.today,
                      child: Text('Today'),
                    ),
                    DropdownMenuItem(
                      value: TaskTimeFilter.sevenDays,
                      child: Text('7 Days'),
                    ),
                    DropdownMenuItem(
                      value: TaskTimeFilter.thirtyDays,
                      child: Text('30 Days'),
                    ),
                    DropdownMenuItem(
                      value: TaskTimeFilter.all,
                      child: Text('All Tasks'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _timeFilter = value);
                    }
                  },
                ),
                const SizedBox(width: 8),
                // Sort Options
                DropdownButton<TaskSortOption>(
                  value: _sortOption,
                  isDense: true,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: TaskSortOption.priority,
                      child: Row(
                        children: [
                          Icon(Icons.sort, size: 16),
                          SizedBox(width: 4),
                          Text('Priority'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: TaskSortOption.dueDate,
                      child: Row(
                        children: [
                          Icon(Icons.sort, size: 16),
                          SizedBox(width: 4),
                          Text('Due Date'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: TaskSortOption.status,
                      child: Row(
                        children: [
                          Icon(Icons.sort, size: 16),
                          SizedBox(width: 4),
                          Text('Status'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _sortOption = value);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (sortedTasks.isEmpty)
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
                        'No tasks found',
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
                itemCount: sortedTasks.length > 10 ? 10 : sortedTasks.length,
                itemBuilder: (context, index) {
                  final task = sortedTasks[index];
                  return _buildTaskItem(task, tasks);
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

  Widget _buildTaskItem(Task task, List<Task> allTasks) {
    final isOverdue =
        task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        !task.isCompleted;
    final subtasks = allTasks.where((t) => t.parentTaskId == task.id).toList();
    final subtaskCount = subtasks.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isOverdue
            ? Colors.red.withOpacity(0.05)
            : Theme.of(context).colorScheme.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: isOverdue
            ? Border.all(color: Colors.red.withOpacity(0.5), width: 1.5)
            : null,
      ),
      child: InkWell(
        onTap: () {
          final isDesktop = MediaQuery.of(context).size.width >= 600;
          if (isDesktop) {
            _showTaskDrawer(task, allTasks);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskDetailsPage(task: task),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Priority indicator
              Container(
                width: 4,
                height: 50,
                decoration: BoxDecoration(
                  color: _getPriorityColor(task.priority),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),

              // Checkbox
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
                    await _taskController.updateTask(updatedTask);
                  }
                },
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (task.description != null &&
                        task.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (isOverdue)
                          _buildTaskBadge(
                            'OVERDUE',
                            Colors.red,
                            Icons.warning_amber_rounded,
                          ),
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
                              ? DateFormat('MMM d, h:mm a').format(task.dueDate!)
                              : 'No date',
                          task.dueDate != null
                              ? (isOverdue ? Colors.red : Colors.grey[700]!)
                              : Colors.grey[400]!,
                          Icons.calendar_today,
                        ),
                        if (subtaskCount > 0)
                          _buildTaskBadge(
                            '$subtaskCount subtask${subtaskCount > 1 ? 's' : ''}',
                            Colors.blue[700]!,
                            Icons.list,
                          ),
                        // Project badge
                        if (task.projectId != null)
                          Builder(
                            builder: (context) {
                              final project = _projectController.currentProjects
                                  ?.where((p) => p.id == task.projectId)
                                  .firstOrNull;
                              if (project == null) return const SizedBox.shrink();
                              final projectColor = project.color != null
                                  ? Color(int.parse(
                                      project.color!.replaceFirst('#', '0xff')))
                                  : Colors.blue[700]!;
                              return _buildTaskBadge(
                                project.name,
                                projectColor,
                                Icons.folder,
                              );
                            },
                          ),
                        // Bucket badge
                        if (task.bucketId != null)
                          Builder(
                            builder: (context) {
                              final bucket = _bucketController
                                  .getBucketFromCurrentState(task.bucketId!);
                              if (bucket == null) return const SizedBox.shrink();
                              return _buildTaskBadge(
                                bucket.name,
                                Colors.purple[700]!,
                                Icons.inbox,
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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

  void _showTaskDrawer(Task task, List<Task> allTasks) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Task Details',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        final subtasks = allTasks
            .where((t) => t.parentTaskId == task.id)
            .toList();
        final isOverdue =
            task.dueDate != null &&
            task.dueDate!.isBefore(DateTime.now()) &&
            !task.isCompleted;

        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 24),
            child: Material(
              elevation: 8,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Container(
                width: MediaQuery.of(context).size.width > 600
                    ? 500
                    : MediaQuery.of(context).size.width * 0.85,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
                child: Column(
                  children: [
                    // Header
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
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              Navigator.pop(context);
                              _showTaskEditDialog(task);
                            },
                            tooltip: 'Edit Task',
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    // Quick task details preview
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            if (isOverdue)
                              Chip(
                                avatar: const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                label: const Text('OVERDUE'),
                                backgroundColor: Colors.red.withOpacity(0.1),
                                side: BorderSide(
                                  color: Colors.red.withOpacity(0.5),
                                ),
                              ),
                            if (task.description != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Text(task.description!),
                              ),
                            if (subtasks.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                '${subtasks.length} Subtask${subtasks.length > 1 ? 's' : ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
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
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.open_in_full),
                          label: const Text('View Full Details'),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    TaskDetailsPage(task: task),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTaskEditDialog(Task task) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    if (isDesktop) {
      // Desktop: Use Dialog wrapper with content mode
      showDialog(
        context: context,
        builder: (context) => Dialog(
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
                    useDialogContent: true,
                    onSave: (updatedTask) async {
                      try {
                        await _taskController.updateTask(updatedTask);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Task updated successfully'),
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
                    onDelete: () async {
                      try {
                        await _taskController.deleteTask(task.id!);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Task deleted successfully'),
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
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Mobile: Use AlertDialog mode
      showDialog(
        context: context,
        builder: (context) => TaskManagementDialog(
          task: task,
          userId: _supabaseService.userId!,
          onSave: (updatedTask) async {
            try {
              await _taskController.updateTask(updatedTask);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Task updated successfully'),
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
          onDelete: () async {
            try {
              await _taskController.deleteTask(task.id!);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Task deleted successfully'),
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
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.projectManagement);
                  },
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: Text(
                    '${activeProjects.length} project${activeProjects.length != 1 ? 's' : ''}',
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
              // 3-Grid Layout for Projects
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: activeProjects.length > 6
                    ? 6
                    : activeProjects.length,
                itemBuilder: (context, index) {
                  final project = activeProjects[index];
                  return _buildProjectCard(project);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildProjectCard(Project project) {
    final projectColor = project.color != null
        ? Color(int.parse(project.color!.replaceFirst('#', '0xff')))
        : Colors.blue[700]!;

    // Get bucket from project metadata or default
    final bucket = project.metadata['bucket'] ?? 'Work';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: projectColor.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.projectDetail,
            arguments: project,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project Icon & Color
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: projectColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.folder, color: projectColor, size: 20),
              ),
              const SizedBox(height: 8),
              // Project Title
              Text(
                project.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              // Bucket Tab
              _buildBucketChip(bucket),
              const SizedBox(height: 8),
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  project.status.displayName,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBucketChip(String bucket) {
    Color bucketColor;
    IconData bucketIcon;

    switch (bucket.toLowerCase()) {
      case 'work':
        bucketColor = Colors.blue;
        bucketIcon = Icons.work;
        break;
      case 'personal':
        bucketColor = Colors.green;
        bucketIcon = Icons.person;
        break;
      case 'urgent':
        bucketColor = Colors.red;
        bucketIcon = Icons.priority_high;
        break;
      case 'learning':
        bucketColor = Colors.purple;
        bucketIcon = Icons.school;
        break;
      default:
        bucketColor = Colors.grey;
        bucketIcon = Icons.folder;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bucketColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(bucketIcon, size: 10, color: bucketColor),
          const SizedBox(width: 4),
          Text(
            bucket,
            style: TextStyle(
              fontSize: 9,
              color: bucketColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
