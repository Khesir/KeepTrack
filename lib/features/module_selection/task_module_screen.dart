import 'package:flutter/material.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/logging/log_viewer_screen.dart';
import 'package:keep_track/core/settings/domain/entities/app_settings.dart';
import 'package:keep_track/core/settings/presentation/settings_controller.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/app_layout_controller.dart';
import 'package:keep_track/core/ui/responsive/responsive_breakpoints.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';
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

  final List<Widget> _screens = const [
    TaskHomeScreen(),
    TasksTabNew(),
    ProjectsTab(),
    PomodoroTab(),
    ProfileScreen(moduleType: ModuleType.task),
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
      // Theme toggle button
      IconButton(
        icon: Icon(
          Theme.of(context).brightness == Brightness.dark
              ? Icons.light_mode
              : Icons.dark_mode,
        ),
        onPressed: () {
          final settingsController = locator.get<SettingsController>();
          final currentTheme = Theme.of(context).brightness;
          settingsController.updateThemeMode(
            currentTheme == Brightness.dark
                ? AppThemeMode.light
                : AppThemeMode.dark,
          );
        },
        tooltip: 'Toggle Theme',
      ),
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
            return LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= ResponsiveBreakpoints.desktop;

                if (isDesktop) {
                  return _buildDesktopLayout();
                } else {
                  return _buildMobileLayout();
                }
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _screens[_currentIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateToModuleSelection,
        ),
        title: Text(_layoutController.title),
        actions: _buildActions(),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _changeTab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.task_alt), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.folder), label: 'Projects'),
          NavigationDestination(icon: Icon(Icons.timer), label: 'Pomodoro'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                const Icon(Icons.task_alt, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tasks', style: AppTextStyles.h4),
                    Text('Management', style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildNavItem('Home', Icons.home, 0),
                _buildNavItem('Tasks', Icons.task_alt, 1),
                _buildNavItem('Projects', Icons.folder, 2),
                _buildNavItem('Pomodoro', Icons.timer, 3),
                _buildNavItem('Profile', Icons.person, 4),
              ],
            ),
          ),
          // Logout button
          _buildUserProfileSection(),
          // All Modules button
          InkWell(
            onTap: _navigateToModuleSelection,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.apps, size: 20, color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Text('All Modules', style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(String label, IconData icon, int index) {
    final isActive = _currentIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.secondary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, size: 20,
            color: isActive ? AppColors.textPrimary : AppColors.textSecondary),
        title: Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                color: isActive ? AppColors.textPrimary : AppColors.textSecondary)),
        onTap: () => _changeTab(index),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(_layoutController.title, style: AppTextStyles.h3),
          const Spacer(),
          ..._buildActions(),
        ],
      ),
    );
  }

  Widget _buildUserProfileSection() {
    final authController = locator.get<AuthController>();
    final user = authController.currentUser;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: PopupMenuButton<String>(
        tooltip: 'Account options',
        offset: const Offset(0, -8),
        constraints: const BoxConstraints(
          minWidth: 236, // 260 (sidebar width) - 24 (padding)
          maxWidth: 236,
        ),
        onSelected: (value) async {
          if (value == 'signout') {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Sign Out'),
                content: const Text('Are you sure you want to sign out?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            );

            if (confirmed == true && mounted) {
              await authController.signOut();
            }
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'signout',
            child: Row(
              children: [
                Icon(Icons.logout, size: 18, color: Colors.red),
                SizedBox(width: 12),
                Text('Sign Out', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
        child: Row(
          children: [
            // Avatar
            if (user?.photoUrl != null)
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(user!.photoUrl!),
                backgroundColor: AppColors.primary.withOpacity(0.1),
              )
            else
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.7),
                      AppColors.primary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, size: 20, color: Colors.white),
              ),
            const SizedBox(width: 12),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user?.displayName ?? 'User',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user?.email ?? 'No email',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
          ],
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
