/// Base exception for failures produced by the Neo Central API layer.
///
/// The positional constructor and [toString] are intentionally kept compatible
/// with the original mobile client.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Object? details;

  const ApiException(this.statusCode, this.message, {this.details});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class UnauthorizedApiException extends ApiException {
  const UnauthorizedApiException(String message, {Object? details})
    : super(401, message, details: details);
}

class ForbiddenApiException extends ApiException {
  const ForbiddenApiException(String message, {Object? details})
    : super(403, message, details: details);
}

class NotFoundApiException extends ApiException {
  const NotFoundApiException(String message, {Object? details})
    : super(404, message, details: details);
}

class ConflictApiException extends ApiException {
  const ConflictApiException(String message, {Object? details})
    : super(409, message, details: details);
}

class ValidationApiException extends ApiException {
  const ValidationApiException(
    super.statusCode,
    super.message, {
    super.details,
  });
}

class ServerApiException extends ApiException {
  const ServerApiException(super.statusCode, super.message, {super.details});
}

/// A transport failure for which no valid HTTP response was received.
class NetworkApiException extends ApiException {
  const NetworkApiException(String message, {Object? details})
    : super(0, message, details: details);
}

/// The server replied, but its JSON shape does not match the agreed contract.
class ApiContractException extends ApiException {
  const ApiContractException(String message, {Object? details})
    : super(0, message, details: details);
}
