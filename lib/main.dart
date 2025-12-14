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
import 'package:persona_codex/core/ui/app_layout_controller.dart';
import 'package:persona_codex/shared/infrastructure/supabase/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/di/di_logger.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/migrations/migration_manager.dart';
import 'features/tasks/tasks_di.dart';
import 'features/projects/projects_di.dart';
import 'features/budget/budget_di.dart';
import 'features/tasks/presentation/screens/task_list_screen.dart';
import 'features/projects/presentation/project_list_screen.dart';
import 'features/budget/presentation/screens/budget_list_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Enable DI logging for debugging
  DILogger.enable();

  try {
    // Initialize Supabase
    print('🚀 Initializing Supabase...');
    await Supabase.initialize(url: 'url', anonKey: 'anon_key');
    print('✅ Supabase initialized');

    // Run database migrations BEFORE setting up dependencies
    print('');
    final migrationManager = MigrationManager(Supabase.instance.client);
    await migrationManager.runMigrations();
    print('');

    // Setup app dependencies
    _setupDependencies();

    // Run the app
    runApp(const PersonalCodexApp());
  } catch (e, stackTrace) {
    print('');
    print('❌ Failed to initialize app: $e');
    print(stackTrace);

    // Show error screen
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to Initialize',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Please check:\n'
                    '1. Supabase credentials are correct\n'
                    '2. Database schema is set up\n'
                    '3. Internet connection is available',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Setup all dependencies
void _setupDependencies() {
  // Core Supabase service (shared infrastructure)
  // Note: Supabase is already initialized in main(), we just wrap the client
  locator.registerLazySingleton<SupabaseService>(() {
    return SupabaseService.fromClient(Supabase.instance.client);
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
  final _layoutController = AppLayoutController();
  final List<Widget> _screens = const [
    TaskListScreen(),
    ProjectListScreen(),
    BudgetListScreen(),
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
              title: Text(_layoutController.title),
              actions: _layoutController.actions,
            ),
            body: _screens[_currentIndex],
            floatingActionButton: _layoutController.floatingActionButton,
            bottomNavigationBar: _layoutController.showBottomNav
                ? NavigationBar(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: (index) {
                      setState(() => _currentIndex = index);
                    },
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.task_alt),
                        label: 'Tasks',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.folder),
                        label: 'Projects',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.account_balance_wallet),
                        label: 'Budget',
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
