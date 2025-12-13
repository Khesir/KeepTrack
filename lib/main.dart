/// Example App - Task Management
///
/// Shows how to use the DI system with task management feature
library;

import 'package:flutter/material.dart';
import 'core/di/service_locator.dart';
import 'core/di/di_logger.dart';
import 'features/tasks/tasks_di.dart';
import 'features/budget/budget_di.dart';
import 'features/tasks/presentation/screens/task_list_screen.dart';
import 'features/tasks/presentation/screens/project_list_screen.dart';
import 'features/budget/presentation/screens/budget_list_screen.dart';

void main() {
  // Enable DI logging for debugging
  DILogger.enable();

  // Setup dependencies
  setupTasksDependencies();
  setupBudgetDependencies();

  runApp(const TaskManagementApp());
}

class TaskManagementApp extends StatelessWidget {
  const TaskManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Codex',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const MainScreen(),
    );
  }
}

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
