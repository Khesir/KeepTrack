import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:keep_track/core/logging/app_logger.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  FlutterLocalNotificationsPlugin? _plugin;
  bool _initialized = false;

  // Windows uses Timers for scheduling since flutter_local_notifications doesn't support Windows
  final Map<int, Timer> _windowsTimers = {};

  bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS || Platform.isWindows;
  }

  bool get isInitialized => _initialized;

  FlutterLocalNotificationsPlugin? get plugin => _plugin;

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
      if (Platform.isWindows) {
        await localNotifier.setup(appName: 'Keep Track');
        _initialized = true;
        AppLogger.info('NotificationService: Windows notifications initialized');
        return true;
      }

      // Initialize timezone database (Android/iOS)
      tz_data.initializeTimeZones();
      try {
        final localTimezone = DateTime.now().timeZoneName;
        tz.setLocalLocation(tz.getLocation(localTimezone));
        AppLogger.info('NotificationService: Timezone set to $localTimezone');
      } catch (e) {
        AppLogger.warning('NotificationService: Could not set local timezone, defaulting to UTC');
      }

      _plugin = FlutterLocalNotificationsPlugin();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final success = await _plugin!.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (success == true) {
        _initialized = true;
        AppLogger.info('NotificationService: Initialized successfully');
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

  void _onNotificationTapped(NotificationResponse response) {
    AppLogger.info('NotificationService: Notification tapped - ${response.payload}');
  }

  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid || _plugin == null) return;

    final androidPlugin = _plugin!.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'finance_reminders',
        'Finance Reminders',
        description: 'Daily reminders to track your finances',
        importance: Importance.defaultImportance,
      ),
    );

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        'task_reminders',
        'Task Reminders',
        description: 'Reminders for your tasks and deadlines',
        importance: Importance.high,
      ),
    );

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

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String channelId = 'task_reminders',
  }) async {
    if (!_initialized) {
      AppLogger.warning('NotificationService: Cannot show notification - not initialized');
      return;
    }

    if (Platform.isWindows) {
      await _showWindowsNotification(id: id, title: title, body: body);
      return;
    }

    if (_plugin == null) return;

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

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _plugin!.show(id, title, body, details, payload: payload);
    AppLogger.info('NotificationService: Notification shown - $title');
  }

  Future<void> _showWindowsNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    final notification = LocalNotification(
      identifier: id.toString(),
      title: title,
      body: body,
    );
    await notification.show();
    AppLogger.info('NotificationService: Windows notification shown - $title');
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

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    String channelId = 'task_reminders',
  }) async {
    if (!_initialized) {
      AppLogger.warning('NotificationService: Cannot schedule notification - not initialized');
      return;
    }

    if (scheduledTime.isBefore(DateTime.now())) {
      AppLogger.warning('NotificationService: Skipping past notification - $title at $scheduledTime');
      return;
    }

    if (Platform.isWindows) {
      final delay = scheduledTime.difference(DateTime.now());
      _windowsTimers[id]?.cancel();
      _windowsTimers[id] = Timer(delay, () async {
        await _showWindowsNotification(id: id, title: title, body: body);
        _windowsTimers.remove(id);
      });
      AppLogger.info('NotificationService: Windows notification scheduled - $title at $scheduledTime');
      return;
    }

    if (_plugin == null) return;

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

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

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

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
    String channelId = 'task_reminders',
  }) async {
    if (!_initialized) {
      AppLogger.warning('NotificationService: Cannot schedule daily notification - not initialized');
      return;
    }

    if (Platform.isWindows) {
      _scheduleWindowsDaily(id: id, title: title, body: body, hour: hour, minute: minute);
      AppLogger.info('NotificationService: Windows daily notification scheduled - $title at $hour:$minute');
      return;
    }

    if (_plugin == null) return;

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

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

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

  void _scheduleWindowsDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) {
    _windowsTimers[id]?.cancel();

    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour, minute);
    if (next.isBefore(now)) next = next.add(const Duration(days: 1));

    _windowsTimers[id] = Timer(next.difference(now), () async {
      await _showWindowsNotification(id: id, title: title, body: body);
      // Reschedule for the next day
      _scheduleWindowsDaily(id: id, title: title, body: body, hour: hour, minute: minute);
    });
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> cancelNotification(int id) async {
    if (!_initialized) return;

    if (Platform.isWindows) {
      _windowsTimers[id]?.cancel();
      _windowsTimers.remove(id);
      AppLogger.info('NotificationService: Windows notification cancelled - ID: $id');
      return;
    }

    if (_plugin == null) return;

    try {
      await _plugin!.cancel(id);
      AppLogger.info('NotificationService: Notification cancelled - ID: $id');
    } catch (e, stackTrace) {
      AppLogger.warning(
        'NotificationService: Failed to cancel notification $id, attempting cache clear',
      );
      await _clearNotificationCacheOnError(e, stackTrace);
    }
  }

  Future<void> cancelAllNotifications() async {
    if (!_initialized) return;

    if (Platform.isWindows) {
      for (final timer in _windowsTimers.values) {
        timer.cancel();
      }
      _windowsTimers.clear();
      AppLogger.info('NotificationService: All Windows notifications cancelled');
      return;
    }

    if (_plugin == null) return;

    try {
      await _plugin!.cancelAll();
      AppLogger.info('NotificationService: All notifications cancelled');
    } catch (e, stackTrace) {
      AppLogger.warning(
        'NotificationService: Failed to cancel all notifications, attempting cache clear',
      );
      await _clearNotificationCacheOnError(e, stackTrace);
    }
  }

  Future<void> _clearNotificationCacheOnError(Object error, StackTrace stackTrace) async {
    AppLogger.error('NotificationService: Notification cache error', error, stackTrace);

    if (Platform.isAndroid && _plugin != null) {
      try {
        final androidPlugin = _plugin!.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          await androidPlugin.cancelAll();
          AppLogger.info('NotificationService: Cleared all notifications via Android plugin');
        }
      } catch (e2) {
        AppLogger.error('NotificationService: Could not clear notification cache', e2, stackTrace);
      }
    }
  }
}
