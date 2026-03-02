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

    test('displayName for staff is Staff', () {
      expect(UserRole.staff.displayName, 'Staff');
    });

    test('enum values count is 3', () {
      expect(UserRole.values.length, 3);
    });
  });
}
