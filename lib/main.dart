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
import 'core/logging/app_logger.dart';
import 'core/logging/log_viewer_screen.dart';
import 'features/tasks/tasks_di.dart';
import 'features/projects/projects_di.dart';
import 'features/budget/budget_di.dart';
import 'features/tasks/presentation/screens/task_list_screen.dart';
import 'features/projects/presentation/screens/project_list_screen.dart';
import 'features/budget/presentation/screens/budget_list_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Enable DI logging for debugging
  DILogger.enable();

  const isProd = bool.fromEnvironment('PROD', defaultValue: false);
  AppLogger.info("Production mode: $isProd");

  if (isProd) {
    const url = String.fromEnvironment('SUPABASE_URL');
    const key = String.fromEnvironment('SUPABASE_ANON_KEY');

    AppLogger.info("SUPABASE_URL length: ${url.length}");
    AppLogger.info("SUPABASE_ANON_KEY length: ${key.length}");

    // Runtime checks that work in release builds
    if (url.isEmpty || key.isEmpty) {
      final error = 'Missing required environment variables!\n'
          'SUPABASE_URL: ${url.isEmpty ? "NOT SET" : "OK"}\n'
          'SUPABASE_ANON_KEY: ${key.isEmpty ? "NOT SET" : "OK"}\n\n'
          'Make sure to pass them via --dart-define:\n'
          'flutter build apk --release --dart-define="PROD=true" '
          '--dart-define="SUPABASE_URL=..." --dart-define="SUPABASE_ANON_KEY=..."';
      AppLogger.error(error);
      runApp(_buildErrorScreen(Exception(error), false, false));
      return;
    }

    // Production: read from --dart-define
    await _initializeAppWithRetry(supabaseUrl: url, supabaseAnonKey: key);
  } else {
    // Dev: load from assets/.env
    AppLogger.info("Dev mode: Loading from .env file");
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
        AppLogger.info('🚀 Initializing Supabase...');
      } else {
        AppLogger.info('🔄 Retry attempt $retryCount/$maxRetries...');
      }

      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
      AppLogger.info('✅ Supabase initialized');

      // Run database migrations BEFORE setting up dependencies
      final migrationManager = MigrationManager(Supabase.instance.client);
      await migrationManager.runMigrations();

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
        AppLogger.warning('⚠️  Network error', e);
        AppLogger.info(
          '⏳ Retrying in ${delay.inSeconds} seconds... ($retryCount/$maxRetries)',
        );

        // Show loading screen with retry info
        runApp(_buildRetryingScreen(retryCount, maxRetries, delay));

        await Future.delayed(delay);
        continue; // Retry
      } else {
        // Non-network error or max retries reached
        AppLogger.error('❌ Failed to initialize app', e, stackTrace);

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
    home: Builder(
      builder: (context) => Scaffold(
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
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LogViewerScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bug_report),
                  label: const Text('View Logs'),
                ),
              ],
            ),
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
  final isBootstrapError = error.toString().contains('bootstrap');

  return MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    wasNetworkError
                        ? Icons.wifi_off
                        : (isBootstrapError ? Icons.construction : Icons.error_outline),
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    wasNetworkError
                        ? 'Connection Failed'
                        : (isBootstrapError ? 'Setup Required' : 'Failed to Initialize'),
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (isBootstrapError) ...[
                    // Bootstrap-specific instructions
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb_outline,
                                  color: Colors.orange[700], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Setup Required',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Your Supabase database needs to be initialized.\n\n'
                            'Steps to fix:\n'
                            '1. Open your Supabase dashboard\n'
                            '2. Go to SQL Editor → New Query\n'
                            '3. Copy & paste supabase/bootstrap.sql\n'
                            '4. Click "Run" or press Ctrl+Enter\n'
                            '5. Restart this app',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // General instructions
                    Text(
                      wasNetworkError
                          ? 'Please check:\n'
                                '• Internet connection is available\n'
                                '• WiFi/Mobile data is enabled\n'
                                '• Server is reachable\n\n'
                                'The app will restart when connection is restored.'
                          : 'Please check:\n'
                                '• Supabase credentials are correct\n'
                                '• Database schema is set up\n'
                                '• Bootstrap script was run',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LogViewerScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bug_report),
                    label: const Text('View Detailed Logs'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                // Other actions from layout controller
                if (_layoutController.actions != null)
                  ..._layoutController.actions!,
              ],
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
