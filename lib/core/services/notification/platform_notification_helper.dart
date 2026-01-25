import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'package:keep_track/core/logging/app_logger.dart';

/// Helper class for handling notification permissions across platforms
class PlatformNotificationHelper {
  PlatformNotificationHelper._();

  static final PlatformNotificationHelper _instance =
      PlatformNotificationHelper._();
  static PlatformNotificationHelper get instance => _instance;

  /// Check if the current platform supports notifications
  bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Request notification permissions
  /// Returns true if permissions were granted
  Future<bool> requestPermissions() async {
    if (!isSupportedPlatform) {
      AppLogger.info('Notifications: Platform not supported, skipping permission request');
      return false;
    }

    try {
      // Request notification permission (Android 13+ and iOS)
      final notificationStatus = await Permission.notification.request();
      AppLogger.info('Notifications: Permission status - $notificationStatus');

      if (notificationStatus.isGranted) {
        // Also request exact alarm permission on Android for scheduled notifications
        if (Platform.isAndroid) {
          final alarmStatus = await Permission.scheduleExactAlarm.request();
          AppLogger.info('Notifications: Exact alarm permission - $alarmStatus');
        }
        return true;
      }

      if (notificationStatus.isPermanentlyDenied) {
        AppLogger.warning('Notifications: Permission permanently denied');
      }

      return false;
    } catch (e) {
      AppLogger.error('Notifications: Error requesting permissions', e);
      return false;
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (!isSupportedPlatform) return false;

    try {
      final status = await Permission.notification.status;
      return status.isGranted;
    } catch (e) {
      AppLogger.error('Notifications: Error checking permission status', e);
      return false;
    }
  }

  /// Open app notification settings
  Future<bool> openNotificationSettings() async {
    if (!isSupportedPlatform) return false;

    try {
      return await openAppSettings();
    } catch (e) {
      AppLogger.error('Notifications: Error opening settings', e);
      return false;
    }
  }
}
