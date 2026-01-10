import 'package:flutter/material.dart';
import 'package:keep_track/core/logging/log_viewer_screen.dart';
import 'package:keep_track/core/theme/app_theme.dart';
import 'package:keep_track/core/ui/app_layout_controller.dart';
import 'package:keep_track/core/ui/responsive/responsive_breakpoints.dart';
import 'package:keep_track/features/finance/presentation/screens/finance_main_screen.dart';
import 'package:keep_track/features/finance/presentation/screens/tabs/accounts/accounts_tab_new.dart';
import 'package:keep_track/features/finance/presentation/screens/tabs/budgets/budgets_tab_new.dart';
import 'package:keep_track/features/finance/presentation/screens/tabs/debts/debts_tab_new.dart';
import 'package:keep_track/features/finance/presentation/screens/tabs/goals/goals_tab.dart';
import 'package:keep_track/features/finance/presentation/screens/tabs/planned_payments/planned_payments_tab.dart';
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

  // All screens including sub-tabs for desktop sidebar
  final List<Widget> _allScreens = const [
    HomeScreen(),
    FinanceMainScreen(), // Index 1 - shown on mobile "Finance" tab
    AccountsTabNew(),    // Index 2 - Finance sub-item
    BudgetsTabNew(),     // Index 3 - Finance sub-item
    GoalsTabNew(),       // Index 4 - Finance sub-item
    DebtsTabNew(),       // Index 5 - Finance sub-item
    PlannedPaymentsTabNew(), // Index 6 - Finance sub-item
    LogsScreen(),        // Index 7
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
              icon: Icon(Icons.account_balance_wallet), label: 'Finance'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Transactions'),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Finance', style: AppTextStyles.h4),
              Text('Management', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return InkWell(
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
        onTap: () => setState(() => _currentIndex = index),
      ),
    );
  }

  Widget _buildSubNavItem(String label, IconData icon, int index) {
    final isActive = _currentIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 4, left: 24),
      decoration: BoxDecoration(
        color: isActive ? AppColors.secondary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, size: 18,
            color: isActive ? AppColors.textPrimary : AppColors.textSecondary),
        title: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                color: isActive ? AppColors.textPrimary : AppColors.textSecondary)),
        onTap: () => setState(() => _currentIndex = index),
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
}
