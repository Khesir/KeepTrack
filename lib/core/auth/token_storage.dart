import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_tokens.dart';

/// Platform-aware token storage.
/// Mobile/desktop → flutter_secure_storage (encrypted keychain/keystore)
/// Web           → in-memory only (no persistence intentional per requirements)
class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  // In-memory fallback for web
  String? _memAccessToken;
  String? _memRefreshToken;

  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> save(AuthTokens tokens) async {
    if (kIsWeb) {
      _memAccessToken = tokens.accessToken;
      _memRefreshToken = tokens.refreshToken;
    } else {
      await _secure.write(key: _accessKey, value: tokens.accessToken);
      await _secure.write(key: _refreshKey, value: tokens.refreshToken);
    }
  }

  Future<AuthTokens?> load() async {
    if (kIsWeb) {
      final a = _memAccessToken;
      final r = _memRefreshToken;
      if (a == null || r == null) return null;
      return AuthTokens(accessToken: a, refreshToken: r);
    }
    final a = await _secure.read(key: _accessKey);
    final r = await _secure.read(key: _refreshKey);
    if (a == null || r == null) return null;
    return AuthTokens(accessToken: a, refreshToken: r);
  }

  Future<String?> getAccessToken() async {
    if (kIsWeb) return _memAccessToken;
    return _secure.read(key: _accessKey);
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) return _memRefreshToken;
    return _secure.read(key: _refreshKey);
  }

  Future<void> clear() async {
    if (kIsWeb) {
      _memAccessToken = null;
      _memRefreshToken = null;
    } else {
      await _secure.delete(key: _accessKey);
      await _secure.delete(key: _refreshKey);
    }
  }
}
