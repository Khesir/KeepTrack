/// Main screen with bottom navigation
library;

import 'package:flutter/material.dart';
import '../../features/tasks/presentation/screens/task_list_screen.dart';
import '../../features/projects/presentation/screens/project_list_screen.dart';
import '../../features/budget/presentation/screens/budget_list_screen.dart';

/// Main screen with bottom navigation bar
/// Switches between Tasks, Projects, and Budget
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    TaskListScreen(),
    ProjectListScreen(),
    BudgetListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.task_alt), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.folder), label: 'Projects'),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Budget',
          ),
        ],
      ),
    );
  }
}
