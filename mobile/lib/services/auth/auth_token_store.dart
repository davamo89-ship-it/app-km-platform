import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../models/auth/login_response.dart';

class AuthTokenStore {
  AuthTokenStore({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _userIdKey = 'auth_user_id';
  static const String _emailKey = 'auth_email';
  static const String _accessTokenKey = 'auth_access_token';
  static const String _accessTokenExpiresAtKey =
      'auth_access_token_expires_at';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _refreshTokenExpiresAtKey =
      'auth_refresh_token_expires_at';

  Future<void> saveSession(LoginResponse session) async {
    await Future.wait([
      _storage.write(
        key: _userIdKey,
        value: session.userId,
      ),
      _storage.write(
        key: _emailKey,
        value: session.email,
      ),
      _storage.write(
        key: _accessTokenKey,
        value: session.accessToken,
      ),
      _storage.write(
        key: _accessTokenExpiresAtKey,
        value: session.accessTokenExpiresAtUtc.toIso8601String(),
      ),
      _storage.write(
        key: _refreshTokenKey,
        value: session.refreshToken,
      ),
      _storage.write(
        key: _refreshTokenExpiresAtKey,
        value: session.refreshTokenExpiresAtUtc.toIso8601String(),
      ),
    ]);
  }

Future<DateTime?> getAccessTokenExpiresAtUtc() async {
    final value = await _storage.read(
        key: _accessTokenExpiresAtKey,
    );

    if (value == null || value.isEmpty) {
        return null;
    }

    return DateTime.tryParse(value)?.toUtc();
    }

Future<DateTime?> getRefreshTokenExpiresAtUtc() async {
    final value = await _storage.read(
        key: _refreshTokenExpiresAtKey,
    );

    if (value == null || value.isEmpty) {
        return null;
    }

    return DateTime.tryParse(value)?.toUtc();
    }

  Future<String?> getAccessToken() {
    return _storage.read(
      key: _accessTokenKey,
    );
  }

  Future<String?> getRefreshToken() {
    return _storage.read(
      key: _refreshTokenKey,
    );
  }

  Future<String?> getUserId() {
    return _storage.read(
      key: _userIdKey,
    );
  }

  Future<String?> getEmail() {
    return _storage.read(
      key: _emailKey,
    );
  }

  Future<bool> hasSession() async {
    final accessToken =
        await _storage.read(key: _accessTokenKey);

    final refreshToken =
        await _storage.read(key: _refreshTokenKey);

    return accessToken != null &&
        accessToken.isNotEmpty &&
        refreshToken != null &&
        refreshToken.isNotEmpty;
  }

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _emailKey),
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _accessTokenExpiresAtKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _refreshTokenExpiresAtKey),
    ]);
  }
}