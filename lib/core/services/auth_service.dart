import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

import '../../features/auth/presentation/microsoft_login_page.dart';
import '../../features/shell/notification_router.dart';
import '../constants/app_config.dart';
import '../models/auth_models.dart';
import '../navigation/navigator_key.dart';
import 'api_client.dart';
import 'secure_storage_service.dart';

/// Sign-in, session restore and logout.
///
/// Microsoft sign-in uses the backend's web OAuth flow, the same one the web
/// app uses: `GET /auth/microsoft/login` opens in an in-app web page, the
/// backend redirects back with a one-time code, and
/// `POST /auth/microsoft/exchange` turns that code into our tokens.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SecureStorageService _storage = SecureStorageService();

  static const _timeout = Duration(seconds: 20);

  /// Opens Microsoft sign-in. Throws when cancelled or rejected.
  Future<AuthResult> login() async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      throw const ApiException(0, 'Halaman login belum siap. Coba lagi.');
    }
    final outcome = await navigator.push<MicrosoftLoginOutcome>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MicrosoftLoginPage(
          startUrl: AppConfig.microsoftLoginUrl,
          apiBaseUrl: AppConfig.baseUrl,
        ),
      ),
    );
    if (outcome == null) throw Exception('Login cancelled');
    if (outcome.error != null) throw ApiException(0, outcome.error!);

    final body = await _postJson('/auth/microsoft/exchange', {
      'code': outcome.code,
    });
    // Response: { success, data: { accessToken, refreshToken, user } }
    final data = body['data'];
    if (data is! Map) {
      throw const ApiContractException('Respons login tidak valid.');
    }
    final result = AuthResult.fromJson(Map<String, dynamic>.from(data));
    await _storage.saveAuthResult(result);
    return result;
  }

  /// Email and password sign-in (`POST /auth/login`).
  /// Response: `{ success, user, accessToken, refreshToken }`.
  Future<AuthResult> loginWithEmail(String email, String password) async {
    final body = await _postJson('/auth/login', {
      'email': email,
      'password': password,
    });
    final result = AuthResult.fromJson(body);
    await _storage.saveAuthResult(result);
    return result;
  }

  /// Restores the saved session, or returns null when the user must sign in.
  ///
  /// The saved profile is refreshed from `GET /auth/me` when the server is
  /// reachable, so role changes (for example a new Kadep) apply on start.
  Future<AuthResult?> tryAutoLogin() async {
    if (!await _storage.isLoggedIn()) return null;
    final token = await _storage.getAccessToken();
    final refreshToken = await _storage.getRefreshToken();
    final saved = await _storage.getUser();
    if (token == null || refreshToken == null || saved == null) return null;

    var user = saved;
    try {
      final res = await ApiClient().get('/auth/me');
      final fresh = res is Map ? res['user'] : null;
      if (fresh is Map) {
        user = UserModel.fromJson(Map<String, dynamic>.from(fresh));
      }
    } on UnauthorizedApiException {
      // The refresh token is no longer valid either.
      await _storage.clearAll();
      return null;
    } catch (_) {
      // Offline or server error: keep the saved profile.
    }

    final result = AuthResult(
      accessToken: await _storage.getAccessToken() ?? token,
      refreshToken: await _storage.getRefreshToken() ?? refreshToken,
      user: user,
    );
    await _storage.saveAuthResult(result);
    return result;
  }

  /// Signs out on the backend (best effort) and clears the session, including
  /// the Microsoft cookies of the sign-in page.
  Future<void> logout() async {
    NotificationRouter.instance.detach();
    try {
      await ApiClient()
          .post('/auth/logout')
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
    try {
      await WebViewCookieManager().clearCookies();
    } catch (_) {}
    await _storage.clearAll();
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}$path'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const NetworkApiException(
        'Permintaan ke server melewati batas waktu.',
      );
    } on http.ClientException {
      throw const NetworkApiException(
        'Tidak dapat terhubung ke server. Periksa koneksi internet.',
      );
    }

    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      decoded = null;
    }
    final body = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body['message']?.toString();
      throw ApiException(
        response.statusCode,
        message == null || message.isEmpty ? 'Authentication gagal.' : message,
      );
    }
    return body;
  }
}
