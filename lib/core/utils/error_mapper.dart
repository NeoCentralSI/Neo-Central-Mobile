/// Maps errors from the sign-in flow to short Indonesian messages.
///
/// With [passThrough], [raw] is a message written by the backend: it is kept
/// as is unless a friendlier wording is known.
String friendlyAuthError(String raw, {bool passThrough = false}) {
  if (raw.contains('Invalid credentials')) {
    return 'Email atau kata sandi salah.';
  }
  if (raw.contains('cancelled') || raw.contains('cancel')) {
    return 'Login dibatalkan.';
  }
  if (raw.contains('not found') || raw.contains('belum terdaftar')) {
    return 'Akun tidak ditemukan. Silakan hubungi admin.';
  }
  if (raw.contains('403') || raw.contains('belum diaktivasi')) {
    return 'Akun belum diaktivasi. Hubungi admin.';
  }
  if (passThrough && raw.trim().isNotEmpty) return raw.trim();
  return 'Login gagal. Coba lagi nanti.';
}
