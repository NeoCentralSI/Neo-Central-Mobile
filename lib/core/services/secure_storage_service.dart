import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_models.dart';
import '../enums/user_role.dart';

/// Persists auth tokens and user data using SharedPreferences so session
/// survives app restarts without requiring re-login.
class SecureStorageService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user_data';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ── Write ──────────────────────────────────────────────────
  Future<void> saveAuthResult(AuthResult result) async {
    final prefs = await _prefs;
    await Future.wait([
      prefs.setString(_accessTokenKey, result.accessToken),
      prefs.setString(_refreshTokenKey, result.refreshToken),
      prefs.setString(_userKey, jsonEncode(result.user.toJson())),
    ]);
  }

  // ── Read ───────────────────────────────────────────────────
  Future<String?> getAccessToken() async {
    final prefs = await _prefs;
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await _prefs;
    return prefs.getString(_refreshTokenKey);
  }

  Future<UserModel?> getUser() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_userKey);
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
    final prefs = await _prefs;
    await Future.wait([
      prefs.remove(_accessTokenKey),
      prefs.remove(_refreshTokenKey),
      prefs.remove(_userKey),
    ]);
  }
}
