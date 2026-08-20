import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:neocentral/core/enums/user_role.dart';
import 'package:neocentral/core/models/auth_models.dart';
import 'package:neocentral/core/services/secure_storage_service.dart';
import 'package:neocentral/core/services/token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryTokenStore implements TokenStore {
  final values = <String, String>{};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

void main() {
  late MemoryTokenStore tokenStore;
  late SecureStorageService storage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tokenStore = MemoryTokenStore();
    storage = SecureStorageService(tokenStore: tokenStore);
  });

  AuthResult authResult({
    String accessToken = 'test-jwt',
    String refreshToken = 'test-refresh',
  }) => AuthResult.fromJson({
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'user': {
      'id': 'u1',
      'fullName': 'John Doe',
      'email': 'john@unand.ac.id',
      'isVerified': true,
      'roles': [
        {'id': 'r1', 'name': 'Mahasiswa'},
      ],
      'student': {'id': 's1', 'enrollmentYear': 2020},
    },
  });

  group('secure token persistence', () {
    test('stores tokens outside SharedPreferences', () async {
      await storage.saveAuthResult(authResult());

      expect(await storage.getAccessToken(), 'test-jwt');
      expect(await storage.getRefreshToken(), 'test-refresh');
      expect(
        tokenStore.values[SecureStorageService.accessTokenKey],
        'test-jwt',
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SecureStorageService.accessTokenKey), isNull);
      expect(prefs.getString(SecureStorageService.refreshTokenKey), isNull);
      expect(prefs.getString(SecureStorageService.userKey), isNotNull);
    });

    test('migrates and removes legacy preference tokens on read', () async {
      SharedPreferences.setMockInitialValues({
        SecureStorageService.accessTokenKey: 'legacy-access',
        SecureStorageService.refreshTokenKey: 'legacy-refresh',
      });
      storage = SecureStorageService(tokenStore: tokenStore);

      expect(await storage.getAccessToken(), 'legacy-access');
      expect(await storage.getRefreshToken(), 'legacy-refresh');
      expect(
        tokenStore.values[SecureStorageService.accessTokenKey],
        'legacy-access',
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(SecureStorageService.accessTokenKey), false);
      expect(prefs.containsKey(SecureStorageService.refreshTokenKey), false);
    });

    test('secure value takes precedence over a legacy copy', () async {
      SharedPreferences.setMockInitialValues({
        SecureStorageService.accessTokenKey: 'stale-token',
      });
      tokenStore.values[SecureStorageService.accessTokenKey] = 'secure-token';
      storage = SecureStorageService(tokenStore: tokenStore);

      expect(await storage.getAccessToken(), 'secure-token');
    });

    test('saveTokens replaces a rotated token pair', () async {
      await storage.saveTokens(
        accessToken: 'new-access',
        refreshToken: 'new-refresh',
      );

      expect(await storage.getAccessToken(), 'new-access');
      expect(await storage.getRefreshToken(), 'new-refresh');
    });
  });

  group('profile cache', () {
    test('persists and retrieves non-secret user data', () async {
      await storage.saveAuthResult(authResult());

      final user = await storage.getUser();
      expect(user?.id, 'u1');
      expect(user?.fullName, 'John Doe');
      expect(user?.student?.enrollmentYear, 2020);
      expect(user?.appRole, UserRole.student);
    });

    test('returns null for corrupted user JSON', () async {
      SharedPreferences.setMockInitialValues({
        SecureStorageService.userKey: 'not-valid-json{{{',
      });
      storage = SecureStorageService(tokenStore: tokenStore);

      expect(await storage.getUser(), isNull);
    });

    test('resolves a lecturer role from cached profile', () async {
      final userData = {
        'id': 'u2',
        'fullName': 'Dosen',
        'email': 'dosen@unand.ac.id',
        'isVerified': true,
        'roles': [
          {'id': 'r2', 'name': 'Dosen Pembimbing'},
        ],
      };
      SharedPreferences.setMockInitialValues({
        SecureStorageService.userKey: jsonEncode(userData),
      });
      storage = SecureStorageService(tokenStore: tokenStore);

      expect(await storage.getUserRole(), UserRole.lecturer);
    });
  });

  group('session lifecycle', () {
    test('isLoggedIn requires a non-empty access token', () async {
      expect(await storage.isLoggedIn(), false);

      await storage.saveTokens(accessToken: '', refreshToken: 'refresh');
      expect(await storage.isLoggedIn(), false);

      await storage.saveTokens(accessToken: 'jwt', refreshToken: 'refresh');
      expect(await storage.isLoggedIn(), true);
    });

    test('clearAll removes secure tokens and cached profile', () async {
      await storage.saveAuthResult(authResult());
      await storage.clearAll();

      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(await storage.getUser(), isNull);
      expect(tokenStore.values, isEmpty);
    });
  });
}
