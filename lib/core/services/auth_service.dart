import 'dart:convert';
import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';
import 'package:http/http.dart' as http;
import '../../main.dart' show navigatorKey;
import '../constants/app_config.dart';
import '../models/auth_models.dart';
import 'secure_storage_service.dart';

/// Handles Microsoft OAuth login via aad_oauth (Azure AD purpose-built package).
///
/// Flow:
/// 1. [AadOAuth.login] opens Microsoft login → handles MSAL quirks internally
/// 2. Get MS access token via [AadOAuth.getAccessToken]
/// 3. POST /auth/microsoft/mobile → receive our JWT
/// 4. Persist JWT to secure storage
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SecureStorageService _storage = SecureStorageService();

  late final AadOAuth _aadOAuth = AadOAuth(_buildConfig());

  static Config _buildConfig() => Config(
    tenant: AppConfig.msTenantId,
    clientId: AppConfig.msClientId,
    scope: AppConfig.msScopes.join(' '),
    redirectUri: AppConfig.msRedirectUri,
    navigatorKey: navigatorKey,
  );

  // ─────────────────────────────────────────────────────────────
  // PUBLIC API
  // ─────────────────────────────────────────────────────────────

  /// Opens Microsoft login in a system Custom Tab via Azure AD.
  /// Returns [AuthResult] containing our backend JWT and user profile.
  Future<AuthResult> login() async {
    await _aadOAuth.login();

    final msAccessToken = await _aadOAuth.getAccessToken();
    if (msAccessToken == null) {
      throw Exception('Login Microsoft gagal atau dibatalkan.');
    }

    try {
      // 2. Send MS access token to our backend → receive our JWT
      final response = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}/auth/microsoft/mobile'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'accessToken': msAccessToken}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final message = body['message'] ?? 'Authentication gagal.';
        throw Exception(message);
      }

      final tokenData = jsonDecode(response.body) as Map<String, dynamic>;
      final result = AuthResult.fromJson(tokenData);

      // 3. Persist tokens
      await _storage.saveAuthResult(result);

      return result;
    } on http.ClientException catch (e) {
      print('[AUTH] Network ClientException: $e');
      throw Exception(
        'Tidak dapat terhubung ke server. Periksa koneksi internet atau IP server.',
      );
    } catch (e) {
      print('[AUTH] Unexpected Error during backend exchange: $e');
      rethrow;
    }
  }

  /// Returns a persisted [AuthResult] if the user is already logged in.
  ///
  /// Checks two layers:
  /// 1. Our own JWT in flutter_secure_storage (fast path)
  /// 2. aad_oauth's cached MS token → silently re-auth with backend (fallback)
  Future<AuthResult?> tryAutoLogin() async {
    // ── Fast path: check our own persisted JWT ──
    final isLoggedIn = await _storage.isLoggedIn();
    if (isLoggedIn) {
      final token = await _storage.getAccessToken();
      final refreshToken = await _storage.getRefreshToken();
      final user = await _storage.getUser();

      if (token != null && refreshToken != null && user != null) {
        return AuthResult(
          accessToken: token,
          refreshToken: refreshToken,
          user: user,
        );
      }
    }

    // ── Fallback: try silent re-auth via aad_oauth cached MS token ──
    // This covers the case where the app was killed (recent apps cleared)
    // and flutter_secure_storage lost its data, but aad_oauth still has
    // a valid cached Microsoft token.
    try {
      final msAccessToken = await _aadOAuth.getAccessToken();
      if (msAccessToken == null) return null;

      // Exchange cached MS token for our backend JWT
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/auth/microsoft/mobile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'accessToken': msAccessToken}),
      );

      if (response.statusCode != 200) return null;

      final tokenData = jsonDecode(response.body) as Map<String, dynamic>;
      final result = AuthResult.fromJson(tokenData);

      // Re-persist so next cold start uses the fast path
      await _storage.saveAuthResult(result);

      return result;
    } catch (_) {
      // aad_oauth has no cached token or it's expired → user needs to login
      return null;
    }
  }

  /// Clears all stored tokens (both ours and aad_oauth cache).
  Future<void> logout() async {
    await _aadOAuth.logout();
    await _storage.clearAll();
  }
}
