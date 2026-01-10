import 'package:flutter/material.dart';
import 'package:keep_track/core/logging/log_viewer_screen.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/app_layout_controller.dart';
import 'package:keep_track/core/ui/responsive/desktop_sidebar.dart';
import 'package:keep_track/core/ui/responsive/responsive_layout_wrapper.dart';
import 'package:keep_track/features/finance/presentation/screens/finance_main_screen.dart';
import 'package:keep_track/features/home/home_screen.dart';
import 'package:keep_track/features/logs/logs_screen.dart';
import 'package:keep_track/features/module_selection/module_selection_screen.dart';
import 'package:keep_track/features/profile/presentation/profile_screen.dart';

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

  // Navigation items for both mobile and desktop
  List<ResponsiveNavItem> get _navItems => const [
        ResponsiveNavItem(
          label: 'Home',
          icon: Icons.home,
          screen: HomeScreen(),
        ),
        ResponsiveNavItem(
          label: 'Finance',
          icon: Icons.account_balance_wallet,
          screen: FinanceMainScreen(),
        ),
        ResponsiveNavItem(
          label: 'Transactions',
          icon: Icons.history,
          screen: LogsScreen(),
        ),
        ResponsiveNavItem(
          label: 'Profile',
          icon: Icons.person,
          screen: ProfileScreen(moduleType: ModuleType.finance),
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
          return ResponsiveLayoutWrapper(
            config: ResponsiveLayoutConfig(
              navItems: _navItems,
              currentIndex: _currentIndex,
              onNavIndexChanged: (index) {
                setState(() => _currentIndex = index);
              },
              title: _layoutController.title,
              actions: _buildActions(),
              sidebarHeader: const SidebarHeader(
                title: 'Finance',
                subtitle: 'Management',
                leading: Icon(
                  Icons.account_balance_wallet,
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
              floatingActionButton: null,
            ),
          );
        },
      ),
    );
  }
}
