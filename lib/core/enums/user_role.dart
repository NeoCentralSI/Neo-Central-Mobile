/// User role enum for the NeoCentral app
enum UserRole {
  student,
  lecturer,
  staff,
  headOfDepartment,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'Mahasiswa';
      case UserRole.lecturer:
        return 'Dosen';
      case UserRole.staff:
        return 'Staff';
      case UserRole.headOfDepartment:
        return 'Ketua Departemen';
      case UserRole.admin:
        return 'Admin';
    }
  }
}
