import 'package:flutter/material.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/logging/log_viewer_screen.dart';
import 'package:keep_track/core/settings/domain/entities/app_settings.dart';
import 'package:keep_track/core/settings/presentation/settings_controller.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/app_layout_controller.dart';
import 'package:keep_track/core/ui/responsive/responsive_breakpoints.dart';
import 'package:keep_track/features/auth/presentation/state/auth_controller.dart';
import 'package:keep_track/features/finance/presentation/screens/finance_main_screen.dart';
import 'package:keep_track/features/finance/presentation/screens/tabs/accounts/accounts_tab_new.dart';
import 'package:keep_track/features/finance/presentation/screens/tabs/budgets/budgets_tab_new.dart';
import 'package:keep_track/features/finance/presentation/screens/tabs/debts/debts_tab_new.dart';
import 'package:keep_track/features/finance/presentation/screens/tabs/goals/goals_tab.dart';
import 'package:keep_track/features/finance/presentation/screens/tabs/planned_payments/planned_payments_tab.dart';
import 'package:keep_track/features/home/home_screen.dart';
import 'package:keep_track/features/logs/logs_screen.dart';
import 'package:keep_track/features/module_selection/module_selection_screen.dart';
import 'package:keep_track/features/module_selection/task_module_screen.dart';
import 'package:keep_track/features/profile/presentation/profile_screen.dart';
import 'package:keep_track/features/tasks/presentation/widgets/pomodoro_nav_indicator.dart';

import '../auth/presentation/screens/auth_settings_screen.dart';

/// Finance Module Screen - Wraps the existing finance functionality
/// This is what users see when they select "Finance Management" from module selection
class FinanceModuleScreen extends StatefulWidget {
  const FinanceModuleScreen({super.key});

  @override
  State<FinanceModuleScreen> createState() => _FinanceModuleScreenState();
}

class _FinanceModuleScreenState extends State<FinanceModuleScreen> {
  int _currentIndex = 0;
  final _layoutController = AppLayoutController();

  // All screens including sub-tabs for desktop sidebar
  final List<Widget> _allScreens = const [
    HomeScreen(),
    FinanceMainScreen(), // Index 1 - shown on mobile "Finance" tab
    AccountsTabNew(), // Index 2 - Finance sub-item
    BudgetsTabNew(), // Index 3 - Finance sub-item
    GoalsTabNew(), // Index 4 - Finance sub-item
    DebtsTabNew(), // Index 5 - Finance sub-item
    PlannedPaymentsTabNew(), // Index 6 - Finance sub-item
    LogsScreen(), // Index 7
    ProfileScreen(moduleType: ModuleType.finance), // Index 8
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

  void _navigateToTaskModulePomodoro() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const TaskModuleScreen(initialTabIndex: 3),
      ),
    );
  }

  List<Widget> _buildActions() {
    return [
      // Pomodoro timer indicator (shows when session is active)
      PomodoroNavIndicator(
        onTap: _navigateToTaskModulePomodoro,
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
              arguments: {'mode': 'finance'},
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
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Simple sidebar
          _buildSidebar(),
          // Content
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _allScreens[_currentIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    // Map desktop index to mobile index
    int mobileIndex = _currentIndex;
    if (_currentIndex >= 2 && _currentIndex <= 6) {
      mobileIndex = 1; // All finance sub-tabs map to Finance tab
    } else if (_currentIndex == 7) {
      mobileIndex = 2; // Transactions
    } else if (_currentIndex == 8) {
      mobileIndex = 3; // Profile
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateToModuleSelection,
        ),
        title: Text(_layoutController.title),
        actions: _buildActions(),
      ),
      body: mobileIndex == 1
          ? const FinanceMainScreen()
          : _allScreens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: mobileIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = [0, 1, 7, 8][index];
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Finance',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'Transactions',
          ),
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
          _buildSidebarHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildNavItem('Home', Icons.home, 0),
                _buildNavItem('Finance', Icons.account_balance_wallet, 1),
                _buildSubNavItem('Accounts', Icons.account_balance_wallet, 2),
                _buildSubNavItem('Budgets', Icons.pie_chart, 3),
                _buildSubNavItem('Goals', Icons.flag, 4),
                _buildSubNavItem('Debts', Icons.swap_horiz, 5),
                _buildSubNavItem('Payments', Icons.event_repeat, 6),
                _buildNavItem('Transactions', Icons.history, 7),
                _buildNavItem('Profile', Icons.person, 8),
              ],
            ),
          ),
          _buildSidebarFooter(),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet,
            color: theme.colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Finance',
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
    );
  }

  Widget _buildSidebarFooter() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildUserProfileSection(),
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
        onTap: () => setState(() => _currentIndex = index),
      ),
    );
  }

  Widget _buildSubNavItem(String label, IconData icon, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isActive = _currentIndex == index;
    final activeColor = isDark ? const Color(0xFF27272A) : AppColors.secondary;
    final textColor = theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface;
    final secondaryTextColor = theme.textTheme.bodySmall?.color ?? theme.colorScheme.onSurface.withOpacity(0.6);

    return Container(
      margin: const EdgeInsets.only(bottom: 4, left: 24),
      decoration: BoxDecoration(
        color: isActive ? activeColor : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          size: 18,
          color: isActive ? textColor : secondaryTextColor,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
            color: isActive ? textColor : secondaryTextColor,
          ),
        ),
        onTap: () => setState(() => _currentIndex = index),
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
}
