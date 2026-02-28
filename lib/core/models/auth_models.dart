import '../../core/enums/user_role.dart';

// ─── User Model ───────────────────────────────────────────────
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? identityNumber;
  final String? identityType;
  final String? phoneNumber;
  final bool isVerified;
  final List<UserRoleEntry> roles;
  final StudentData? student;
  final LecturerData? lecturer;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.identityNumber,
    this.identityType,
    this.phoneNumber,
    required this.isVerified,
    required this.roles,
    this.student,
    this.lecturer,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      identityNumber: json['identityNumber'] as String?,
      identityType: json['identityType'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      roles: (json['roles'] as List<dynamic>? ?? [])
          .map((r) => UserRoleEntry.fromJson(r as Map<String, dynamic>))
          .toList(),
      student: json['student'] != null
          ? StudentData.fromJson(json['student'] as Map<String, dynamic>)
          : null,
      lecturer: json['lecturer'] != null
          ? LecturerData.fromJson(json['lecturer'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'identityNumber': identityNumber,
    'identityType': identityType,
    'phoneNumber': phoneNumber,
    'isVerified': isVerified,
    'roles': roles.map((r) => r.toJson()).toList(),
    'student': student?.toJson(),
    'lecturer': lecturer?.toJson(),
  };

  /// Resolve the primary app role from the roles array.
  UserRole get appRole {
    for (final r in roles) {
      final name = r.name.toLowerCase();
      if (name == 'mahasiswa' || name == 'student') return UserRole.student;
      if (name.contains('dosen') || name.contains('lecturer')) {
        return UserRole.lecturer;
      }
    }
    // Fallback: if student data present → student, else lecturer
    if (student != null) return UserRole.student;
    if (lecturer != null) return UserRole.lecturer;
    return UserRole.student;
  }
}

class UserRoleEntry {
  final String id;
  final String name;
  final String? status;

  const UserRoleEntry({required this.id, required this.name, this.status});

  factory UserRoleEntry.fromJson(Map<String, dynamic> json) => UserRoleEntry(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    status: json['status'] as String?,
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'status': status};
}

class StudentData {
  final String id;
  final int? enrollmentYear;
  final String? status;

  const StudentData({required this.id, this.enrollmentYear, this.status});

  factory StudentData.fromJson(Map<String, dynamic> json) => StudentData(
    id: json['id'] as String? ?? '',
    enrollmentYear: json['enrollmentYear'] as int?,
    status: json['status'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'enrollmentYear': enrollmentYear,
    'status': status,
  };
}

class LecturerData {
  final String id;
  final String? scienceGroup;

  const LecturerData({required this.id, this.scienceGroup});

  factory LecturerData.fromJson(Map<String, dynamic> json) => LecturerData(
    id: json['id'] as String? ?? '',
    scienceGroup: json['scienceGroup'] as String?,
  );

  Map<String, dynamic> toJson() => {'id': id, 'scienceGroup': scienceGroup};
}

// ─── Auth Result ──────────────────────────────────────────────
class AuthResult {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
  );
}
