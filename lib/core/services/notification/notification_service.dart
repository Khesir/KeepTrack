import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:keep_track/core/logging/app_logger.dart';

/// Core notification service for handling local notifications
/// Only initializes on mobile platforms (Android/iOS)
class NotificationService {
  NotificationService._();

  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  FlutterLocalNotificationsPlugin? _plugin;
  bool _initialized = false;

  /// Check if the current platform supports notifications
  bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Check if the service is initialized
  bool get isInitialized => _initialized;

  /// Get the notification plugin (only available on mobile)
  FlutterLocalNotificationsPlugin? get plugin => _plugin;

  /// Initialize the notification service
  /// Safe to call on any platform - will no-op on unsupported platforms
  Future<bool> initialize() async {
    if (!isSupportedPlatform) {
      AppLogger.info('NotificationService: Platform not supported, skipping initialization');
      return false;
    }

    if (_initialized) {
      AppLogger.info('NotificationService: Already initialized');
      return true;
    }

    try {
      // Initialize timezone database
      tz_data.initializeTimeZones();
      final localTimezone = DateTime.now().timeZoneName;
      AppLogger.info('NotificationService: Timezone initialized - $localTimezone');

      // Create plugin instance
      _plugin = FlutterLocalNotificationsPlugin();

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize the plugin
      final success = await _plugin!.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (success == true) {
        _initialized = true;
        AppLogger.info('NotificationService: Initialized successfully');

        // Create notification channels for Android
        await _createNotificationChannels();

        return true;
      } else {
        AppLogger.warning('NotificationService: Initialization returned false');
        return false;
      }
    } catch (e, stackTrace) {
      AppLogger.error('NotificationService: Initialization failed', e, stackTrace);
      return false;
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    AppLogger.info('NotificationService: Notification tapped - ${response.payload}');
    // TODO: Handle navigation based on payload if needed
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid || _plugin == null) return;

    final androidPlugin = _plugin!.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // Finance reminders channel
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'finance_reminders',
        'Finance Reminders',
        description: 'Daily reminders to track your finances',
        importance: Importance.defaultImportance,
      ),
    );

    // Task reminders channel (high priority)
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'task_reminders',
        'Task Reminders',
        description: 'Reminders for your tasks and deadlines',
        importance: Importance.high,
      ),
    );

    // Payment reminders channel (high priority)
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'payment_reminders',
        'Payment Reminders',
        description: 'Reminders for upcoming payments and debt due dates',
        importance: Importance.high,
      ),
    );

    AppLogger.info('NotificationService: Notification channels created');
  }

  /// Show an immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'task_reminders',
  }) async {
    if (!_initialized || _plugin == null) {
      AppLogger.warning('NotificationService: Cannot show notification - not initialized');
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      importance: _isHighPriorityChannel(channelId) ? Importance.high : Importance.defaultImportance,
      priority: _isHighPriorityChannel(channelId) ? Priority.high : Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin!.show(id, title, body, details, payload: payload);
    AppLogger.info('NotificationService: Notification shown - $title');
  }

  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'finance_reminders':
        return 'Finance Reminders';
      case 'task_reminders':
        return 'Task Reminders';
      case 'payment_reminders':
        return 'Payment Reminders';
      default:
        return 'Reminders';
    }
  }

  bool _isHighPriorityChannel(String channelId) {
    return channelId == 'task_reminders' || channelId == 'payment_reminders';
  }

  /// Schedule a notification at a specific time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    String channelId = 'task_reminders',
  }) async {
    if (!_initialized || _plugin == null) {
      AppLogger.warning('NotificationService: Cannot schedule notification - not initialized');
      return;
    }

    // Don't schedule notifications in the past
    if (scheduledTime.isBefore(DateTime.now())) {
      AppLogger.warning('NotificationService: Skipping past notification - $title at $scheduledTime');
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      importance: _isHighPriorityChannel(channelId) ? Importance.high : Importance.defaultImportance,
      priority: _isHighPriorityChannel(channelId) ? Priority.high : Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin!.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    AppLogger.info('NotificationService: Notification scheduled - $title at $scheduledTime');
  }

  /// Schedule a daily repeating notification
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
    String channelId = 'task_reminders',
  }) async {
    if (!_initialized || _plugin == null) {
      AppLogger.warning('NotificationService: Cannot schedule daily notification - not initialized');
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      importance: _isHighPriorityChannel(channelId) ? Importance.high : Importance.defaultImportance,
      priority: _isHighPriorityChannel(channelId) ? Priority.high : Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin!.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );

    AppLogger.info('NotificationService: Daily notification scheduled - $title at $hour:$minute');
  }

  /// Get the next instance of a specific time
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Cancel a notification by ID
  Future<void> cancelNotification(int id) async {
    if (!_initialized || _plugin == null) return;

    try {
      await _plugin!.cancel(id);
      AppLogger.info('NotificationService: Notification cancelled - ID: $id');
    } catch (e, stackTrace) {
      // Handle corrupted notification cache (Missing type parameter error)
      AppLogger.warning(
        'NotificationService: Failed to cancel notification $id, attempting cache clear',
      );
      await _clearNotificationCacheOnError(e, stackTrace);
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!_initialized || _plugin == null) return;

    try {
      await _plugin!.cancelAll();
      AppLogger.info('NotificationService: All notifications cancelled');
    } catch (e, stackTrace) {
      // Handle corrupted notification cache
      AppLogger.warning(
        'NotificationService: Failed to cancel all notifications, attempting cache clear',
      );
      await _clearNotificationCacheOnError(e, stackTrace);
    }
  }

  /// Handle corrupted notification cache by clearing it
  Future<void> _clearNotificationCacheOnError(Object error, StackTrace stackTrace) async {
    AppLogger.error('NotificationService: Notification cache error', error, stackTrace);

    // On Android, try to clear the notification cache
    if (Platform.isAndroid && _plugin != null) {
      try {
        final androidPlugin = _plugin!.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          // Clear all notifications from the system
          await androidPlugin.cancelAll();
          AppLogger.info('NotificationService: Cleared all notifications via Android plugin');
        }
      } catch (e2) {
        AppLogger.error('NotificationService: Could not clear notification cache', e2, stackTrace);
        // The corrupted cache is stored in SharedPreferences
        // User may need to clear app data from device settings
      }
    }
  }
}
