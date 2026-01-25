import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:keep_track/core/config/app_info.dart';
import 'package:keep_track/core/logging/app_logger.dart';

/// Result of a version check
class VersionCheckResult {
  final bool updateAvailable;
  final String currentVersion;
  final String? latestVersion;
  final String? releaseUrl;
  final String? releaseNotes;
  final String? error;

  const VersionCheckResult({
    required this.updateAvailable,
    required this.currentVersion,
    this.latestVersion,
    this.releaseUrl,
    this.releaseNotes,
    this.error,
  });

  factory VersionCheckResult.noUpdate(String currentVersion) {
    return VersionCheckResult(
      updateAvailable: false,
      currentVersion: currentVersion,
    );
  }

  factory VersionCheckResult.error(String currentVersion, String error) {
    return VersionCheckResult(
      updateAvailable: false,
      currentVersion: currentVersion,
      error: error,
    );
  }
}

/// Service for checking app version against GitHub releases
class VersionCheckerService {
  VersionCheckerService._();

  static final VersionCheckerService _instance = VersionCheckerService._();
  static VersionCheckerService get instance => _instance;

  /// Check if a newer version is available on GitHub
  Future<VersionCheckResult> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      AppLogger.info('Version Check: Current version is $currentVersion');

      final response = await http
          .get(
            Uri.parse(AppInfo.latestReleaseApiUrl),
            headers: {'Accept': 'application/vnd.github.v3+json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final tagName = data['tag_name'] as String?;
        final htmlUrl = data['html_url'] as String?;
        final body = data['body'] as String?;

        if (tagName == null) {
          AppLogger.warning('Version Check: No tag_name in response');
          return VersionCheckResult.noUpdate(currentVersion);
        }

        // Remove 'v' prefix if present (e.g., v0.7.4 -> 0.7.4)
        final latestVersion = tagName.startsWith('v')
            ? tagName.substring(1)
            : tagName;

        AppLogger.info('Version Check: Latest version is $latestVersion');

        final isNewer = _isNewerVersion(currentVersion, latestVersion);

        if (isNewer) {
          AppLogger.info('Version Check: Update available!');
          return VersionCheckResult(
            updateAvailable: true,
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            releaseUrl: htmlUrl ?? AppInfo.releasesUrl,
            releaseNotes: body,
          );
        }

        return VersionCheckResult.noUpdate(currentVersion);
      } else if (response.statusCode == 404) {
        AppLogger.info('Version Check: No releases found on GitHub');
        return VersionCheckResult.noUpdate(currentVersion);
      } else {
        AppLogger.warning(
          'Version Check: Failed with status ${response.statusCode}',
        );
        return VersionCheckResult.error(
          currentVersion,
          'GitHub API returned status ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.error('Version Check: Error - $e');
      final packageInfo = await PackageInfo.fromPlatform();
      return VersionCheckResult.error(
        packageInfo.version,
        e.toString(),
      );
    }
  }

  /// Compare two semantic versions
  /// Returns true if latestVersion is newer than currentVersion
  bool _isNewerVersion(String current, String latest) {
    try {
      // Strip any pre-release or build metadata for comparison
      // e.g., "0.7.3-alpha.4+38" -> "0.7.3"
      final currentBase = _extractBaseVersion(current);
      final latestBase = _extractBaseVersion(latest);

      // Validate that both versions contain only numeric parts
      final currentParts = _parseVersionParts(currentBase);
      final latestParts = _parseVersionParts(latestBase);

      if (currentParts == null || latestParts == null) {
        AppLogger.warning(
          'Version Check: Cannot compare non-semantic versions: $current vs $latest',
        );
        return false;
      }

      // Pad shorter version with zeros
      while (currentParts.length < 3) {
        currentParts.add(0);
      }
      while (latestParts.length < 3) {
        latestParts.add(0);
      }

      // Compare major.minor.patch
      for (var i = 0; i < 3; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }

      // Base versions are equal, check pre-release
      // A release version is newer than a pre-release of the same base
      final currentHasPreRelease = current.contains('-');
      final latestHasPreRelease = latest.contains('-');

      if (currentHasPreRelease && !latestHasPreRelease) {
        // Current is pre-release, latest is stable -> update available
        return true;
      }

      return false;
    } catch (e) {
      AppLogger.error('Version comparison error: $e');
      return false;
    }
  }

  /// Extract base version (major.minor.patch) from full version string
  String _extractBaseVersion(String version) {
    // Remove pre-release suffix (e.g., -alpha.4)
    var base = version.split('-').first;
    // Remove build metadata (e.g., +38)
    base = base.split('+').first;
    return base;
  }

  /// Parse version string into numeric parts, returns null if invalid
  List<int>? _parseVersionParts(String version) {
    final parts = version.split('.');
    final result = <int>[];

    for (final part in parts) {
      final number = int.tryParse(part);
      if (number == null) {
        return null; // Non-numeric part found
      }
      result.add(number);
    }

    return result.isEmpty ? null : result;
  }
}
