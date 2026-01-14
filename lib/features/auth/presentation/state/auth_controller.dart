import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/state/state.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/features/auth/data/services/auth_service.dart';
import 'package:keep_track/features/auth/domain/entities/user.dart';
import 'package:keep_track/features/finance/data/services/finance_initialization_service.dart';
import 'package:keep_track/features/tasks/data/sevices/bucket_initialization_service.dart';

class AuthController extends StreamState<AsyncState<User?>> {
  final AuthService _authService;

  // Start with null state instead of loading - let _init() determine the actual state
  AuthController(this._authService) : super(const AsyncData(null)) {
    _init();
  }

  /// Initialize auth state
  void _init() async {
    // Listen to auth state changes FIRST
    _authService.authStateChanges.listen(
      (user) {
        if (user != null) {
          AppLogger.info('Auth state changed: User signed in - ${user.email}');
          emit(AsyncData(user));
          _initializeUserData(user.id);
        } else {
          AppLogger.info('Auth state changed: User signed out');
          emit(const AsyncData(null));
        }
      },
      onError: (error) {
        AppLogger.error('Auth state change error', error, null);
        emit(AsyncError('Auth error', error));
      },
    );

    // On web, if there's an OAuth callback in progress (URL has ?code=...),
    // Supabase processes it automatically. Wait for auth state listener to fire.
    // Give it up to 2 seconds to process the OAuth callback.
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 100));

      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        AppLogger.info('User authenticated: ${currentUser.email}');
        emit(AsyncData(currentUser));
        _initializeUserData(currentUser.id);
        return; // Done!
      }
    }

    // After 2 seconds, if still no user, assume not logged in
    AppLogger.info('No authenticated user found');
    emit(const AsyncData(null));
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    emit(const AsyncLoading());
    final result = await _authService.signInWithGoogle();
    result.fold(
      onSuccess: (user) async {
        emit(AsyncData(user));
        // Initialize user data (finance categories, etc.) in the background
        _initializeUserData(user.id);
      },
      onError: (failure) {
        // On web, "Sign-in initiated" is expected (redirect flow)
        // Don't show error, just keep loading state
        if (failure.message.contains('Sign-in initiated')) {
          // Keep loading state - auth listener will update when redirect completes
          AppLogger.info('Web OAuth redirect initiated');
        } else {
          emit(AsyncError(failure.message, failure));
        }
      },
    );
  }

  /// Sign in with email and password (simple, works on all platforms!)
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    emit(const AsyncLoading());
    final result = await _authService.signInWithEmail(
      email: email,
      password: password,
    );
    result.fold(
      onSuccess: (user) async {
        emit(AsyncData(user));
        _initializeUserData(user.id);
      },
      onError: (failure) => emit(AsyncError(failure.message, failure)),
    );
  }

  /// Sign up with email and password
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    emit(const AsyncLoading());
    final result = await _authService.signUpWithEmail(
      email: email,
      password: password,
      displayName: displayName,
    );
    result.fold(
      onSuccess: (user) async {
        emit(AsyncData(user));
        _initializeUserData(user.id);
      },
      onError: (failure) => emit(AsyncError(failure.message, failure)),
    );
  }

  /// Sign in as Admin (Dev mode only)
  Future<void> signInAsAdmin() async {
    emit(const AsyncLoading());
    final result = await _authService.signInAsAdmin();
    result.fold(
      onSuccess: (user) async {
        emit(AsyncData(user));
        // Initialize user data (finance categories, etc.) in the background
        _initializeUserData(user.id);
      },
      onError: (failure) => emit(AsyncError(failure.message, failure)),
    );
  }

  /// Sign in with Magic Link (passwordless email)
  Future<void> signInWithMagicLink(String email) async {
    emit(const AsyncLoading());
    final result = await _authService.signInWithMagicLink(email);
    result.fold(
      onSuccess: (_) {
        // Magic link sent - show success message
        // User will be signed in when they click the link in their email
        emit(const AsyncData(null));
        AppLogger.info('Magic link sent to: $email');
      },
      onError: (failure) => emit(AsyncError(failure.message, failure)),
    );
  }

  /// Cancel sign-in (reset to idle state)
  void cancelSignIn() {
    AppLogger.info('Sign-in cancelled by user');
    emit(const AsyncData(null));
  }

  /// Sign out
  Future<void> signOut() async {
    emit(const AsyncLoading());
    final result = await _authService.signOut();
    result.fold(
      onSuccess: (_) => emit(const AsyncData(null)),
      onError: (failure) => emit(AsyncError(failure.message, failure)),
    );
  }

  /// Get current user
  User? get currentUser => _authService.currentUser;

  /// Check if authenticated
  bool get isAuthenticated => _authService.isAuthenticated;

  /// Get current user ID
  String? get currentUserId => _authService.currentUserId;

  /// Check if current user is admin
  bool get isAdmin => _authService.currentUser?.isAdmin ?? false;

  /// Initialize user data on first login (background task)
  /// This includes creating default finance categories and other setup
  Future<void> _initializeUserData(String userId) async {
    try {
      AppLogger.info('Initializing user data for user: $userId');

      // Initialize default finance categories
      final financeService = locator.get<FinanceInitializationService>();

      final financeResult = await financeService.initializeDefaultCategories(
        userId,
      );

      financeResult.fold(
        onSuccess: (wasInitialized) {
          if (wasInitialized) {
            AppLogger.info(
              '✅ Finance data initialization completed successfully',
            );
          } else {
            AppLogger.info(
              'Finance data  already exists, skipping initialization',
            );
          }
        },
        onError: (failure) {
          // Log error but don't block user from using the app
          AppLogger.warning(
            'Failed to initialize user data (non-blocking): ${failure.message}',
          );
        },
      );
      final bucketService = locator.get<BucketInitializationService>();

      final bucketResult = await bucketService.initializeDefaultCategories(
        userId,
      );

      bucketResult.fold(
        onSuccess: (wasInitialized) {
          if (wasInitialized) {
            AppLogger.info(
              '✅ Bucket data initialization completed successfully',
            );
          } else {
            AppLogger.info(
              'Bucket data already exists, skipping initialization',
            );
          }
        },
        onError: (failure) {
          // Log error but don't block user from using the app
          AppLogger.warning(
            'Failed to initialize user data (non-blocking): ${failure.message}',
          );
        },
      );
    } catch (e, stackTrace) {
      // Don't let initialization errors affect user experience
      AppLogger.error('Error during user data initialization', e, stackTrace);
    }
  }
}
