import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/routing/app_router.dart';
import 'package:keep_track/core/state/stream_builder_widget.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/app_layout_controller.dart';
import 'package:keep_track/core/ui/responsive/desktop_aware_screen.dart';
import 'package:keep_track/core/ui/scoped_screen.dart';
import 'package:keep_track/features/tasks/modules/buckets/domain/entities/bucket.dart';
import 'package:keep_track/features/tasks/modules/tasks/domain/entities/task.dart';
import 'package:keep_track/features/tasks/modules/projects/domain/entities/project.dart';
import 'package:keep_track/features/tasks/presentation/state/bucket_controller.dart';
import 'package:keep_track/features/tasks/presentation/state/task_controller.dart';
import 'package:keep_track/features/tasks/presentation/state/project_controller.dart';
import 'package:keep_track/features/tasks/presentation/screens/tabs/task/components/task_management_dialog.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';
import 'package:keep_track/features/tasks/presentation/screens/tabs/task/task_details_page.dart';
import 'package:keep_track/features/tasks/presentation/screens/tabs/task/create_task_page.dart';

enum DateViewMode { daily, weekly, monthly }

enum StatusFilter { all, todo, inProgress, completed, cancelled }

enum DueDateFilter { all, dueNow, dueThisWeek, dueThisMonth }

/// Redesigned Tasks Tab with improved UI and filters
class TasksTabNew extends ScopedScreen {
  const TasksTabNew({super.key});

  @override
  State<TasksTabNew> createState() => _TasksTabNewState();
}

class _TasksTabNewState extends ScopedScreenState<TasksTabNew>
    with AppLayoutControlled {
  late final TaskController _controller;
  late final ProjectController _projectController;
  late final BucketController _bucketController;
  late final SupabaseService _supabaseService;
  late ScrollController _dateScrollController;

  DateViewMode _viewMode = DateViewMode.daily;
  DateTime _selectedDate = DateTime.now();
  StatusFilter _statusFilter = StatusFilter.all;
  DueDateFilter _dueDateFilter = DueDateFilter.all;
  final Set<String> _expandedTaskIds = {};
  Task? _selectedTaskForDrawer;

  @override
  void registerServices() {
    _controller = locator.get<TaskController>();
    _projectController = locator.get<ProjectController>();
    _bucketController = locator.get<BucketController>();
    _supabaseService = locator.get<SupabaseService>();
    _dateScrollController = ScrollController();

    // Load active projects and buckets
    _projectController.loadActiveProjects();
    _bucketController.loadBuckets();

    // Scroll to center on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCenter();
    });
  }

  @override
  void onReady() {
    configureLayout(title: 'Tasks', showBottomNav: true);
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  void _scrollToCenter() {
    if (!_dateScrollController.hasClients) return;

    // Check if the position is ready
    if (!_dateScrollController.position.hasContentDimensions) return;
    if (!_dateScrollController.position.hasViewportDimension) return;

    try {
      // For daily picker: 61 items, today is at index 30
      // Item width: 70px + 8px margin (4px each side) = 78px
      final todayIndex = 30;
      final itemWidth = 78.0;
      final viewportWidth = _dateScrollController.position.viewportDimension;

      // Calculate scroll position to center today's date
      final targetScroll =
          (todayIndex * itemWidth) - (viewportWidth / 2) + (itemWidth / 2);

      // Clamp to valid scroll range
      final maxScroll = _dateScrollController.position.maxScrollExtent;
      final scrollPosition = targetScroll.clamp(0.0, maxScroll);

      _dateScrollController.jumpTo(scrollPosition);
    } catch (e) {
      // Ignore scroll errors during layout
    }
  }

  @override
  Widget build(BuildContext context) {
    return DesktopAwareScreen(
      builder: (context, isDesktop) {
        return AsyncStreamBuilder<List<Task>>(
          state: _controller,
          builder: (context, tasks) {
            final filteredTasks = _filterTasks(tasks);
            final sortedTasks = _sortTasksByPriority(filteredTasks);

            return Scaffold(
              backgroundColor: isDesktop
                  ? (Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF09090B)
                        : AppColors.backgroundSecondary)
                  : null,
              body: isDesktop
                  ? _buildDesktopLayout(tasks, sortedTasks)
                  : _buildMobileLayout(tasks, sortedTasks),
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
          loadingBuilder: (_) => const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout(List<Task> tasks, List<Task> sortedTasks) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // View Mode Selector
              _buildViewModeSelector(),
              const SizedBox(height: 12),

              // Horizontal Date Picker
              _buildDatePicker(),
              const SizedBox(height: 16),

              // Tasks and Overview Row (2/3 tasks, 1/3 overview)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tasks Section (2/3)
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Filters Row
                        _buildFiltersSection(),
                        const SizedBox(height: 24),
                        if (sortedTasks.isEmpty)
                          _buildEmptyState()
                        else
                          _buildTaskList(sortedTasks, tasks),
                      ],
                    ),
                  ),

                  const SizedBox(width: 24),

                  // Overview Section (1/3)
                  Expanded(flex: 1, child: _buildTaskOverviewSidebar(tasks)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(List<Task> tasks, List<Task> sortedTasks) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          _buildSummaryCard(tasks),
          const SizedBox(height: 16),

          // View Mode Selector
          _buildViewModeSelector(),
          const SizedBox(height: 12),

          // Horizontal Date Picker
          _buildDatePicker(),
          const SizedBox(height: 16),

          // Filters Row
          _buildFiltersSection(),
          const SizedBox(height: 16),

          // Task List
          if (sortedTasks.isEmpty)
            _buildEmptyState()
          else
            _buildTaskList(sortedTasks, tasks),
        ],
      ),
    );
  }

  Widget _buildTaskOverviewSidebar(List<Task> tasks) {
    final totalTasks = tasks.where((t) => !t.isArchived).length;
    final completedTasks = tasks
        .where((t) => t.isCompleted && !t.isArchived)
        .length;
    final inProgressTasks = tasks
        .where((t) => t.status == TaskStatus.inProgress && !t.isArchived)
        .length;
    final todoTasks = tasks
        .where((t) => t.status == TaskStatus.todo && !t.isArchived)
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        ),
        const SizedBox(height: 16),

        // Total Tasks
        _buildOverviewStatCard(
          'Total Tasks',
          totalTasks.toString(),
          Icons.task_alt,
          Colors.blue,
        ),
        const SizedBox(height: 12),

        // In Progress
        _buildOverviewStatCard(
          'In Progress',
          inProgressTasks.toString(),
          Icons.play_circle_outline,
          Colors.blue[700]!,
        ),
        const SizedBox(height: 12),

        // To-do
        _buildOverviewStatCard(
          'To-do',
          todoTasks.toString(),
          Icons.radio_button_unchecked,
          Colors.orange,
        ),
        const SizedBox(height: 12),

        // Completed
        _buildOverviewStatCard(
          'Completed',
          completedTasks.toString(),
          Icons.check_circle,
          Colors.green,
        ),
        const SizedBox(height: 12),

        // Due Today
        _buildOverviewStatCard(
          'Due Today',
          todayTasks.toString(),
          Icons.today,
          Colors.purple,
        ),
        const SizedBox(height: 12),

        // Overdue
        _buildOverviewStatCard(
          'Overdue',
          overdueTasks.toString(),
          Icons.warning_amber_rounded,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildOverviewStatCard(
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
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(List<Task> tasks) {
    final totalTasks = tasks.length;
    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final inProgressTasks = tasks
        .where((t) => t.status == TaskStatus.inProgress)
        .length;
    final todoTasks = tasks.where((t) => t.status == TaskStatus.todo).length;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Overview',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatChip('Total', totalTasks, Colors.blue),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatChip('To-do', todoTasks, Colors.orange),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatChip(
                    'In Progress',
                    inProgressTasks,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatChip('Done', completedTasks, Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildViewModeButton(
            'Daily',
            DateViewMode.daily,
            Icons.calendar_today,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildViewModeButton(
            'Weekly',
            DateViewMode.weekly,
            Icons.calendar_view_week,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildViewModeButton(
            'Monthly',
            DateViewMode.monthly,
            Icons.calendar_month,
          ),
        ),
      ],
    );
  }

  Widget _buildViewModeButton(String label, DateViewMode mode, IconData icon) {
    final isSelected = _viewMode == mode;
    return Material(
      color: isSelected
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {
          setState(() {
            _viewMode = mode;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToCenter();
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Prevent scroll notifications from bubbling up to parent
        return true;
      },
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
          scrollbars: false,
        ),
        child: SizedBox(
          height: 80,
          child: _viewMode == DateViewMode.daily
              ? _buildDailyPicker()
              : _viewMode == DateViewMode.weekly
              ? _buildWeeklyPicker()
              : _buildMonthlyPicker(),
        ),
      ),
    );
  }

  Widget _buildDailyPicker() {
    final today = DateTime.now();
    // Generate 60 days: 30 before and 30 after today
    final dates = List.generate(61, (index) {
      return today.subtract(Duration(days: 30 - index));
    });

    return ListView.builder(
      controller: _dateScrollController,
      scrollDirection: Axis.horizontal,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        final isSelected = _isSameDay(date, _selectedDate);
        final isToday = _isSameDay(date, today);

        return GestureDetector(
          onTap: () => setState(() => _selectedDate = date),
          child: Container(
            width: 70,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : isToday
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: isToday && !isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('EEE').format(date),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date.day.toString(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM').format(date),
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected
                        ? Colors.white.withOpacity(0.9)
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeeklyPicker() {
    final today = DateTime.now();
    // Generate 20 weeks: 10 before and 10 after this week
    final weeks = List.generate(21, (index) {
      final weekStart = _getWeekStart(
        today,
      ).subtract(Duration(days: (10 - index) * 7));
      return weekStart;
    });

    return ListView.builder(
      controller: _dateScrollController,
      scrollDirection: Axis.horizontal,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: weeks.length,
      itemBuilder: (context, index) {
        final weekStart = weeks[index];
        final weekEnd = weekStart.add(const Duration(days: 6));
        final isSelected = _isSameWeek(_selectedDate, weekStart);
        final isThisWeek = _isSameWeek(today, weekStart);

        return GestureDetector(
          onTap: () => setState(() => _selectedDate = weekStart),
          child: Container(
            width: 120,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : isThisWeek
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: isThisWeek && !isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Week',
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected
                        ? Colors.white.withOpacity(0.9)
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('MMM d').format(weekStart)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  '-',
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected
                        ? Colors.white.withOpacity(0.7)
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                Text(
                  '${DateFormat('MMM d').format(weekEnd)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthlyPicker() {
    final today = DateTime.now();
    // Generate 24 months: 12 before and 12 after this month
    final months = List.generate(25, (index) {
      final month = DateTime(today.year, today.month - 12 + index, 1);
      return month;
    });

    return ListView.builder(
      controller: _dateScrollController,
      scrollDirection: Axis.horizontal,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: months.length,
      itemBuilder: (context, index) {
        final month = months[index];
        final isSelected = _isSameMonth(_selectedDate, month);
        final isThisMonth = _isSameMonth(today, month);

        return GestureDetector(
          onTap: () => setState(() => _selectedDate = month),
          child: Container(
            width: 100,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : isThisMonth
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: isThisMonth && !isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('MMMM').format(month),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  month.year.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? Colors.white.withOpacity(0.9)
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFiltersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Filter
        Text(
          'Status',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All', _statusFilter == StatusFilter.all, () {
                setState(() => _statusFilter = StatusFilter.all);
              }),
              const SizedBox(width: 8),
              _buildFilterChip('To-do', _statusFilter == StatusFilter.todo, () {
                setState(() => _statusFilter = StatusFilter.todo);
              }),
              const SizedBox(width: 8),
              _buildFilterChip(
                'In Progress',
                _statusFilter == StatusFilter.inProgress,
                () {
                  setState(() => _statusFilter = StatusFilter.inProgress);
                },
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Completed',
                _statusFilter == StatusFilter.completed,
                () {
                  setState(() => _statusFilter = StatusFilter.completed);
                },
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Cancelled',
                _statusFilter == StatusFilter.cancelled,
                () {
                  setState(() => _statusFilter = StatusFilter.cancelled);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Due Date Filter
        Text(
          'Due Date',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                'All Tasks',
                _dueDateFilter == DueDateFilter.all,
                () {
                  setState(() => _dueDateFilter = DueDateFilter.all);
                },
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Due Now',
                _dueDateFilter == DueDateFilter.dueNow,
                () {
                  setState(() => _dueDateFilter = DueDateFilter.dueNow);
                },
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Due This Week',
                _dueDateFilter == DueDateFilter.dueThisWeek,
                () {
                  setState(() => _dueDateFilter = DueDateFilter.dueThisWeek);
                },
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Due This Month',
                _dueDateFilter == DueDateFilter.dueThisMonth,
                () {
                  setState(() => _dueDateFilter = DueDateFilter.dueThisMonth);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: Theme.of(context).colorScheme.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              size: 80,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, List<Task> allTasks) {
    // Filter to show only main tasks (not subtasks) at top level
    final mainTasks = tasks.where((t) => !t.isSubtask).toList();

    // Separate tasks by date relevance
    final tasksMatchingDate = <Task>[];
    final tasksWithoutDate = <Task>[];

    for (final task in mainTasks) {
      if (task.dueDate == null) {
        tasksWithoutDate.add(task);
      } else {
        // Check if task matches the selected date based on view mode
        bool matches = false;
        switch (_viewMode) {
          case DateViewMode.daily:
            matches = _isSameDay(task.dueDate!, _selectedDate);
            break;
          case DateViewMode.weekly:
            matches = _isSameWeek(task.dueDate!, _selectedDate);
            break;
          case DateViewMode.monthly:
            matches = _isSameMonth(task.dueDate!, _selectedDate);
            break;
        }

        if (matches) {
          tasksMatchingDate.add(task);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tasks matching the selected date
        if (tasksMatchingDate.isNotEmpty) ...[
          Text(
            _getDateSectionTitle(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasksMatchingDate.length,
            itemBuilder: (context, index) {
              final task = tasksMatchingDate[index];
              return _buildTaskItem(task, allTasks, false);
            },
          ),
          const SizedBox(height: 24),
        ],

        // Tasks without dates
        if (tasksWithoutDate.isNotEmpty) ...[
          Text(
            'Tasks Without Dates',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasksWithoutDate.length,
            itemBuilder: (context, index) {
              final task = tasksWithoutDate[index];
              return _buildTaskItem(task, allTasks, false);
            },
          ),
        ],

        // Show message if no tasks in either section
        if (tasksMatchingDate.isEmpty && tasksWithoutDate.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'No tasks for selected filters',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _getDateSectionTitle() {
    switch (_viewMode) {
      case DateViewMode.daily:
        final isToday = _isSameDay(_selectedDate, DateTime.now());
        if (isToday) {
          return 'Tasks for Today';
        }
        return 'Tasks for ${DateFormat('EEEE, MMM d').format(_selectedDate)}';
      case DateViewMode.weekly:
        final weekStart = _getWeekStart(_selectedDate);
        final weekEnd = weekStart.add(const Duration(days: 6));
        return 'Tasks for Week ${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d').format(weekEnd)}';
      case DateViewMode.monthly:
        return 'Tasks for ${DateFormat('MMMM yyyy').format(_selectedDate)}';
    }
  }

  Widget _buildTaskItem(
    Task task,
    List<Task> allTasks,
    bool isLast, {
    int depth = 0,
  }) {
    final isExpanded = task.id != null && _expandedTaskIds.contains(task.id);
    final subtasks = allTasks.where((t) => t.parentTaskId == task.id).toList();
    final subtaskCount = subtasks.length;
    final isOverdue =
        task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        !task.isCompleted;

    return Column(
      children: [
        // Task row with indentation based on depth
        Container(
          margin: EdgeInsets.only(bottom: 8, left: depth * 24.0),
          decoration: BoxDecoration(
            color: isOverdue
                ? Colors.red.withOpacity(0.05)
                : Theme.of(
                    context,
                  ).colorScheme.surface.withOpacity(0.3 - (depth * 0.05)),
            borderRadius: BorderRadius.circular(8),
            border: isOverdue
                ? Border.all(color: Colors.red.withOpacity(0.5), width: 1.5)
                : depth > 0
                ? Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.2),
                  )
                : null,
          ),
          child: InkWell(
            onTap: () {
              setState(() => _selectedTaskForDrawer = task);
              // Check if desktop or mobile
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
                      onChanged: (value) =>
                          _toggleTaskCompletion(task, allTasks, value),
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
                            if (isOverdue)
                              _buildTaskBadge(
                                'OVERDUE',
                                Colors.red,
                                Icons.warning_amber_rounded,
                              ),
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
                                  final project = _projectController
                                      .currentProjects
                                      ?.where((p) => p.id == task.projectId)
                                      .firstOrNull;
                                  if (project == null)
                                    return const SizedBox.shrink();
                                  final projectColor = project.color != null
                                      ? Color(
                                          int.parse(
                                            project.color!.replaceFirst(
                                              '#',
                                              '0xff',
                                            ),
                                          ),
                                        )
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
                                      .getBucketFromCurrentState(
                                        task.bucketId!,
                                      );
                                  if (bucket == null)
                                    return const SizedBox.shrink();
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

                  // Expand icon (only show if there are subtasks)
                  if (subtaskCount > 0)
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (task.id != null) {
                            if (_expandedTaskIds.contains(task.id)) {
                              _expandedTaskIds.remove(task.id);
                            } else {
                              _expandedTaskIds.add(task.id!);
                            }
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Subtasks (shown when expanded) - RECURSIVE
        if (isExpanded && subtaskCount > 0)
          ...subtasks.map(
            (subtask) =>
                _buildTaskItem(subtask, allTasks, false, depth: depth + 1),
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

  void _showTaskEditDialog(Task task) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    if (isDesktop) {
      // Desktop: Use Dialog wrapper with content mode
      showDialog(
        context: context,
        builder: (context) => AsyncStreamBuilder<List<Bucket>>(
          state: _bucketController,
          builder: (context, buckets) {
            final activeBuckets = buckets.where((b) => !b.isArchive).toList();

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
                        buckets: activeBuckets,
                        useDialogContent: true,
                        onSave: (updatedTask) async {
                          try {
                            await _controller.updateTask(updatedTask);
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
                            await _controller.deleteTask(task.id!);
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
            );
          },
        ),
      );
    } else {
      // Mobile: Use AlertDialog mode
      showDialog(
        context: context,
        builder: (context) => AsyncStreamBuilder<List<Bucket>>(
          state: _bucketController,
          builder: (context, buckets) {
            final activeBuckets = buckets.where((b) => !b.isArchive).toList();

            return TaskManagementDialog(
              task: task,
              userId: _supabaseService.userId!,
              buckets: activeBuckets,
              onSave: (updatedTask) async {
                try {
                  await _controller.updateTask(updatedTask);
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
                  await _controller.deleteTask(task.id!);
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
            );
          },
        ),
      );
    }
  }

  void _showCreateSubtaskDialog(Task parentTask) {
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
                          'Create Subtask',
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
                    parentTaskId: parentTask.id,
                    useDialogContent: true,
                    onSave: (newTask) async {
                      try {
                        await _controller.createTask(newTask);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Subtask created successfully'),
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
          userId: _supabaseService.userId!,
          parentTaskId: parentTask.id,
          onSave: (newTask) async {
            try {
              await _controller.createTask(newTask);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Subtask created successfully'),
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
                              await _controller.createTask(newTask);
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
                child: TaskDetailsPage(task: task, isDrawerMode: true),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailSection(String title, IconData icon, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(padding: const EdgeInsets.only(left: 28), child: content),
      ],
    );
  }

  Widget _buildEditableDetailSection(
    String title,
    IconData icon,
    Widget content,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(padding: const EdgeInsets.only(left: 28), child: content),
      ],
    );
  }

  List<Task> _filterTasks(List<Task> tasks) {
    var filtered = tasks.where((task) => !task.isArchived).toList();

    // Filter by selected date/week/month
    filtered = filtered.where((task) {
      if (task.dueDate == null) return _dueDateFilter == DueDateFilter.all;

      switch (_viewMode) {
        case DateViewMode.daily:
          return _isSameDay(task.dueDate!, _selectedDate);
        case DateViewMode.weekly:
          return _isSameWeek(task.dueDate!, _selectedDate);
        case DateViewMode.monthly:
          return _isSameMonth(task.dueDate!, _selectedDate);
      }
    }).toList();

    // Filter by status
    if (_statusFilter != StatusFilter.all) {
      filtered = filtered.where((task) {
        switch (_statusFilter) {
          case StatusFilter.todo:
            return task.status == TaskStatus.todo;
          case StatusFilter.inProgress:
            return task.status == TaskStatus.inProgress;
          case StatusFilter.completed:
            return task.status == TaskStatus.completed;
          case StatusFilter.cancelled:
            return task.status == TaskStatus.cancelled;
          case StatusFilter.all:
            return true;
        }
      }).toList();
    }

    // Filter by due date
    if (_dueDateFilter != DueDateFilter.all) {
      final now = DateTime.now();
      filtered = filtered.where((task) {
        if (task.dueDate == null) return false;

        switch (_dueDateFilter) {
          case DueDateFilter.dueNow:
            return task.dueDate!.isBefore(now) ||
                _isSameDay(task.dueDate!, now);
          case DueDateFilter.dueThisWeek:
            final weekEnd = now.add(const Duration(days: 7));
            return task.dueDate!.isBefore(weekEnd);
          case DueDateFilter.dueThisMonth:
            return task.dueDate!.year == now.year &&
                task.dueDate!.month == now.month;
          case DueDateFilter.all:
            return true;
        }
      }).toList();
    }

    return filtered;
  }

  List<Task> _sortTasksByPriority(List<Task> tasks) {
    final sorted = List<Task>.from(tasks);
    sorted.sort((a, b) {
      // Sort by priority first
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

      // Then by due date
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      }
      if (a.dueDate != null) return -1;
      if (b.dueDate != null) return 1;

      return 0;
    });
    return sorted;
  }

  Future<void> _toggleTaskCompletion(
    Task task,
    List<Task> allTasks,
    bool? value,
  ) async {
    if (value == null) return;

    final updatedTask = task.copyWith(
      status: value ? TaskStatus.completed : TaskStatus.todo,
      completedAt: value ? DateTime.now() : null,
    );
    await _controller.updateTask(updatedTask);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _isSameWeek(DateTime date1, DateTime date2) {
    final weekStart1 = _getWeekStart(date1);
    final weekStart2 = _getWeekStart(date2);
    return _isSameDay(weekStart1, weekStart2);
  }

  bool _isSameMonth(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
  }

  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
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
}
