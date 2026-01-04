import 'package:keep_track/core/state/stream_state.dart';
import 'package:keep_track/core/state/state.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import 'package:keep_track/core/di/service_locator.dart';
import 'package:keep_track/features/auth/data/services/auth_service.dart';
import 'package:keep_track/features/auth/domain/entities/user.dart';
import 'package:keep_track/features/finance/data/services/finance_initialization_service.dart';

class AuthController extends StreamState<AsyncState<User?>> {
  final AuthService _authService;

  AuthController(this._authService) : super(const AsyncLoading()) {
    _init();
  }

  /// Initialize auth state
  void _init() {
    // Check current auth state
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      emit(AsyncData(currentUser));
      // Initialize user data if needed (handles auto-login from session restoration)
      _initializeUserData(currentUser.id);
    } else {
      emit(const AsyncData(null));
    }

    // Listen to auth state changes
    _authService.authStateChanges.listen(
      (user) {
        emit(AsyncData(user));
        // Initialize user data when user signs in via OAuth redirect or session restore
        if (user != null) {
          _initializeUserData(user.id);
        }
      },
      onError: (error) {
        AppLogger.error('Auth state change error', error, null);
        emit(AsyncError('Auth error', error));
      },
    );
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
      final result = await financeService.initializeDefaultCategories(userId);

      result.fold(
        onSuccess: (wasInitialized) {
          if (wasInitialized) {
            AppLogger.info('✅ User data initialization completed successfully');
          } else {
            AppLogger.info('User data already exists, skipping initialization');
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
