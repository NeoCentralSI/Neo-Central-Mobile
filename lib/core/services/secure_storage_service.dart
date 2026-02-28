import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_models.dart';
import '../enums/user_role.dart';

/// Wraps flutter_secure_storage for all auth token/user persistence.
class SecureStorageService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user_data';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ── Write ──────────────────────────────────────────────────
  Future<void> saveAuthResult(AuthResult result) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: result.accessToken),
      _storage.write(key: _refreshTokenKey, value: result.refreshToken),
      _storage.write(key: _userKey, value: jsonEncode(result.user.toJson())),
    ]);
  }

  // ── Read ───────────────────────────────────────────────────
  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<UserModel?> getUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<UserRole?> getUserRole() async {
    final user = await getUser();
    return user?.appRole;
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ── Clear ──────────────────────────────────────────────────
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
