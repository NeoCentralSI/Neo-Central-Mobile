import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../constants/app_config.dart';
import '../models/api_envelope.dart';
import '../models/api_exception.dart';
import 'secure_storage_service.dart';

export '../models/api_exception.dart';

typedef AuthorizedRequest = Future<http.Response> Function(String? token);

/// Central HTTP client with bearer authentication, token refresh, and strict
/// opt-in response decoding.
///
/// Legacy methods still return decoded JSON so existing features keep their
/// current behavior. New feature services should use the typed `*Data` methods.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;

  ApiClient._internal()
    : _httpClient = http.Client(),
      _storage = SecureStorageService(),
      _baseUrl = AppConfig.baseUrl,
      _timeout = const Duration(seconds: 30);

  /// Injectable constructor for deterministic unit tests and alternate hosts.
  ApiClient.withDependencies({
    required http.Client httpClient,
    required SecureStorageService storage,
    String baseUrl = AppConfig.baseUrl,
    Duration timeout = const Duration(seconds: 30),
  }) : _httpClient = httpClient,
       _storage = storage,
       _baseUrl = baseUrl,
       _timeout = timeout;

  final http.Client _httpClient;
  final SecureStorageService _storage;
  final String _baseUrl;
  final Duration _timeout;

  Future<bool>? _refreshFuture;

  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    final uri = _uri(path, queryParams: queryParams);
    final response = await _sendAuthorized(
      (token) => _httpClient.get(uri, headers: _jsonHeaders(token)),
    );
    return _handleJsonResponse(response);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final uri = _uri(path);
    final response = await _sendAuthorized(
      (token) => _httpClient.post(
        uri,
        headers: _jsonHeaders(token),
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _handleJsonResponse(response);
  }

  Future<dynamic> patch(String path, {Object? body}) async {
    final uri = _uri(path);
    final response = await _sendAuthorized(
      (token) => _httpClient.patch(
        uri,
        headers: _jsonHeaders(token),
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _handleJsonResponse(response);
  }

  Future<dynamic> put(String path, {Object? body}) async {
    final uri = _uri(path);
    final response = await _sendAuthorized(
      (token) => _httpClient.put(
        uri,
        headers: _jsonHeaders(token),
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _handleJsonResponse(response);
  }

  Future<dynamic> delete(String path, {Object? body}) async {
    final uri = _uri(path);
    final response = await _sendAuthorized(
      (token) => _httpClient.delete(
        uri,
        headers: _jsonHeaders(token),
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _handleJsonResponse(response);
  }

  /// Strictly decodes the backend's standard success envelope.
  Future<T> getData<T>(
    String path, {
    Map<String, String>? queryParams,
    required T Function(dynamic value) decoder,
  }) async => ApiEnvelope<T>.decode(
    await get(path, queryParams: queryParams),
    decoder,
  ).data;

  Future<T> postData<T>(
    String path, {
    Object? body,
    required T Function(dynamic value) decoder,
  }) async => ApiEnvelope<T>.decode(await post(path, body: body), decoder).data;

  Future<T> patchData<T>(
    String path, {
    Object? body,
    required T Function(dynamic value) decoder,
  }) async =>
      ApiEnvelope<T>.decode(await patch(path, body: body), decoder).data;

  Future<T> putData<T>(
    String path, {
    Object? body,
    required T Function(dynamic value) decoder,
  }) async => ApiEnvelope<T>.decode(await put(path, body: body), decoder).data;

  Future<T> deleteData<T>(
    String path, {
    Object? body,
    required T Function(dynamic value) decoder,
  }) async =>
      ApiEnvelope<T>.decode(await delete(path, body: body), decoder).data;

  /// Sends multipart/form-data while retaining bearer refresh/retry behavior.
  /// UUIDs and other scalar identifiers belong in [fields].
  Future<dynamic> postMultipart(
    String path, {
    Map<String, String> fields = const {},
    List<MapEntry<String, String>>? listFields,
    String? filePath,
    String? fileName,
    String fileField = 'file',
  }) async {
    Uint8List? fileBytes;
    String? resolvedName;
    MediaType? contentType;

    if (filePath != null) {
      final file = File(filePath);
      if (!await file.exists()) {
        throw ApiException(0, 'File upload tidak ditemukan: $filePath');
      }
      fileBytes = await file.readAsBytes();
      resolvedName = fileName ?? filePath.split(Platform.pathSeparator).last;
      contentType = _contentType(resolvedName);
    }

    final uri = _uri(path);
    final response = await _sendAuthorized((token) async {
      // A MultipartRequest cannot be sent twice, so build a fresh request for
      // the single retry after token rotation.
      final request = http.MultipartRequest('POST', uri);
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.fields.addAll(fields);
      if (listFields != null) {
        for (final entry in listFields) {
          // MultipartRequest.fields is a Map and would silently keep only the
          // final value for repeated keys such as `milestoneIds[]`. A string
          // part without a filename preserves each occurrence on the wire.
          request.files.add(
            http.MultipartFile.fromString(entry.key, entry.value),
          );
        }
      }
      if (fileBytes != null && resolvedName != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            fileField,
            fileBytes,
            filename: resolvedName,
            contentType: contentType,
          ),
        );
      }

      final streamed = await _httpClient.send(request);
      return http.Response.fromStream(streamed);
    });
    return _handleJsonResponse(response);
  }

  /// Downloads an authenticated binary payload without attempting JSON decode.
  Future<ApiBinaryResponse> getBinary(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final uri = _uri(path, queryParams: queryParams);
    final response = await _sendAuthorized(
      (token) => _httpClient.get(uri, headers: _authHeaders(token)),
    );
    if (!_isSuccessful(response.statusCode)) {
      _handleJsonResponse(response);
    }
    return ApiBinaryResponse(
      bytes: response.bodyBytes,
      contentType: response.headers['content-type'],
      fileName: _extractFileName(response.headers['content-disposition']),
      headers: Map.unmodifiable(response.headers),
    );
  }

  Uri _uri(String path, {Map<String, String>? queryParams}) =>
      Uri.parse('$_baseUrl$path').replace(queryParameters: queryParams);

  Map<String, String> _authHeaders(String? token) => {
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  Map<String, String> _jsonHeaders(String? token) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    ..._authHeaders(token),
  };

  Future<http.Response> _sendAuthorized(AuthorizedRequest request) async {
    final attemptedToken = await _storage.getAccessToken();
    var response = await _runRequest(() => request(attemptedToken));
    if (response.statusCode != HttpStatus.unauthorized) return response;

    // If another request already rotated the access token, use that token and
    // avoid issuing a second refresh call.
    final currentToken = await _storage.getAccessToken();
    if (currentToken != null && currentToken != attemptedToken) {
      return _runRequest(() => request(currentToken));
    }

    final refreshed = await _refreshTokensSingleFlight();
    if (!refreshed) return response;

    final refreshedToken = await _storage.getAccessToken();
    response = await _runRequest(() => request(refreshedToken));
    return response;
  }

  Future<bool> _refreshTokensSingleFlight() {
    final pending = _refreshFuture;
    if (pending != null) return pending;

    final future = _performRefresh();
    _refreshFuture = future;
    return future.whenComplete(() {
      if (identical(_refreshFuture, future)) _refreshFuture = null;
    });
  }

  Future<bool> _performRefresh() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    final response = await _runRequest(
      () => _httpClient.post(
        _uri('/auth/refresh'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refreshToken': refreshToken}),
      ),
    );

    if (!_isSuccessful(response.statusCode)) {
      await _storage.clearTokens();
      return false;
    }

    try {
      final decoded = _decodeJson(response);
      if (decoded is! Map) {
        throw const ApiContractException(
          'Respons refresh token harus berupa objek JSON.',
        );
      }
      final json = Map<String, dynamic>.from(decoded);
      final accessToken = json['accessToken'];
      final rotatedRefreshToken = json['refreshToken'];
      if (accessToken is! String ||
          accessToken.isEmpty ||
          rotatedRefreshToken is! String ||
          rotatedRefreshToken.isEmpty) {
        throw const ApiContractException(
          'Respons refresh token tidak memiliki pasangan token yang valid.',
        );
      }
      await _storage.saveTokens(
        accessToken: accessToken,
        refreshToken: rotatedRefreshToken,
      );
      return true;
    } on ApiContractException {
      await _storage.clearTokens();
      rethrow;
    }
  }

  Future<http.Response> _runRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request().timeout(_timeout);
    } on TimeoutException catch (error) {
      throw NetworkApiException(
        'Permintaan ke server melewati batas waktu.',
        details: error,
      );
    } on SocketException catch (error) {
      throw NetworkApiException(
        'Tidak dapat terhubung ke server.',
        details: error,
      );
    } on http.ClientException catch (error) {
      throw NetworkApiException(
        'Terjadi gangguan koneksi ke server.',
        details: error,
      );
    }
  }

  dynamic _handleJsonResponse(http.Response response) {
    final body = _decodeJson(
      response,
      strict: _isSuccessful(response.statusCode),
    );
    if (_isSuccessful(response.statusCode)) return body;

    final json = body is Map ? Map<String, dynamic>.from(body) : null;
    final message = json?['message']?.toString() ?? 'Request gagal';
    final details = json?['details'] ?? json?['errors'];
    throw _exceptionFor(response.statusCode, message, details);
  }

  dynamic _decodeJson(http.Response response, {bool strict = true}) {
    if (response.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException catch (error) {
      if (!strict) return null;
      throw ApiContractException(
        'Server mengembalikan JSON yang tidak valid.',
        details: error,
      );
    }
  }

  ApiException _exceptionFor(int status, String message, Object? details) {
    return switch (status) {
      HttpStatus.unauthorized => UnauthorizedApiException(
        message,
        details: details,
      ),
      HttpStatus.forbidden => ForbiddenApiException(message, details: details),
      HttpStatus.notFound => NotFoundApiException(message, details: details),
      HttpStatus.conflict => ConflictApiException(message, details: details),
      HttpStatus.badRequest ||
      422 => ValidationApiException(status, message, details: details),
      >= 500 => ServerApiException(status, message, details: details),
      _ => ApiException(status, message, details: details),
    };
  }

  bool _isSuccessful(int status) => status >= 200 && status < 300;

  MediaType _contentType(String name) {
    final extension = name.split('.').last.toLowerCase();
    return switch (extension) {
      'pdf' => MediaType('application', 'pdf'),
      'doc' => MediaType('application', 'msword'),
      'docx' => MediaType(
        'application',
        'vnd.openxmlformats-officedocument.wordprocessingml.document',
      ),
      _ => MediaType('application', 'octet-stream'),
    };
  }

  String? _extractFileName(String? disposition) {
    if (disposition == null) return null;
    final encoded = RegExp(
      r"filename\*=UTF-8''([^;]+)",
      caseSensitive: false,
    ).firstMatch(disposition)?.group(1);
    if (encoded != null) return Uri.decodeComponent(encoded);

    return RegExp(
      r'filename="?([^";]+)"?',
      caseSensitive: false,
    ).firstMatch(disposition)?.group(1);
  }
}

class ApiBinaryResponse {
  final Uint8List bytes;
  final String? contentType;
  final String? fileName;
  final Map<String, String> headers;

  const ApiBinaryResponse({
    required this.bytes,
    required this.contentType,
    required this.fileName,
    required this.headers,
  });
}
