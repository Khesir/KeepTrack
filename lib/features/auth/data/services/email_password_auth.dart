import 'package:keep_track/core/error/result.dart';
import 'package:keep_track/core/error/failure.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../domain/entities/user.dart';

/// Simple email/password authentication extension for AuthService
class EmailPasswordAuth {
  final SupabaseClient _supabase;

  EmailPasswordAuth(this._supabase);

  /// Sign up with email and password
  Future<Result<User>> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      AppLogger.info('Signing up with email: $email');

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': displayName},
      );

      if (response.user == null) {
        return Result.error(
          const ServerFailure(message: 'Failed to create account'),
        );
      }

      final user = User(
        id: response.user!.id,
        email: response.user!.email ?? email,
        displayName: displayName,
        photoUrl: null,
        createdAt: DateTime.parse(response.user!.createdAt),
        isAdmin: false,
        metadata: response.user!.userMetadata,
      );

      AppLogger.info('Sign-up successful: $email');
      return Result.success(user);
    } catch (e, stackTrace) {
      AppLogger.error('Sign-up error', e, stackTrace);
      return Result.error(
        UnknownFailure(
          message: 'Failed to sign up: ${e.toString()}',
          stackTrace: stackTrace,
          originalError: e,
        ),
      );
    }
  }

  /// Sign in with email and password
  Future<Result<User>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('Signing in with email: $email');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return Result.error(
          const ValidationFailure('Invalid email or password'),
        );
      }

      final user = User(
        id: response.user!.id,
        email: response.user!.email ?? email,
        displayName: response.user!.userMetadata?['full_name'] as String?,
        photoUrl: response.user!.userMetadata?['avatar_url'] as String?,
        createdAt: DateTime.parse(response.user!.createdAt),
        isAdmin: response.user!.userMetadata?['is_admin'] as bool? ?? false,
        metadata: response.user!.userMetadata,
      );

      AppLogger.info('Sign-in successful: $email');
      return Result.success(user);
    } catch (e, stackTrace) {
      AppLogger.error('Sign-in error', e, stackTrace);
      return Result.error(
        UnknownFailure(
          message: 'Failed to sign in: ${e.toString()}',
          stackTrace: stackTrace,
          originalError: e,
        ),
      );
    }
  }

  /// Send password reset email
  Future<Result<void>> resetPassword(String email) async {
    try {
      AppLogger.info('Sending password reset email to: $email');

      await _supabase.auth.resetPasswordForEmail(email);

      AppLogger.info('Password reset email sent');
      return Result.success(null);
    } catch (e, stackTrace) {
      AppLogger.error('Password reset error', e, stackTrace);
      return Result.error(
        UnknownFailure(
          message: 'Failed to send reset email: ${e.toString()}',
          stackTrace: stackTrace,
          originalError: e,
        ),
      );
    }
  }

  /// Sign in with Magic Link (passwordless email authentication)
  /// User receives an email with a link to sign in - no password needed!
  Future<Result<void>> signInWithMagicLink(String email) async {
    try {
      AppLogger.info('Sending magic link to: $email');

      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: null, // Will use app's current URL
      );

      AppLogger.info('Magic link sent successfully');
      return Result.success(null);
    } catch (e, stackTrace) {
      AppLogger.error('Magic link error', e, stackTrace);
      return Result.error(
        UnknownFailure(
          message: 'Failed to send magic link: ${e.toString()}',
          stackTrace: stackTrace,
          originalError: e,
        ),
      );
    }
  }
}
