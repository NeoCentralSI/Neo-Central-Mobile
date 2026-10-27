import '../models/api_exception.dart';

/// Text to show the user for a failed request.
///
/// A rejection from the backend (for example "Anda sedang cuti. ...") is shown
/// as the backend wrote it; the app does not restate business rules. Anything
/// else (a bug, a parse error) falls back to [fallback] so raw exception text
/// never reaches the screen.
String errorMessageOf(
  Object error, {
  String fallback = 'Terjadi kesalahan. Silakan coba lagi.',
}) {
  if (error is ApiException) {
    final message = error.message.trim();
    if (message.isNotEmpty) return message;
  }
  return fallback;
}

/// True when the backend answered 404 (for example "Tugas akhir aktif tidak
/// ditemukan").
bool isNotFoundError(Object error) =>
    error is ApiException && error.statusCode == 404;
