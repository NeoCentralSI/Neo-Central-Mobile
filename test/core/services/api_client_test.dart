import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:neocentral/core/models/api_envelope.dart';
import 'package:neocentral/core/services/api_client.dart';
import 'package:neocentral/core/services/secure_storage_service.dart';
import 'package:neocentral/core/services/token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryTokenStore implements TokenStore {
  final values = <String, String>{};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

void main() {
  late MemoryTokenStore tokenStore;
  late SecureStorageService storage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    tokenStore = MemoryTokenStore();
    storage = SecureStorageService(tokenStore: tokenStore);
  });

  ApiClient clientWith(MockClient client) => ApiClient.withDependencies(
    httpClient: client,
    storage: storage,
    baseUrl: 'https://example.test',
    timeout: const Duration(seconds: 2),
  );

  String? authorization(http.Request request) =>
      request.headers['Authorization'] ?? request.headers['authorization'];

  group('ApiException compatibility and typing', () {
    test('keeps the original constructor and string representation', () {
      const exception = ApiException(404, 'Not found');

      expect(exception.statusCode, 404);
      expect(exception.message, 'Not found');
      expect(exception.toString(), 'ApiException(404): Not found');
    });

    test('maps forbidden responses to a typed exception', () async {
      final api = clientWith(
        MockClient(
          (_) async =>
              http.Response(jsonEncode({'message': 'Tidak diizinkan'}), 403),
        ),
      );

      expect(api.get('/forbidden'), throwsA(isA<ForbiddenApiException>()));
    });
  });

  group('JSON contracts', () {
    test('legacy method still returns decoded raw JSON', () async {
      final api = clientWith(
        MockClient(
          (_) async => http.Response(jsonEncode({'legacy': true}), 200),
        ),
      );

      expect(await api.get('/legacy'), {'legacy': true});
    });

    test('typed method strictly unwraps a valid envelope', () async {
      final api = clientWith(
        MockClient(
          (_) async => http.Response(
            jsonEncode({
              'success': true,
              'data': {'id': 'item-1'},
            }),
            200,
          ),
        ),
      );

      final id = await api.getData<String>(
        '/item',
        decoder: (data) => (data as Map<String, dynamic>)['id'] as String,
      );
      expect(id, 'item-1');
    });

    test('malformed successful JSON is a contract error', () async {
      final api = clientWith(
        MockClient((_) async => http.Response('<html>', 200)),
      );

      expect(api.get('/broken'), throwsA(isA<ApiContractException>()));
    });

    test('missing envelope data is a contract error, not an empty value', () {
      expect(
        () => ApiEnvelope<List<String>>.decode({
          'success': true,
        }, (value) => List<String>.from(value as List)),
        throwsA(isA<ApiContractException>()),
      );
    });
  });

  group('authenticated transport', () {
    test('binary download includes bearer token and preserves bytes', () async {
      await storage.saveTokens(
        accessToken: 'binary-token',
        refreshToken: 'refresh-token',
      );
      final api = clientWith(
        MockClient((request) async {
          expect(authorization(request), 'Bearer binary-token');
          return http.Response.bytes(
            [0, 1, 2, 255],
            200,
            headers: {
              'content-type': 'application/pdf',
              'content-disposition': 'attachment; filename="hasil.pdf"',
            },
          );
        }),
      );

      final result = await api.getBinary('/documents/result');
      expect(result.bytes, [0, 1, 2, 255]);
      expect(result.contentType, 'application/pdf');
      expect(result.fileName, 'hasil.pdf');
    });

    test('multipart sends UUID field and bearer token', () async {
      await storage.saveTokens(
        accessToken: 'upload-token',
        refreshToken: 'refresh-token',
      );
      final api = clientWith(
        MockClient((request) async {
          expect(authorization(request), 'Bearer upload-token');
          expect(request.body, contains('name="requirementId"'));
          expect(
            request.body,
            contains('0cf78ed0-591b-4f14-b37e-b41af2d01055'),
          );
          expect(
            RegExp('name="milestoneIds\\[\\]"').allMatches(request.body),
            hasLength(2),
          );
          expect(request.body, contains('milestone-1'));
          expect(request.body, contains('milestone-2'));
          return http.Response(jsonEncode({'success': true}), 200);
        }),
      );

      await api.postMultipart(
        '/requirements/upload',
        fields: const {'requirementId': '0cf78ed0-591b-4f14-b37e-b41af2d01055'},
        listFields: const [
          MapEntry('milestoneIds[]', 'milestone-1'),
          MapEntry('milestoneIds[]', 'milestone-2'),
        ],
      );
    });

    test('parallel 401 responses share one refresh and retry once', () async {
      await storage.saveTokens(
        accessToken: 'expired-access',
        refreshToken: 'refresh-1',
      );
      var refreshCalls = 0;
      var oldTokenCalls = 0;
      var newTokenCalls = 0;
      final api = clientWith(
        MockClient((request) async {
          if (request.url.path == '/auth/refresh') {
            refreshCalls++;
            expect(jsonDecode(request.body), {'refreshToken': 'refresh-1'});
            await Future<void>.delayed(const Duration(milliseconds: 20));
            return http.Response(
              jsonEncode({
                'success': true,
                'accessToken': 'fresh-access',
                'refreshToken': 'refresh-2',
              }),
              200,
            );
          }

          if (authorization(request) == 'Bearer expired-access') {
            oldTokenCalls++;
            return http.Response(jsonEncode({'message': 'Expired'}), 401);
          }

          expect(authorization(request), 'Bearer fresh-access');
          newTokenCalls++;
          return http.Response(
            jsonEncode({'success': true, 'data': request.url.path}),
            200,
          );
        }),
      );

      final results = await Future.wait([
        api.getData<String>('/first', decoder: (value) => value as String),
        api.getData<String>('/second', decoder: (value) => value as String),
      ]);

      expect(results, ['/first', '/second']);
      expect(oldTokenCalls, 2);
      expect(newTokenCalls, 2);
      expect(refreshCalls, 1);
      expect(await storage.getAccessToken(), 'fresh-access');
      expect(await storage.getRefreshToken(), 'refresh-2');
    });

    test(
      'does not loop when the retried request is still unauthorized',
      () async {
        await storage.saveTokens(
          accessToken: 'expired-access',
          refreshToken: 'refresh-1',
        );
        var protectedCalls = 0;
        var refreshCalls = 0;
        final api = clientWith(
          MockClient((request) async {
            if (request.url.path == '/auth/refresh') {
              refreshCalls++;
              return http.Response(
                jsonEncode({
                  'accessToken': 'fresh-access',
                  'refreshToken': 'refresh-2',
                }),
                200,
              );
            }
            protectedCalls++;
            return http.Response(jsonEncode({'message': 'Unauthorized'}), 401);
          }),
        );

        await expectLater(
          api.get('/protected'),
          throwsA(isA<UnauthorizedApiException>()),
        );
        expect(refreshCalls, 1);
        expect(protectedCalls, 2);
      },
    );
  });
}
