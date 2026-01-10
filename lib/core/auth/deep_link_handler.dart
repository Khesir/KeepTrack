import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles deep link authentication callbacks for desktop platforms
class DeepLinkHandler {
  static final DeepLinkHandler _instance = DeepLinkHandler._internal();
  factory DeepLinkHandler() => _instance;
  DeepLinkHandler._internal();

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  /// Initialize deep link handling
  Future<void> initialize() async {
    try {
      _appLinks = AppLinks();

      // Listen for deep links while app is running
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri uri) {
          AppLogger.info('📱 Deep link received: $uri');
          _handleDeepLink(uri);
        },
        onError: (err) {
          AppLogger.error('Deep link error', err, null);
        },
      );

      // Check if app was opened via deep link
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        AppLogger.info('📱 App opened via deep link: $initialUri');
        _handleDeepLink(initialUri);
      }

      AppLogger.info('✅ Deep link handler initialized');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize deep link handler', e, stackTrace);
    }
  }

  /// Handle incoming deep link
  void _handleDeepLink(Uri uri) {
    try {
      // Check if this is an OAuth callback
      if (uri.fragment.isNotEmpty) {
        // Supabase OAuth callback format: scheme://path#access_token=...
        AppLogger.info('Processing OAuth callback from deep link');

        // Supabase will automatically handle the OAuth callback
        // We just need to make sure the session is processed
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
          final event = data.event;
          if (event == AuthChangeEvent.signedIn) {
            AppLogger.info('✅ User signed in via deep link');
          }
        });
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error handling deep link', e, stackTrace);
    }
  }

  /// Dispose resources
  void dispose() {
    _linkSubscription?.cancel();
  }
}
