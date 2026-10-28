/// Role the mobile app is built around.
///
/// Department roles (Ketua Departemen, Sekretaris Departemen, and so on) are
/// lecturers on mobile: they get the lecturer menu and nothing extra.
enum UserRole {
  student,
  lecturer,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'Mahasiswa';
      case UserRole.lecturer:
        return 'Dosen';
      case UserRole.admin:
        return 'Admin';
    }
  }
}
