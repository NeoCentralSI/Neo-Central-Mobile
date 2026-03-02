import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neocentral/core/services/secure_storage_service.dart';
import 'package:neocentral/core/models/auth_models.dart';
import 'package:neocentral/core/enums/user_role.dart';

void main() {
  late SecureStorageService storage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = SecureStorageService();
  });

  // ─── saveAuthResult + reads ───────────────────────────────

  group('saveAuthResult & reads', () {
    test('persists and retrieves access token', () async {
      final result = AuthResult.fromJson({
        'accessToken': 'test-jwt',
        'refreshToken': 'test-refresh',
        'user': {
          'id': 'u1',
          'fullName': 'Test',
          'email': 'test@unand.ac.id',
          'isVerified': true,
          'roles': <dynamic>[],
        },
      });

      await storage.saveAuthResult(result);

      final token = await storage.getAccessToken();
      expect(token, 'test-jwt');
    });

    test('persists and retrieves refresh token', () async {
      final result = AuthResult.fromJson({
        'accessToken': 'jwt',
        'refreshToken': 'my-refresh',
        'user': {
          'id': 'u1',
          'fullName': 'Test',
          'email': 'test@unand.ac.id',
          'isVerified': true,
          'roles': <dynamic>[],
        },
      });

      await storage.saveAuthResult(result);

      final token = await storage.getRefreshToken();
      expect(token, 'my-refresh');
    });

    test('persists and retrieves user data', () async {
      final result = AuthResult.fromJson({
        'accessToken': 'jwt',
        'refreshToken': 'refresh',
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

      await storage.saveAuthResult(result);

      final user = await storage.getUser();
      expect(user, isNotNull);
      expect(user!.id, 'u1');
      expect(user.fullName, 'John Doe');
      expect(user.roles.length, 1);
      expect(user.student?.enrollmentYear, 2020);
    });
  });

  // ─── getUser edge cases ───────────────────────────────────

  group('getUser', () {
    test('returns null when no user stored', () async {
      final user = await storage.getUser();
      expect(user, isNull);
    });

    test('returns null for corrupted JSON', () async {
      // Manually set invalid JSON
      SharedPreferences.setMockInitialValues({
        'user_data': 'not-valid-json{{{',
      });
      storage = SecureStorageService();

      final user = await storage.getUser();
      expect(user, isNull);
    });
  });

  // ─── getUserRole ──────────────────────────────────────────

  group('getUserRole', () {
    test('returns student role for mahasiswa user', () async {
      final userData = {
        'id': 'u1',
        'fullName': 'Student',
        'email': 'student@unand.ac.id',
        'isVerified': true,
        'roles': [
          {'id': 'r1', 'name': 'Mahasiswa'},
        ],
      };
      SharedPreferences.setMockInitialValues({
        'user_data': jsonEncode(userData),
        'access_token': 'token',
      });
      storage = SecureStorageService();

      final role = await storage.getUserRole();
      expect(role, UserRole.student);
    });

    test('returns lecturer role for dosen user', () async {
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
        'user_data': jsonEncode(userData),
        'access_token': 'token',
      });
      storage = SecureStorageService();

      final role = await storage.getUserRole();
      expect(role, UserRole.lecturer);
    });

    test('returns null when no user stored', () async {
      final role = await storage.getUserRole();
      expect(role, isNull);
    });
  });

  // ─── isLoggedIn ───────────────────────────────────────────

  group('isLoggedIn', () {
    test('returns true when token exists', () async {
      SharedPreferences.setMockInitialValues({
        'access_token': 'some-token',
      });
      storage = SecureStorageService();

      expect(await storage.isLoggedIn(), true);
    });

    test('returns false when no token', () async {
      expect(await storage.isLoggedIn(), false);
    });

    test('returns false when token is empty', () async {
      SharedPreferences.setMockInitialValues({
        'access_token': '',
      });
      storage = SecureStorageService();

      expect(await storage.isLoggedIn(), false);
    });
  });

  // ─── clearAll ─────────────────────────────────────────────

  group('clearAll', () {
    test('removes all stored data', () async {
      final result = AuthResult.fromJson({
        'accessToken': 'jwt',
        'refreshToken': 'refresh',
        'user': {
          'id': 'u1',
          'fullName': 'Test',
          'email': 'test@test.com',
          'isVerified': true,
          'roles': <dynamic>[],
        },
      });

      await storage.saveAuthResult(result);
      expect(await storage.isLoggedIn(), true);

      await storage.clearAll();

      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(await storage.getUser(), isNull);
      expect(await storage.isLoggedIn(), false);
    });
  });
}
