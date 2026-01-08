import 'package:flutter/material.dart';
import 'package:keep_track/core/logging/log_viewer_screen.dart';
import 'package:keep_track/core/ui/app_layout_controller.dart';
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

  final List<Widget> _screens = const [
    HomeScreen(),
    FinanceMainScreen(),
    LogsScreen(),
    ProfileScreen(moduleType: ModuleType.finance),
  ];

  @override
  void dispose() {
    _layoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLayoutProvider(
      controller: _layoutController,
      child: AnimatedBuilder(
        animation: _layoutController,
        builder: (context, child) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  // Go back to module selection
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ModuleSelectionScreen(),
                    ),
                  );
                },
                tooltip: 'Back to Module Selection',
              ),
              title: Text(_layoutController.title),
              actions: [
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
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/settings',
                          arguments: {'mode': 'finance'},
                        );
                      },
                    ),
                  ),
                // Other actions from layout controller
                ..._layoutController.actions,
              ],
            ),
            body: _screens[_currentIndex],
            bottomNavigationBar: _layoutController.showBottomNav
                ? NavigationBar(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: (index) {
                      setState(() => _currentIndex = index);
                    },
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.account_balance_wallet),
                        label: 'Finance',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.history),
                        label: 'Transactions',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.person),
                        label: 'Profile',
                      ),
                    ],
                  )
                : null,
          );
        },
      ),
    );
  }
}
