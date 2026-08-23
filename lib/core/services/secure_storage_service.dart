import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../enums/user_role.dart';
import '../models/auth_models.dart';
import 'token_store.dart';

typedef PreferencesFactory = Future<SharedPreferences> Function();

/// Persists authentication secrets in platform secure storage.
///
/// Non-secret cached profile data remains in SharedPreferences. Existing
/// installations are migrated lazily from the legacy preference token keys.
class SecureStorageService {
  static const accessTokenKey = 'access_token';
  static const refreshTokenKey = 'refresh_token';
  static const userKey = 'user_data';

  final TokenStore _tokenStore;
  final PreferencesFactory _preferencesFactory;

  SecureStorageService({
    TokenStore? tokenStore,
    PreferencesFactory? preferencesFactory,
  }) : _tokenStore = tokenStore ?? const FlutterSecureTokenStore(),
       _preferencesFactory =
           preferencesFactory ?? SharedPreferences.getInstance;

  Future<SharedPreferences> get _prefs => _preferencesFactory();

  Future<void> saveAuthResult(AuthResult result) async {
    final prefs = await _prefs;
    await Future.wait([
      saveTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
      ),
      prefs.setString(userKey, jsonEncode(result.user.toJson())),
    ]);
  }

  /// Stores a rotated access/refresh token pair, then removes the deprecated
  /// SharedPreferences copies.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await _prefs;
    await Future.wait([
      _tokenStore.write(accessTokenKey, accessToken),
      _tokenStore.write(refreshTokenKey, refreshToken),
    ]);
    await Future.wait([
      prefs.remove(accessTokenKey),
      prefs.remove(refreshTokenKey),
    ]);
  }

  Future<String?> getAccessToken() => _readAndMigrate(accessTokenKey);

  Future<String?> getRefreshToken() => _readAndMigrate(refreshTokenKey);

  Future<String?> _readAndMigrate(String key) async {
    final secureValue = await _tokenStore.read(key);
    if (secureValue != null) return secureValue;

    final prefs = await _prefs;
    final legacyValue = prefs.getString(key);
    if (legacyValue == null) return null;

    await _tokenStore.write(key, legacyValue);
    await prefs.remove(key);
    return legacyValue;
  }

  Future<UserModel?> getUser() async {
    final prefs = await _prefs;
    final raw = prefs.getString(userKey);
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

  Future<void> clearTokens() async {
    final prefs = await _prefs;
    await Future.wait([
      _tokenStore.delete(accessTokenKey),
      _tokenStore.delete(refreshTokenKey),
      prefs.remove(accessTokenKey),
      prefs.remove(refreshTokenKey),
    ]);
  }

  Future<void> clearAll() async {
    final prefs = await _prefs;
    await Future.wait([clearTokens(), prefs.remove(userKey)]);
  }
}
