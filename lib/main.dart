/// Personal Codex - Main Entry Point
///
/// Multi-feature app with Clean Architecture:
/// - Custom DI System
/// - Custom State Management (StreamState)
/// - Custom Error Handling
/// - Feature-based organization
library;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
import 'features/projects/presentation/screens/project_list_screen.dart';
import 'features/budget/presentation/screens/budget_list_screen.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Enable DI logging for debugging
  DILogger.enable();

  const isProd = bool.fromEnvironment('PROD', defaultValue: false);

  if (isProd) {
    // Production: read from --dart-define
    await _initializeAppWithRetry(
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    );
  } else {
    // Dev: load from assets/.env
    await dotenv.load(fileName: '.env');
    await _initializeAppWithRetry(
      supabaseUrl: dotenv.env['SUPABASE_URL']!,
      supabaseAnonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }
}

Future<void> loadEnv() async {
  await dotenv.load(fileName: 'assets/.env');
}

/// Initialize app with automatic retry on network errors
Future<void> _initializeAppWithRetry({
  required String supabaseUrl,
  required String supabaseAnonKey,
}) async {
  const maxRetries = 5;
  const initialDelay = Duration(seconds: 2);
  int retryCount = 0;
  while (true) {
    try {
      // Initialize Supabase
      if (retryCount == 0) {
        print('🚀 Initializing Supabase...');
      } else {
        print('🔄 Retry attempt $retryCount/$maxRetries...');
      }

      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
      print('✅ Supabase initialized');

      // Run database migrations BEFORE setting up dependencies
      print('');
      final migrationManager = MigrationManager(Supabase.instance.client);
      await migrationManager.runMigrations();
      print('');

      // Setup app dependencies
      _setupDependencies();

      // Run the app - SUCCESS!
      runApp(const PersonalCodexApp());
      return; // Exit the retry loop
    } catch (e, stackTrace) {
      final isNetworkError = _isNetworkError(e);

      if (isNetworkError && retryCount < maxRetries) {
        // Network error - retry with exponential backoff
        retryCount++;
        final delay =
            initialDelay * (1 << (retryCount - 1)); // Exponential backoff
        print('');
        print('⚠️  Network error: $e');
        print(
          '⏳ Retrying in ${delay.inSeconds} seconds... ($retryCount/$maxRetries)',
        );
        print('');

        // Show loading screen with retry info
        runApp(_buildRetryingScreen(retryCount, maxRetries, delay));

        await Future.delayed(delay);
        continue; // Retry
      } else {
        // Non-network error or max retries reached
        print('');
        print('❌ Failed to initialize app: $e');
        print(stackTrace);

        // Show error screen
        runApp(_buildErrorScreen(e, isNetworkError, retryCount >= maxRetries));
        return; // Stop retrying
      }
    }
  }
}

/// Check if error is network-related
bool _isNetworkError(dynamic error) {
  final errorString = error.toString().toLowerCase();
  return errorString.contains('network') ||
      errorString.contains('socket') ||
      errorString.contains('connection') ||
      errorString.contains('timeout') ||
      errorString.contains('failed host lookup') ||
      errorString.contains('unreachable');
}

/// Build retry screen
Widget _buildRetryingScreen(int retryCount, int maxRetries, Duration delay) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              const Text(
                'Connecting to Server...',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Network error detected',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Retry attempt $retryCount of $maxRetries',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Retrying in ${delay.inSeconds} seconds...',
                style: TextStyle(
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Build error screen
Widget _buildErrorScreen(
  dynamic error,
  bool wasNetworkError,
  bool maxRetriesReached,
) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                wasNetworkError ? Icons.wifi_off : Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                wasNetworkError ? 'Connection Failed' : 'Failed to Initialize',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (maxRetriesReached) ...[
                const Text(
                  'Max retry attempts reached',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Text(
                wasNetworkError
                    ? 'Please check:\n'
                          '1. Internet connection is available\n'
                          '2. WiFi/Mobile data is enabled\n'
                          '3. Server is reachable\n\n'
                          'The app will restart automatically when connection is restored.'
                    : 'Please check:\n'
                          '1. Supabase credentials are correct\n'
                          '2. Database schema is set up\n'
                          '3. Bootstrap script was run',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
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
                        icon: Icon(Icons.inventory_2_outlined),
                        selectedIcon: Icon(Icons.inventory_2),
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
