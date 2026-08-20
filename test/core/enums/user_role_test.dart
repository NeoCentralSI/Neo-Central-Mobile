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

    test('displayName for head of department is Ketua Departemen', () {
      expect(UserRole.headOfDepartment.displayName, 'Ketua Departemen');
    });

    test('displayName for admin is Admin', () {
      expect(UserRole.admin.displayName, 'Admin');
    });

    test('contains all five application roles', () {
      expect(UserRole.values.length, 5);
    });
  });
}
