import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:keep_track/core/auth/auth_tokens.dart';
import 'package:keep_track/core/auth/token_storage.dart';
import 'package:keep_track/core/error/failure.dart';
import 'package:keep_track/core/error/result.dart';
import 'package:keep_track/core/logging/app_logger.dart';
import 'package:keep_track/core/network/api_client.dart';
import 'package:keep_track/core/network/api_exception.dart';
import 'package:keep_track/features/auth/domain/entities/user.dart';

class AuthService {
  final Dio _dio = ApiClient.instance;
  final TokenStorage _tokens = TokenStorage.instance;
  GoogleSignIn? _googleSignIn;

  // ── State ─────────────────────────────────────────────────────────────────

  User? _currentUser;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  String? get currentUserId => _currentUser?.id;

  final _stateController = _UserStreamController();
  Stream<User?> get authStateChanges => _stateController.stream;

  // ── Google Sign-In ────────────────────────────────────────────────────────

  static const _googleClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  GoogleSignIn get _gsi => _googleSignIn ??= kIsWeb
      ? GoogleSignIn(
          scopes: ['email', 'profile', 'openid'],
          clientId: _googleClientId.isEmpty ? null : _googleClientId,
        )
      : GoogleSignIn(
          scopes: ['email', 'profile', 'openid'],
          serverClientId: _googleClientId.isEmpty ? null : _googleClientId,
        );

  Future<Result<User>> signInWithGoogle() async {
    try {
      if (await _isDevMode()) return _devBypass(isAdmin: false);

      // Desktop (non-web, non-mobile) — not yet supported
      if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
        return Result.error(
          const ValidationFailure('Google Sign-In not supported on this platform'),
        );
      }

      // Disconnect to force account picker
      if (_gsi.currentUser != null) await _gsi.disconnect();

      final googleUser = await _gsi.signIn();
      if (googleUser == null) {
        return Result.error(const ValidationFailure('Sign-in cancelled'));
      }

      if (kIsWeb) {
        // Web: Token Client returns an access token, not an id token.
        // Pull it from authHeaders and verify server-side via userinfo endpoint.
        final headers = await googleUser.authHeaders;
        final accessToken = headers['Authorization']?.replaceFirst('Bearer ', '');
        if (accessToken == null || accessToken.isEmpty) {
          return Result.error(
            const UnknownFailure(message: 'Failed to get Google access token'),
          );
        }
        return _exchangeGoogleToken(accessToken: accessToken);
      } else {
        // Mobile: get id token to exchange with backend
        final auth = await googleUser.authentication;
        if (auth.idToken == null) {
          return Result.error(
            const UnknownFailure(message: 'Failed to get Google ID token'),
          );
        }
        return _exchangeGoogleToken(idToken: auth.idToken!);
      }
    } catch (e, st) {
      AppLogger.error('Google Sign-In error', e, st);
      return Result.error(
        UnknownFailure(message: e.toString(), stackTrace: st, originalError: e),
      );
    }
  }

  Future<Result<User>> _exchangeGoogleToken({String? idToken, String? accessToken}) async {
    try {
      final res = await _dio.post(
        '/auth/google',
        data: {
          if (idToken != null) 'idToken': idToken,
          if (accessToken != null) 'accessToken': accessToken,
        },
      );
      return _handleAuthResponse(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return Result.error(mapDioError(e));
    }
  }

  // ── Email / Password ──────────────────────────────────────────────────────

  Future<Result<User>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return _handleAuthResponse(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return Result.error(mapDioError(e));
    } catch (e, st) {
      return Result.error(
        UnknownFailure(message: e.toString(), stackTrace: st, originalError: e),
      );
    }
  }

  Future<Result<User>> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final res = await _dio.post(
        '/auth/register',
        data: {'email': email, 'password': password},
      );
      return _handleAuthResponse(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return Result.error(mapDioError(e));
    } catch (e, st) {
      return Result.error(
        UnknownFailure(message: e.toString(), stackTrace: st, originalError: e),
      );
    }
  }

  /// Magic link is not supported with NestJS backend.
  Future<Result<void>> signInWithMagicLink(String email) async {
    return Result.error(
      const ValidationFailure('Magic link sign-in is not supported'),
    );
  }

  // ── Session ───────────────────────────────────────────────────────────────

  /// Call on app start — restores session from secure storage
  Future<bool> restoreSession() async {
    try {
      final stored = await _tokens.load();
      if (stored == null) return false;

      // Fetch profile to validate the stored token
      final res = await _dio.get('/users/me');
      _currentUser = _userFromJson(res.data as Map<String, dynamic>);
      _stateController.add(_currentUser);
      return true;
    } catch (_) {
      await _tokens.clear();
      return false;
    }
  }

  Future<Result<void>> signOut() async {
    try {
      final refresh = await _tokens.getRefreshToken();
      if (refresh != null) {
        await _dio
            .post('/auth/logout', data: {'refreshToken': refresh})
            .catchError((_) {});
      }
      if (_googleSignIn != null && await _gsi.isSignedIn()) {
        await _gsi.disconnect();
      }
    } catch (_) {}
    await _tokens.clear();
    _currentUser = null;
    _stateController.add(null);
    return Result.success(null);
  }

  // ── Dev bypass ────────────────────────────────────────────────────────────

  Future<bool> _isDevMode() async {
    const v = String.fromEnvironment('DEV_BYPASS', defaultValue: 'false');
    return v.toLowerCase() == 'true';
  }

  Future<Result<User>> signInAsAdmin() async {
    if (!await _isDevMode()) {
      return Result.error(
        const ValidationFailure('Admin bypass only in dev mode'),
      );
    }
    return _devBypass(isAdmin: true);
  }

  Future<Result<User>> _devBypass({required bool isAdmin}) async {
    const adminEmail = String.fromEnvironment('ADMIN_EMAIL', defaultValue: 'admin@personalcodex.app');
    const devEmail = String.fromEnvironment('DEV_EMAIL', defaultValue: 'dev@personalcodex.app');
    const adminPassword = String.fromEnvironment('ADMIN_PASSWORD', defaultValue: 'admin123456');
    const devPassword = String.fromEnvironment('DEV_PASSWORD', defaultValue: 'dev123456');
    final email = isAdmin ? adminEmail : devEmail;
    final password = isAdmin ? adminPassword : devPassword;

    AppLogger.warning('DEV BYPASS — signing in as $email');
    return signInWithEmail(email: email, password: password);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<Result<User>> _handleAuthResponse(Map<String, dynamic> data) async {
    final tokens = AuthTokens.fromJson(data);
    await _tokens.save(tokens);

    final userData = data['user'] as Map<String, dynamic>;
    _currentUser = _userFromJson(userData);
    _stateController.add(_currentUser);
    return Result.success(_currentUser!);
  }

  User _userFromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String?,
        photoUrl: json['photoUrl'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        isAdmin: json['isAdmin'] as bool? ?? false,
        metadata: (json['metadata'] as Map?)?.cast<String, dynamic>(),
      );
}

// Simple broadcast stream controller without dart:async imports
class _UserStreamController {
  User? _last;
  final List<void Function(User?)> _listeners = [];

  Stream<User?> get stream => Stream.multi((c) {
        c.add(_last);
        final fn = c.add;
        _listeners.add(fn);
        c.onCancel = () => _listeners.remove(fn);
      });

  void add(User? user) {
    _last = user;
    for (final l in List.of(_listeners)) {
      l(user);
    }
  }
}
