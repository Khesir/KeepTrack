import 'package:persona_codex/core/state/stream_state.dart';
import 'package:persona_codex/core/state/state.dart';
import 'package:persona_codex/core/logging/app_logger.dart';
import 'package:persona_codex/features/auth/data/services/auth_service.dart';
import 'package:persona_codex/features/auth/domain/entities/user.dart';

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
    } else {
      emit(const AsyncData(null));
    }

    // Listen to auth state changes
    _authService.authStateChanges.listen(
      (user) {
        emit(AsyncData(user));
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
      onSuccess: (user) => emit(AsyncData(user)),
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
      onSuccess: (user) => emit(AsyncData(user)),
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
}
