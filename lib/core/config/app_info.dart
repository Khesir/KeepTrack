/// Application information and configuration
class AppInfo {
  AppInfo._();

  /// GitHub repository owner
  static const String gitHubOwner = 'khesir';

  /// GitHub repository name
  static const String gitHubRepo = 'KeepTrack';

  /// Full GitHub repository path
  static String get gitHubRepoPath => '$gitHubOwner/$gitHubRepo';

  /// Primary download URL for app updates
  static const String downloadUrl = 'https://keep-track.khesir.com/download';

  /// GitHub releases URL (fallback)
  static String get releasesUrl =>
      'https://github.com/$gitHubOwner/$gitHubRepo/releases';

  /// GitHub API URL for latest release
  static String get latestReleaseApiUrl =>
      'https://api.github.com/repos/$gitHubOwner/$gitHubRepo/releases/latest';
}
