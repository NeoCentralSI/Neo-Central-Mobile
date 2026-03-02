import 'package:flutter_test/flutter_test.dart';
import 'package:neocentral/core/models/auth_models.dart';
import 'package:neocentral/core/enums/user_role.dart';

void main() {
  // ─── UserModel.fromJson ───────────────────────────────────

  group('UserModel.fromJson', () {
    test('parses complete JSON with all fields', () {
      final json = {
        'id': 'u1',
        'fullName': 'John Doe',
        'email': 'john@unand.ac.id',
        'identityNumber': '2011521001',
        'identityType': 'NIM',
        'phoneNumber': '08123456',
        'isVerified': true,
        'roles': [
          {'id': 'r1', 'name': 'Mahasiswa', 'status': 'active'},
        ],
        'student': {'id': 's1', 'enrollmentYear': 2020, 'status': 'active'},
        'lecturer': null,
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'u1');
      expect(user.fullName, 'John Doe');
      expect(user.email, 'john@unand.ac.id');
      expect(user.identityNumber, '2011521001');
      expect(user.identityType, 'NIM');
      expect(user.phoneNumber, '08123456');
      expect(user.isVerified, true);
      expect(user.roles.length, 1);
      expect(user.roles.first.name, 'Mahasiswa');
      expect(user.student, isNotNull);
      expect(user.student!.id, 's1');
      expect(user.student!.enrollmentYear, 2020);
      expect(user.lecturer, isNull);
    });

    test('handles missing optional fields with defaults', () {
      final json = {
        'id': 'u2',
        'roles': <dynamic>[],
      };

      final user = UserModel.fromJson(json);

      expect(user.fullName, '');
      expect(user.email, '');
      expect(user.identityNumber, isNull);
      expect(user.identityType, isNull);
      expect(user.phoneNumber, isNull);
      expect(user.isVerified, false);
      expect(user.roles, isEmpty);
      expect(user.student, isNull);
      expect(user.lecturer, isNull);
    });

    test('parses lecturer data when present', () {
      final json = {
        'id': 'u3',
        'fullName': 'Dr. Smith',
        'email': 'smith@unand.ac.id',
        'isVerified': true,
        'roles': [
          {'id': 'r2', 'name': 'Dosen Pembimbing'},
        ],
        'lecturer': {'id': 'l1', 'scienceGroup': 'RPL'},
      };

      final user = UserModel.fromJson(json);

      expect(user.lecturer, isNotNull);
      expect(user.lecturer!.id, 'l1');
      expect(user.lecturer!.scienceGroup, 'RPL');
      expect(user.student, isNull);
    });
  });

  // ─── UserModel.toJson / roundtrip ────────────────────────

  group('UserModel.toJson (roundtrip)', () {
    test('serialization roundtrip preserves data', () {
      final original = UserModel(
        id: 'u1',
        fullName: 'Test User',
        email: 'test@unand.ac.id',
        identityNumber: '123',
        isVerified: true,
        roles: [
          const UserRoleEntry(id: 'r1', name: 'Mahasiswa', status: 'active'),
        ],
        student: const StudentData(
          id: 's1',
          enrollmentYear: 2021,
          status: 'active',
        ),
      );

      final json = original.toJson();
      final restored = UserModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.fullName, original.fullName);
      expect(restored.email, original.email);
      expect(restored.identityNumber, original.identityNumber);
      expect(restored.isVerified, original.isVerified);
      expect(restored.roles.length, original.roles.length);
      expect(restored.roles.first.name, 'Mahasiswa');
      expect(restored.student?.id, original.student?.id);
      expect(restored.student?.enrollmentYear, 2021);
    });
  });

  // ─── UserModel.appRole ────────────────────────────────────

  group('UserModel.appRole', () {
    test('returns student for "Mahasiswa" role', () {
      final user = UserModel(
        id: 'u1',
        fullName: 'Student',
        email: 'student@unand.ac.id',
        isVerified: true,
        roles: [
          const UserRoleEntry(id: 'r1', name: 'Mahasiswa'),
        ],
      );

      expect(user.appRole, UserRole.student);
    });

    test('returns student for "student" role (lowercase)', () {
      final user = UserModel(
        id: 'u1',
        fullName: 'Student',
        email: 'student@unand.ac.id',
        isVerified: true,
        roles: [
          const UserRoleEntry(id: 'r1', name: 'student'),
        ],
      );

      expect(user.appRole, UserRole.student);
    });

    test('returns lecturer for "Dosen Pembimbing" role', () {
      final user = UserModel(
        id: 'u2',
        fullName: 'Lecturer',
        email: 'dosen@unand.ac.id',
        isVerified: true,
        roles: [
          const UserRoleEntry(id: 'r2', name: 'Dosen Pembimbing'),
        ],
      );

      expect(user.appRole, UserRole.lecturer);
    });

    test('returns lecturer for "lecturer" role (English)', () {
      final user = UserModel(
        id: 'u2',
        fullName: 'Lecturer',
        email: 'dosen@unand.ac.id',
        isVerified: true,
        roles: [
          const UserRoleEntry(id: 'r2', name: 'lecturer'),
        ],
      );

      expect(user.appRole, UserRole.lecturer);
    });

    test('fallback: student data present → student role', () {
      final user = UserModel(
        id: 'u3',
        fullName: 'Unknown',
        email: 'unknown@unand.ac.id',
        isVerified: false,
        roles: [],
        student: const StudentData(id: 's1'),
      );

      expect(user.appRole, UserRole.student);
    });

    test('fallback: lecturer data present → lecturer role', () {
      final user = UserModel(
        id: 'u4',
        fullName: 'Unknown',
        email: 'unknown@unand.ac.id',
        isVerified: false,
        roles: [],
        lecturer: const LecturerData(id: 'l1'),
      );

      expect(user.appRole, UserRole.lecturer);
    });

    test('fallback: no roles, no data → defaults to student', () {
      final user = UserModel(
        id: 'u5',
        fullName: 'Unknown',
        email: 'unknown@unand.ac.id',
        isVerified: false,
        roles: [],
      );

      expect(user.appRole, UserRole.student);
    });

    test('first matching role wins (student before lecturer)', () {
      final user = UserModel(
        id: 'u6',
        fullName: 'Both',
        email: 'both@unand.ac.id',
        isVerified: true,
        roles: [
          const UserRoleEntry(id: 'r1', name: 'Mahasiswa'),
          const UserRoleEntry(id: 'r2', name: 'Dosen'),
        ],
      );

      expect(user.appRole, UserRole.student);
    });
  });

  // ─── AuthResult.fromJson ──────────────────────────────────

  group('AuthResult.fromJson', () {
    test('parses tokens and user object', () {
      final json = {
        'accessToken': 'jwt-token',
        'refreshToken': 'refresh-token',
        'user': {
          'id': 'u1',
          'fullName': 'Test',
          'email': 'test@unand.ac.id',
          'isVerified': true,
          'roles': <dynamic>[],
        },
      };

      final result = AuthResult.fromJson(json);

      expect(result.accessToken, 'jwt-token');
      expect(result.refreshToken, 'refresh-token');
      expect(result.user.id, 'u1');
      expect(result.user.fullName, 'Test');
    });
  });

  // ─── UserRoleEntry ────────────────────────────────────────

  group('UserRoleEntry', () {
    test('fromJson parses all fields', () {
      final entry = UserRoleEntry.fromJson({
        'id': 'r1',
        'name': 'Mahasiswa',
        'status': 'active',
      });
      expect(entry.id, 'r1');
      expect(entry.name, 'Mahasiswa');
      expect(entry.status, 'active');
    });

    test('fromJson handles missing fields with defaults', () {
      final entry = UserRoleEntry.fromJson({});
      expect(entry.id, '');
      expect(entry.name, '');
      expect(entry.status, isNull);
    });

    test('toJson roundtrip', () {
      const entry = UserRoleEntry(id: 'r1', name: 'Dosen', status: 'active');
      final json = entry.toJson();
      expect(json['id'], 'r1');
      expect(json['name'], 'Dosen');
      expect(json['status'], 'active');
    });
  });

  // ─── StudentData ──────────────────────────────────────────

  group('StudentData', () {
    test('fromJson parses enrollment year', () {
      final data = StudentData.fromJson({
        'id': 's1',
        'enrollmentYear': 2020,
        'status': 'active',
      });
      expect(data.id, 's1');
      expect(data.enrollmentYear, 2020);
      expect(data.status, 'active');
    });

    test('fromJson handles missing optional fields', () {
      final data = StudentData.fromJson({'id': 's2'});
      expect(data.enrollmentYear, isNull);
      expect(data.status, isNull);
    });
  });

  // ─── LecturerData ────────────────────────────────────────

  group('LecturerData', () {
    test('fromJson parses science group', () {
      final data = LecturerData.fromJson({
        'id': 'l1',
        'scienceGroup': 'RPL',
      });
      expect(data.id, 'l1');
      expect(data.scienceGroup, 'RPL');
    });

    test('fromJson handles missing optional fields', () {
      final data = LecturerData.fromJson({'id': 'l2'});
      expect(data.scienceGroup, isNull);
    });
  });
}
