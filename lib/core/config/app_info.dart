import 'package:flutter/foundation.dart';

/// Application information and configuration
class AppInfo {
  AppInfo._();

  static const String _prodBase = 'https://keep-track.khesir.com';
  static const String _devBase = 'http://localhost:3001';
  static String get _landingBase => kDebugMode ? _devBase : _prodBase;

  /// GitHub repository owner
  static const String gitHubOwner = 'khesir';

  /// GitHub repository name
  static const String gitHubRepo = 'KeepTrack';

  /// Full GitHub repository path
  static String get gitHubRepoPath => '$gitHubOwner/$gitHubRepo';

  /// Primary download URL for app updates
  static String get downloadUrl => '$_landingBase/download';

  /// Announcements page URL
  static String get announcementsUrl => '$_landingBase/announcements';

  /// GitHub releases URL (fallback)
  static String get releasesUrl =>
      'https://github.com/$gitHubOwner/$gitHubRepo/releases';

  /// GitHub API URL for latest release
  static String get latestReleaseApiUrl =>
      'https://api.github.com/repos/$gitHubOwner/$gitHubRepo/releases/latest';
}
