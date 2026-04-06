# Changelog

All notable changes to Keep Track will be documented in this page.

## [Unreleased]

### Fixed

#### Notification Settings Screen Error
- **Issue**: Opening the Notification Settings screen would display "Error loading settings" with a `PlatformException: Missing type parameter` error
- **Cause**: The `flutter_local_notifications` plugin's internal cache (stored in SharedPreferences) became corrupted, containing notification data with missing required fields
- **Solution**: Added error handling in the notification service to gracefully catch and recover from corrupted notification cache errors
- **Files Changed**:
  - `lib/core/services/notification/notification_service.dart` - Added try-catch around `cancelNotification()` and `cancelAllNotifications()` methods
  - `lib/features/notifications/presentation/state/notification_settings_controller.dart` - Added error handling in `_applySettings()` to prevent settings load failures

**Workaround for existing users**: If you still experience issues after updating, clear the app data from your device settings (Settings > Apps > Keep Track > Storage > Clear Data). This will reset the corrupted notification cache.

---

## [0.7.4] - 2025-01-25

### Added
- Build workflow updates
- Local version updates for workflows

### Fixed
- Navigation counter bug for pomodoro
- Removed unnecessary assets and fixed security risk issue on workflow

---

## Previous Releases

For older releases, please check the [GitHub Releases](https://github.com/Khesir/KeepTrack/releases) page.
