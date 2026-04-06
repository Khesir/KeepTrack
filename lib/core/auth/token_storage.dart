import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_tokens.dart';

/// Platform-aware token storage.
/// Mobile/desktop → flutter_secure_storage (encrypted keychain/keystore)
/// Web            → shared_preferences (localStorage-backed, survives reload)
class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<void> save(AuthTokens tokens) async {
    if (kIsWeb) {
      final prefs = await _prefs;
      await prefs.setString(_accessKey, tokens.accessToken);
      await prefs.setString(_refreshKey, tokens.refreshToken);
    } else {
      await _secure.write(key: _accessKey, value: tokens.accessToken);
      await _secure.write(key: _refreshKey, value: tokens.refreshToken);
    }
  }

  Future<AuthTokens?> load() async {
    if (kIsWeb) {
      final prefs = await _prefs;
      final a = prefs.getString(_accessKey);
      final r = prefs.getString(_refreshKey);
      if (a == null || r == null) return null;
      return AuthTokens(accessToken: a, refreshToken: r);
    }
    final a = await _secure.read(key: _accessKey);
    final r = await _secure.read(key: _refreshKey);
    if (a == null || r == null) return null;
    return AuthTokens(accessToken: a, refreshToken: r);
  }

  Future<String?> getAccessToken() async {
    if (kIsWeb) {
      final prefs = await _prefs;
      return prefs.getString(_accessKey);
    }
    return _secure.read(key: _accessKey);
  }

  Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      final prefs = await _prefs;
      return prefs.getString(_refreshKey);
    }
    return _secure.read(key: _refreshKey);
  }

  Future<void> clear() async {
    if (kIsWeb) {
      final prefs = await _prefs;
      await prefs.remove(_accessKey);
      await prefs.remove(_refreshKey);
    } else {
      await _secure.delete(key: _accessKey);
      await _secure.delete(key: _refreshKey);
    }
  }
}
