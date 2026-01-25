library;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/theme/theme.dart';
import 'package:keep_track/features/module_selection/module_selection_screen.dart';
import 'package:keep_track/shared/infrastructure/supabase/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/di/di_logger.dart';
import 'core/routing/app_router.dart';
import 'core/migrations/migration_manager.dart';
import 'core/logging/app_logger.dart';
import 'core/logging/log_viewer_screen.dart';
import 'core/settings/data/repositories/settings_repository.dart';
import 'core/settings/domain/entities/app_settings.dart';
import 'core/settings/presentation/settings_controller.dart';
import 'core/state/stream_state.dart';
import 'features/auth/auth.dart';
import 'features/tasks/tasks_di.dart';
import 'features/finance/finance_di.dart';
import 'features/notifications/notifications_di.dart';

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
    const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

    AppLogger.info("SUPABASE_URL length: ${url.length}");
    AppLogger.info("SUPABASE_ANON_KEY length: ${key.length}");
    AppLogger.info("GOOGLE_WEB_CLIENT_ID length: ${googleWebClientId.length}");

    // Runtime checks that work in release builds
    if (url.isEmpty || key.isEmpty) {
      final error =
          'Missing required environment variables!\n'
          'SUPABASE_URL: ${url.isEmpty ? "NOT SET" : "OK"}\n'
          'SUPABASE_ANON_KEY: ${key.isEmpty ? "NOT SET" : "OK"}\n\n'
          'Make sure to pass them via --dart-define:\n'
          'flutter build apk --release --dart-define="PROD=true" '
          '--dart-define="SUPABASE_URL=..." --dart-define="SUPABASE_ANON_KEY=..." '
          '--dart-define="GOOGLE_WEB_CLIENT_ID=..."';
      AppLogger.error(error);
      runApp(_buildErrorScreen(Exception(error), false, false));
      return;
    }

    // Production: Initialize dotenv with dart-define values
    // This ensures AuthService can access dotenv.env without NotInitializedError
    AppLogger.info(
      "Production mode: Initializing dotenv with dart-define values",
    );
    dotenv.testLoad(
      fileInput:
          '''
SUPABASE_URL=$url
SUPABASE_ANON_KEY=$key
GOOGLE_WEB_CLIENT_ID=$googleWebClientId
DEV_BYPASS=false
PROD=true
''',
    );

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

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        // Use PKCE auth flow with loopback redirect for desktop
        // This automatically starts a local server on http://127.0.0.1:PORT for OAuth callbacks
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      AppLogger.info('✅ Supabase initialized with PKCE + loopback redirect');

      // Initialize SharedPreferences
      AppLogger.info('🔧 Initializing SharedPreferences...');
      final sharedPreferences = await SharedPreferences.getInstance();
      AppLogger.info('✅ SharedPreferences initialized');

      // Run database migrations BEFORE setting up dependencies
      final migrationManager = MigrationManager(Supabase.instance.client);
      await migrationManager.runMigrations();

      // Setup app dependencies
      _setupDependencies(sharedPreferences);

      // Initialize notifications (mobile only - safe to call on any platform)
      await initializeNotifications();

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
                        : (isBootstrapError
                              ? Icons.construction
                              : Icons.error_outline),
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    wasNetworkError
                        ? 'Connection Failed'
                        : (isBootstrapError
                              ? 'Setup Required'
                              : 'Failed to Initialize'),
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
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: Colors.orange[700],
                                size: 20,
                              ),
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
void _setupDependencies(SharedPreferences sharedPreferences) {
  // Core Supabase service (shared infrastructure)
  // Note: Supabase is already initialized in main(), we just wrap the client
  locator.registerLazySingleton<SupabaseService>(() {
    return SupabaseService.fromClient(Supabase.instance.client);
  });

  // Core Settings service
  locator.registerSingleton<SharedPreferences>(sharedPreferences);

  locator.registerLazySingleton<SettingsRepository>(() {
    return SettingsRepository(locator.get<SharedPreferences>());
  });

  locator.registerLazySingleton<SettingsController>(() {
    return SettingsController(locator.get<SettingsRepository>());
  });

  // Feature dependencies
  setupAuthDependencies(); // Auth must be first
  setupTasksDependencies();
  setupFinanceDependencies();
  setupNotificationDependencies(); // Mobile only - safe to call on any platform
}

/// Main app widget
class PersonalCodexApp extends StatefulWidget {
  const PersonalCodexApp({super.key});

  @override
  State<PersonalCodexApp> createState() => _PersonalCodexAppState();
}

class _PersonalCodexAppState extends State<PersonalCodexApp> {
  late final SettingsController _settingsController;

  @override
  void initState() {
    super.initState();
    _settingsController = locator.get<SettingsController>();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AsyncState<AppSettings>>(
      stream: _settingsController.stream,
      initialData: _settingsController.state,
      builder: (context, snapshot) {
        // Extract data from AsyncState
        final asyncState = snapshot.data;
        final settings = asyncState is AsyncData<AppSettings>
            ? asyncState.data
            : const AppSettings();

        return MaterialApp(
          // App info
          title: 'Personal Codex',
          debugShowCheckedModeBanner: false,

          // Theme
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode.toThemeMode(),

          // Routing
          onGenerateRoute: AppRouter.onGenerateRoute,

          // Home screen - Module selection after login, protected by auth guard
          home: const AuthGuard(child: ModuleSelectionScreen()),
        );
      },
    );
  }
}

