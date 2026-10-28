import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:neocentral/core/services/api_client.dart';
import 'package:neocentral/core/services/secure_storage_service.dart';
import 'package:neocentral/core/services/token_store.dart';

class MemoryTokenStore implements TokenStore {
  final values = <String, String>{};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

/// ApiClient over a fake backend. [handler] returns the JSON body (or a full
/// [http.Response]) for each request; every request is kept in [requests].
class FakeBackend {
  FakeBackend(this.handler, {this.accessToken});

  final Object? Function(http.Request request) handler;
  final requests = <http.Request>[];

  /// Signed-in session for the client, or none.
  final String? accessToken;

  ApiClient get client => ApiClient.withDependencies(
    httpClient: MockClient((request) async {
      requests.add(request);
      final result = handler(request);
      if (result is http.Response) return result;
      return http.Response(
        jsonEncode(result),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }),
    storage: SecureStorageService(
      tokenStore: MemoryTokenStore()
        ..values.addAll({
          if (accessToken != null)
            SecureStorageService.accessTokenKey: accessToken!,
        }),
    ),
    baseUrl: 'https://example.test',
    timeout: const Duration(seconds: 2),
  );
}
