library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:keep_track/core/cache/cache_factory.dart';
import 'package:keep_track/core/cache/local_cache.dart';
import 'package:keep_track/core/cache/local_migration_runner.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/core/theme/theme.dart';
import 'package:keep_track/features/module_selection/finance_module_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/di/di_logger.dart';
import 'core/restart/app_restart_widget.dart';
import 'core/navigation/app_navigator.dart';
import 'core/routing/app_router.dart';
import 'core/ui/desktop_title_bar.dart';
import 'core/settings/data/repositories/settings_repository.dart';
import 'core/settings/domain/entities/app_settings.dart';
import 'core/settings/presentation/settings_controller.dart';
import 'core/state/stream_state.dart';
import 'features/auth/auth.dart';
import 'features/finance/finance_di.dart';
import 'features/inbox/api.dart';
import 'features/notifications/notifications_di.dart';
import 'features/settings/settings_di.dart';

late SharedPreferences _sharedPrefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      titleBarStyle: TitleBarStyle.hidden,
      minimumSize: Size(940, 600),
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  if (kDebugMode) DILogger.enable();

  // Initialize Hive for local cache (mobile/desktop only)
  await Hive.initFlutter();

  // Initialize SharedPreferences
  _sharedPrefs = await SharedPreferences.getInstance();

  // Run local schema migrations before any feature code touches the cache
  final cache = createLocalCache();
  await LocalMigrationRunner(cache, _sharedPrefs).run();

  // Setup app dependencies
  _setupDependencies(_sharedPrefs, cache);

  // Initialize notifications (mobile only — safe to call on any platform)
  await initializeNotifications();

  runApp(AppRestartWidget(
    onRestart: reinitializeDependencies,
    child: const PersonalCodexApp(),
  ));
}

void reinitializeDependencies() {
  locator.reset();
  _setupDependencies(_sharedPrefs, createLocalCache());
}

/// Setup all dependencies
void _setupDependencies(SharedPreferences sharedPreferences, LocalCache cache) {
  // Core local cache
  locator.registerSingleton<LocalCache>(cache);

  // Core settings
  locator.registerSingleton<SharedPreferences>(sharedPreferences);
  locator.registerLazySingleton<SettingsRepository>(
    () => SettingsRepository(locator.get<SharedPreferences>()),
  );
  locator.registerLazySingleton<SettingsController>(
    () => SettingsController(locator.get<SettingsRepository>()),
  );

  // Feature dependencies
  setupAuthDependencies(); // Auth must be first
  setupFinanceDependencies();
  setupInboxDependencies();
  setupNotificationDependencies();
  setupSettingsDependencies();
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
        final asyncState = snapshot.data;
        final settings = asyncState is AsyncData<AppSettings>
            ? asyncState.data
            : const AppSettings();

        return MaterialApp(
          title: 'Keep Track',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode.toThemeMode(),
          navigatorKey: AppNavigator.key,
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const AuthGuard(child: FinanceModuleScreen()),
          builder: (context, child) {
            if (!kIsWeb && DesktopTitleBar.isDesktopPlatform) {
              return Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (_) => Column(
                      children: [
                        const DesktopTitleBar(),
                        Expanded(child: child ?? const SizedBox()),
                      ],
                    ),
                  ),
                ],
              );
            }
            return child ?? const SizedBox();
          },
        );
      },
    );
  }
}

