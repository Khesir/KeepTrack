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
import 'package:keep_track/features/tasks/presentation/screens/tabs/task/tasks_tab_new.dart';
import 'package:keep_track/features/tasks/presentation/screens/tabs/projects_tab.dart';
import 'package:keep_track/features/tasks/presentation/screens/tabs/pomodoro_tab.dart';
import 'package:keep_track/features/tasks/presentation/widgets/pomodoro_nav_indicator.dart';

import '../auth/presentation/screens/auth_settings_screen.dart';

/// Task Module Screen - Wraps the task management functionality
/// This is what users see when they select "Task Management" from module selection
class TaskModuleScreen extends StatefulWidget {
  final int initialTabIndex;

  const TaskModuleScreen({super.key, this.initialTabIndex = 0});

  @override
  State<TaskModuleScreen> createState() => _TaskModuleScreenState();
}

class _TaskModuleScreenState extends State<TaskModuleScreen> {
  late int _currentIndex;
  final _layoutController = AppLayoutController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
  }

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
      MaterialPageRoute(builder: (context) => const ModuleSelectionScreen()),
    );
  }

  List<Widget> _buildActions() {
    return [
      // Pomodoro timer indicator (shows when session is active)
      PomodoroNavIndicator(
        onTap: () => _changeTab(3), // Navigate to Pomodoro tab
      ),
      const SizedBox(width: 8),
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
            MaterialPageRoute(builder: (context) => const LogViewerScreen()),
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
                final isDesktop =
                    constraints.maxWidth >= ResponsiveBreakpoints.desktop;

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.task_alt,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tasks',
                      style: AppTextStyles.h4.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Management',
                      style: AppTextStyles.caption.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
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
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.apps,
                    size: 20,
                    color: theme.textTheme.bodySmall?.color ?? theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'All Modules',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: theme.textTheme.bodySmall?.color ?? theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(String label, IconData icon, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = _currentIndex == index;
    final activeColor = isDark ? const Color(0xFF27272A) : AppColors.secondary;
    final textColor = theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface;
    final secondaryTextColor = theme.textTheme.bodySmall?.color ?? theme.colorScheme.onSurface.withOpacity(0.6);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? activeColor : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          size: 20,
          color: isActive ? textColor : secondaryTextColor,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
            color: isActive ? textColor : secondaryTextColor,
          ),
        ),
        onTap: () => _changeTab(index),
      ),
    );
  }

  Widget _buildTopBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: borderColor)),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);
    final authController = locator.get<AuthController>();
    final user = authController.currentUser;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: PopupMenuButton<String>(
        tooltip: 'Account options',
        offset: const Offset(0, -8),
        constraints: const BoxConstraints(
          minWidth: 236, // 260 (sidebar width) - 24 (padding)
          maxWidth: 236,
        ),
        onSelected: (value) async {
          if (value == 'manage_account') {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AuthSettingsScreen(),
              ),
            );
          } else if (value == 'signout') {
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
            value: 'manage_account',
            child: Row(
              children: [
                Icon(Icons.manage_accounts, size: 18),
                SizedBox(width: 12),
                Text('Manage Account'),
              ],
            ),
          ),
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
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              )
            else
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.7),
                      theme.colorScheme.primary,
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
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user?.email ?? 'No email',
                    style: AppTextStyles.caption.copyWith(
                      color: theme.textTheme.bodySmall?.color ?? theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.more_vert,
              size: 20,
              color: theme.textTheme.bodySmall?.color ?? theme.colorScheme.onSurface.withOpacity(0.6),
            ),
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
