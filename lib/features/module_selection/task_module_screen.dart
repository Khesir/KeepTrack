import 'package:flutter/material.dart';
import 'package:keep_track/core/logging/log_viewer_screen.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/app_layout_controller.dart';
import 'package:keep_track/core/ui/responsive/desktop_sidebar.dart';
import 'package:keep_track/core/ui/responsive/responsive_layout_wrapper.dart';
import 'package:keep_track/features/home/task_home_screen.dart';
import 'package:keep_track/features/module_selection/module_selection_screen.dart';
import 'package:keep_track/features/profile/presentation/profile_screen.dart';
import 'package:keep_track/features/tasks/presentation/screens/tabs/tasks_tab_new.dart';
import 'package:keep_track/features/tasks/presentation/screens/tabs/projects_tab.dart';
import 'package:keep_track/features/tasks/presentation/screens/tabs/pomodoro_tab.dart';

/// Task Module Screen - Wraps the task management functionality
/// This is what users see when they select "Task Management" from module selection
class TaskModuleScreen extends StatefulWidget {
  const TaskModuleScreen({super.key});

  @override
  State<TaskModuleScreen> createState() => _TaskModuleScreenState();
}

class _TaskModuleScreenState extends State<TaskModuleScreen> {
  int _currentIndex = 0;
  final _layoutController = AppLayoutController();

  void _changeTab(int index) {
    setState(() => _currentIndex = index);
  }

  // Navigation items for both mobile and desktop
  List<ResponsiveNavItem> get _navItems => const [
        ResponsiveNavItem(
          label: 'Home',
          icon: Icons.home,
          screen: TaskHomeScreen(),
        ),
        ResponsiveNavItem(
          label: 'Tasks',
          icon: Icons.task_alt,
          screen: TasksTabNew(),
        ),
        ResponsiveNavItem(
          label: 'Projects',
          icon: Icons.folder,
          screen: ProjectsTab(),
        ),
        ResponsiveNavItem(
          label: 'Pomodoro',
          icon: Icons.timer,
          screen: PomodoroTab(),
        ),
        ResponsiveNavItem(
          label: 'Profile',
          icon: Icons.person,
          screen: ProfileScreen(moduleType: ModuleType.task),
        ),
      ];

  @override
  void dispose() {
    _layoutController.dispose();
    super.dispose();
  }

  void _navigateToModuleSelection() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const ModuleSelectionScreen(),
      ),
    );
  }

  List<Widget> _buildActions() {
    return [
      // Logging action button
      IconButton(
        icon: const Icon(Icons.bug_report),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LogViewerScreen(),
            ),
          );
        },
        tooltip: 'View Logs',
      ),
      if (_layoutController.showSettings)
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/settings',
              arguments: {'mode': 'task'},
            );
          },
          tooltip: 'Settings',
        ),
      // Other actions from layout controller
      ..._layoutController.actions,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AppLayoutProvider(
      controller: _layoutController,
      child: TaskModuleInherited(
        changeTab: _changeTab,
        child: AnimatedBuilder(
          animation: _layoutController,
          builder: (context, child) {
            return ResponsiveLayoutWrapper(
              config: ResponsiveLayoutConfig(
                navItems: _navItems,
                currentIndex: _currentIndex,
                onNavIndexChanged: _changeTab,
                title: _layoutController.title,
                actions: _buildActions(),
                sidebarHeader: const SidebarHeader(
                  title: 'Tasks',
                  subtitle: 'Management',
                  leading: Icon(
                    Icons.task_alt,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                sidebarFooter: SidebarFooter(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _navigateToModuleSelection,
                      borderRadius: AppRadius.circularMd,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.apps,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              'All Modules',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                floatingActionButton:
                    _layoutController.showBottomNav ? null : null,
              ),
            );
          },
        ),
      ),
    );
  }
}

// Create an InheritedWidget to pass the callback down
class TaskModuleInherited extends InheritedWidget {
  final void Function(int) changeTab;

  const TaskModuleInherited({
    super.key,
    required this.changeTab,
    required super.child,
  });

  static TaskModuleInherited? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TaskModuleInherited>();
  }

  @override
  bool updateShouldNotify(TaskModuleInherited oldWidget) => false;
}
