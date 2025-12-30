import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:persona_codex/core/error/result.dart';
import 'package:persona_codex/core/error/failure.dart';
import 'package:persona_codex/core/logging/app_logger.dart';
import 'package:persona_codex/features/auth/domain/entities/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class AuthService {
  final SupabaseClient _supabase;
  GoogleSignIn? _googleSignIn;

  AuthService(this._supabase);

  /// Lazy initialize Google Sign-In (only when needed)
  GoogleSignIn get _googleSignInInstance {
    _googleSignIn ??= GoogleSignIn(
      scopes: [
        'email',
        'profile',
        'openid',  // Required for id_token
      ],
      // For web, we need to specify the serverClientId (Web OAuth Client ID)
      serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
    );
    return _googleSignIn!;
  }

  /// Get current user
  User? get currentUser {
    final supabaseUser = _supabase.auth.currentUser;
    if (supabaseUser == null) return null;

    return User(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      displayName: supabaseUser.userMetadata?['full_name'] as String?,
      photoUrl: supabaseUser.userMetadata?['avatar_url'] as String?,
      createdAt: DateTime.parse(supabaseUser.createdAt),
      isAdmin: supabaseUser.userMetadata?['is_admin'] as bool? ?? false,
      metadata: supabaseUser.userMetadata,
    );
  }

  /// Get current user ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Check if user is authenticated
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.map((event) {
      final supabaseUser = event.session?.user;
      if (supabaseUser == null) return null;

      return User(
        id: supabaseUser.id,
        email: supabaseUser.email ?? '',
        displayName: supabaseUser.userMetadata?['full_name'] as String?,
        photoUrl: supabaseUser.userMetadata?['avatar_url'] as String?,
        createdAt: DateTime.parse(supabaseUser.createdAt),
        isAdmin: supabaseUser.userMetadata?['is_admin'] as bool? ?? false,
        metadata: supabaseUser.userMetadata,
      );
    });
  }

  /// Sign in with Google
  Future<Result<User>> signInWithGoogle() async {
    try {
      final devMode = await _isDevMode();
      AppLogger.info('Starting Google Sign-In... Dev mode: $devMode');

      // Check if in dev mode
      if (devMode) {
        AppLogger.info('Dev mode detected - using bypass');
        return _devBypass(isAdmin: false);
      }

      // IMPORTANT: Clear any existing Supabase session first
      // This ensures the account picker is always shown, even if there's a cached session
      if (_supabase.auth.currentUser != null) {
        AppLogger.info('Existing Supabase session found, clearing to force account picker');
        await _supabase.auth.signOut();
      }

      // On web, use Supabase OAuth flow (redirect-based)
      if (kIsWeb) {
        AppLogger.info('Web platform detected - using Supabase OAuth redirect');

        // This will redirect to Google OAuth and back
        final response = await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kIsWeb ? Uri.base.toString() : null,
        );

        if (!response) {
          return Result.error(
            const ServerFailure(message: 'Failed to initiate Google Sign-In'),
          );
        }

        // On web, the redirect happens and the user comes back authenticated
        // We need to wait for the auth state to update
        // The auth state listener in AuthController will handle this
        return Result.error(
          const ValidationFailure('Sign-in initiated - waiting for redirect'),
        );
      }

      // On mobile/desktop, use google_sign_in package
      AppLogger.info('Mobile/Desktop platform - using google_sign_in package');

      // Force disconnect to ensure account picker is shown on every sign-in
      // disconnect() fully revokes access, while signOut() might cache the account
      // This is especially important on Android to prevent auto-selecting the last account
      try {
        if (await _googleSignInInstance.isSignedIn()) {
          AppLogger.info('User already signed in to Google, disconnecting to force account picker');
          await _googleSignInInstance.disconnect();
        }
      } catch (e) {
        AppLogger.warning('Error checking/clearing Google Sign-In state: $e');
        // Continue anyway - disconnect might fail if already disconnected
      }

      final GoogleSignInAccount? googleUser = await _googleSignInInstance.signIn();
      if (googleUser == null) {
        AppLogger.warning('Google Sign-In cancelled by user');
        return Result.error(
          const ValidationFailure('Sign-in cancelled'),
        );
      }

      // Get Google auth credentials
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        AppLogger.error('Failed to get Google tokens', null, null);
        return Result.error(
          const UnknownFailure(message: 'Failed to authenticate with Google'),
        );
      }

      AppLogger.info('Google tokens obtained, signing in to Supabase...');

      // Sign in to Supabase with Google credentials
      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken!,
      );

      if (response.user == null) {
        AppLogger.error('Supabase sign-in failed', null, null);
        return Result.error(
          const ServerFailure(message: 'Failed to sign in'),
        );
      }

      final user = User(
        id: response.user!.id,
        email: response.user!.email ?? '',
        displayName: response.user!.userMetadata?['full_name'] as String?,
        photoUrl: response.user!.userMetadata?['avatar_url'] as String?,
        createdAt: DateTime.parse(response.user!.createdAt),
        isAdmin: response.user!.userMetadata?['is_admin'] as bool? ?? false,
        metadata: response.user!.userMetadata,
      );

      AppLogger.info('Sign-in successful for user: ${user.email}');
      return Result.success(user);
    } catch (e, stackTrace) {
      AppLogger.error('Google Sign-In error', e, stackTrace);
      return Result.error(
        UnknownFailure(
          message: 'Failed to sign in: ${e.toString()}',
          stackTrace: stackTrace,
          originalError: e,
        ),
      );
    }
  }

  /// Sign out
  Future<Result<void>> signOut() async {
    try {
      AppLogger.info('Signing out user...');

      // Disconnect from Google (only if initialized)
      // Using disconnect() instead of signOut() to fully revoke access
      // This ensures the account picker shows on next sign-in (especially on Android)
      if (_googleSignIn != null && await _googleSignIn!.isSignedIn()) {
        await _googleSignIn!.disconnect();
      }

      // Sign out from Supabase
      await _supabase.auth.signOut();

      AppLogger.info('Sign-out successful');
      return Result.success(null);
    } catch (e, stackTrace) {
      AppLogger.error('Sign-out error', e, stackTrace);
      return Result.error(
        UnknownFailure(
          message: 'Failed to sign out',
          stackTrace: stackTrace,
          originalError: e,
        ),
      );
    }
  }

  /// Dev bypass for testing without Google auth
  Future<bool> _isDevMode() async {
    try {
      // Check if DEV_BYPASS is set in environment
      final devBypass = dotenv.env['DEV_BYPASS'] ?? 'false';
      AppLogger.info('DEV_BYPASS value: $devBypass');
      return devBypass.toLowerCase() == 'true';
    } catch (e) {
      AppLogger.error('Error checking dev mode', e, null);
      return false;
    }
  }

  /// Sign in as Admin (Dev mode only)
  Future<Result<User>> signInAsAdmin() async {
    try {
      // Only allow in dev mode
      if (!await _isDevMode()) {
        AppLogger.warning('Admin sign-in attempted in production mode');
        return Result.error(
          const ValidationFailure('Admin mode is only available in development'),
        );
      }

      AppLogger.warning('Using ADMIN BYPASS - signing in as admin');
      return _devBypass(isAdmin: true);
    } catch (e, stackTrace) {
      AppLogger.error('Admin bypass error', e, stackTrace);
      return Result.error(
        UnknownFailure(
          message: 'Admin bypass failed',
          stackTrace: stackTrace,
          originalError: e,
        ),
      );
    }
  }

  /// Dev bypass sign-in
  Future<Result<User>> _devBypass({required bool isAdmin}) async {
    try {
      final String email;
      final String password;
      final String displayName;

      if (isAdmin) {
        // Use admin credentials
        email = dotenv.env['ADMIN_EMAIL'] ?? 'admin@personalcodex.app';
        password = dotenv.env['ADMIN_PASSWORD'] ?? 'admin123456';
        displayName = 'Admin User';
        AppLogger.warning('Using ADMIN BYPASS - signing in as admin');
      } else {
        // Use regular dev credentials
        email = dotenv.env['DEV_EMAIL'] ?? 'dev@personalcodex.app';
        password = dotenv.env['DEV_PASSWORD'] ?? 'dev123456';
        displayName = 'Dev User';
        AppLogger.warning('Using DEV BYPASS - signing in as dev user');
      }

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        // Try to sign up if sign-in failed
        AppLogger.info('User not found, creating new user...');
        final signUpResponse = await _supabase.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': displayName,
            'avatar_url': null,
            'is_admin': isAdmin,
          },
        );

        if (signUpResponse.user == null) {
          return Result.error(
            const ServerFailure(message: 'Failed to create user'),
          );
        }

        final user = User(
          id: signUpResponse.user!.id,
          email: signUpResponse.user!.email ?? email,
          displayName: displayName,
          photoUrl: null,
          createdAt: DateTime.parse(signUpResponse.user!.createdAt),
          isAdmin: isAdmin,
          metadata: signUpResponse.user!.userMetadata,
        );

        return Result.success(user);
      }

      final user = User(
        id: response.user!.id,
        email: response.user!.email ?? email,
        displayName: response.user!.userMetadata?['full_name'] as String? ??
            displayName,
        photoUrl: response.user!.userMetadata?['avatar_url'] as String?,
        createdAt: DateTime.parse(response.user!.createdAt),
        isAdmin: response.user!.userMetadata?['is_admin'] as bool? ?? isAdmin,
        metadata: response.user!.userMetadata,
      );

      return Result.success(user);
    } catch (e, stackTrace) {
      AppLogger.error('Dev bypass error', e, stackTrace);
      return Result.error(
        UnknownFailure(
          message: 'Dev bypass failed',
          stackTrace: stackTrace,
          originalError: e,
        ),
      );
    }
  }
}
