import 'package:flutter_test/flutter_test.dart';
import 'package:neocentral/core/utils/error_mapper.dart';

void main() {
  group('friendlyAuthError', () {
    test('maps "cancelled" to login dibatalkan', () {
      expect(
        friendlyAuthError('Exception: Login cancelled by user'),
        'Login dibatalkan.',
      );
    });

    test('maps "cancel" to login dibatalkan', () {
      expect(
        friendlyAuthError('User did cancel the flow'),
        'Login dibatalkan.',
      );
    });

    test('maps "not found" to akun tidak ditemukan', () {
      expect(
        friendlyAuthError('Error: User not found'),
        'Akun tidak ditemukan. Silakan hubungi admin.',
      );
    });

    test('maps "belum terdaftar" to akun tidak ditemukan', () {
      expect(
        friendlyAuthError('User belum terdaftar'),
        'Akun tidak ditemukan. Silakan hubungi admin.',
      );
    });

    test('maps "403" to akun belum diaktivasi', () {
      expect(
        friendlyAuthError('Error 403: Forbidden'),
        'Akun belum diaktivasi. Hubungi admin.',
      );
    });

    test('maps "belum diaktivasi" to akun belum diaktivasi', () {
      expect(
        friendlyAuthError('Akun belum diaktivasi oleh admin.'),
        'Akun belum diaktivasi. Hubungi admin.',
      );
    });

    test('defaults to generic error for unknown errors', () {
      expect(
        friendlyAuthError('Something unexpected happened'),
        'Login gagal. Coba lagi nanti.',
      );
    });

    test('defaults for empty string', () {
      expect(
        friendlyAuthError(''),
        'Login gagal. Coba lagi nanti.',
      );
    });
  });
}
