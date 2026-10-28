import 'package:flutter_test/flutter_test.dart';
import 'package:neocentral/core/enums/user_role.dart';

void main() {
  group('UserRole', () {
    test('displayName for student is Mahasiswa', () {
      expect(UserRole.student.displayName, 'Mahasiswa');
    });

    test('displayName for lecturer is Dosen', () {
      expect(UserRole.lecturer.displayName, 'Dosen');
    });

    test('displayName for admin is Admin', () {
      expect(UserRole.admin.displayName, 'Admin');
    });

    test('has only the three mobile roles (no Kadep role)', () {
      expect(UserRole.values, [
        UserRole.student,
        UserRole.lecturer,
        UserRole.admin,
      ]);
    });
  });
}
