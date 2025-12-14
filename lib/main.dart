/// Personal Codex - Main Entry Point
///
/// Multi-feature app with Clean Architecture:
/// - Custom DI System
/// - Custom State Management (StreamState)
/// - Custom Error Handling
/// - Feature-based organization
library;

import 'package:flutter/material.dart';
import 'package:persona_codex/core/di/service_locator.dart';
import 'package:persona_codex/shared/infrastructure/mongodb/mongodb_service.dart';
import 'core/di/di_logger.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/tasks/tasks_di.dart';
import 'features/projects/projects_di.dart';
import 'features/budget/budget_di.dart';
import 'features/tasks/presentation/screens/task_list_screen.dart';
import 'features/projects/presentation/project_list_screen.dart';
import 'features/budget/presentation/screens/budget_list_screen.dart';

void main() {
  // Enable DI logging for debugging
  DILogger.enable();

  // Setup dependencies
  _setupDependencies();

  runApp(const PersonalCodexApp());
}

/// Setup all dependencies
void _setupDependencies() {
  // Core MongoDB service (shared infrastructure)
  locator.registerLazySingleton<MongoDBService>(() {
    final service = MongoDBService(
      connectionString: 'mongodb://localhost:27017',
      databaseName: 'personal_codex',
    );
    // Connect on first access
    service.connect();
    return service;
  });

  // Feature dependencies
  setupTasksDependencies();
  setupProjectsDependencies();
  setupBudgetDependencies();
}

/// Main app widget
class PersonalCodexApp extends StatelessWidget {
  const PersonalCodexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // App info
      title: 'Personal Codex',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Follow system theme

      // Routing
      onGenerateRoute: AppRouter.onGenerateRoute,

      // Home screen (bottom nav with tabs)
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
