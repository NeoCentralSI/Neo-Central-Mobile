/// Maps raw error strings from auth flow to user-friendly Indonesian messages.
String friendlyAuthError(String raw) {
  if (raw.contains('cancelled') || raw.contains('cancel')) {
    return 'Login dibatalkan.';
  }
  if (raw.contains('not found') || raw.contains('belum terdaftar')) {
    return 'Akun tidak ditemukan. Silakan hubungi admin.';
  }
  if (raw.contains('403') || raw.contains('belum diaktivasi')) {
    return 'Akun belum diaktivasi. Hubungi admin.';
  }
  return 'Login gagal. Coba lagi nanti.';
}
