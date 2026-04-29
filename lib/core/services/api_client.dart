import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants/app_config.dart';
import 'secure_storage_service.dart';

/// Central HTTP client with automatic auth-header attachment.
///
/// All API calls go through this client so auth tokens are always sent.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final SecureStorageService _storage = SecureStorageService();

  /// GET request with Bearer token.
  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    final token = await _storage.getAccessToken();
    final uri = Uri.parse(
      '${AppConfig.baseUrl}$path',
    ).replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _headers(token));
    return _handleResponse(response);
  }

  /// POST request with Bearer token + JSON body.
  Future<dynamic> post(String path, {Object? body}) async {
    final token = await _storage.getAccessToken();
    final uri = Uri.parse('${AppConfig.baseUrl}$path');

    final response = await http.post(
      uri,
      headers: _headers(token),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  /// PATCH request with Bearer token + JSON body.
  Future<dynamic> patch(String path, {Object? body}) async {
    final token = await _storage.getAccessToken();
    final uri = Uri.parse('${AppConfig.baseUrl}$path');

    final response = await http.patch(
      uri,
      headers: _headers(token),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  /// PUT request with Bearer token + JSON body.
  Future<dynamic> put(String path, {Object? body}) async {
    final token = await _storage.getAccessToken();
    final uri = Uri.parse('${AppConfig.baseUrl}$path');

    final response = await http.put(
      uri,
      headers: _headers(token),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  /// DELETE request with Bearer token.
  Future<dynamic> delete(String path, {Object? body}) async {
    final token = await _storage.getAccessToken();
    final uri = Uri.parse('${AppConfig.baseUrl}$path');

    final response = await http.delete(
      uri,
      headers: _headers(token),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  /// POST multipart/form-data request with Bearer token.
  ///
  /// [fields] are text fields, [filePath] + [fileField] for optional file.
  /// [fileName] overrides the filename sent to the server.
  Future<dynamic> postMultipart(
    String path, {
    Map<String, String> fields = const {},
    List<MapEntry<String, String>>? listFields,
    String? filePath,
    String? fileName,
    String fileField = 'file',
  }) async {
    final token = await _storage.getAccessToken();
    final uri = Uri.parse('${AppConfig.baseUrl}$path');

    final request = http.MultipartRequest('POST', uri);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Add simple text fields
    request.fields.addAll(fields);

    // Add list fields (e.g. milestoneIds[])
    if (listFields != null) {
      for (final entry in listFields) {
        request.fields[entry.key] = entry.value;
      }
    }

    // Add file if provided — read bytes explicitly for Android compatibility
    if (filePath != null) {
      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final name = fileName ?? filePath.split(Platform.pathSeparator).last;
        debugPrint('[ApiClient] Attaching file: $name (${bytes.length} bytes)');

        // Detect content type from extension
        final ext = name.split('.').last.toLowerCase();
        final contentType = switch (ext) {
          'pdf' => MediaType('application', 'pdf'),
          'doc' => MediaType('application', 'msword'),
          'docx' => MediaType('application',
              'vnd.openxmlformats-officedocument.wordprocessingml.document'),
          _ => MediaType('application', 'octet-stream'),
        };

        request.files.add(http.MultipartFile.fromBytes(
          fileField,
          bytes,
          filename: name,
          contentType: contentType,
        ));
      } else {
        debugPrint('[ApiClient] WARNING: File not found at $filePath');
      }
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }

  // ─── Private helpers ────────────────────────────────────────

  Map<String, String> _headers(String? token) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  dynamic _handleResponse(http.Response response) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = body is Map
        ? (body['message'] ?? 'Request gagal')
        : 'Request gagal';
    throw ApiException(response.statusCode, message.toString());
  }
}

/// Simple typed exception for API errors.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
