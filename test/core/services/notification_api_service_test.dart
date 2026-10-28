import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:neocentral/core/services/api_client.dart';
import 'package:neocentral/core/services/notification_api_service.dart';
import 'package:neocentral/core/services/secure_storage_service.dart';
import 'package:neocentral/core/services/token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryTokenStore implements TokenStore {
  final values = <String, String>{};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

void main() {
  late List<http.Request> requests;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    requests = [];
  });

  NotificationApiService serviceWith(
    http.Response Function(http.Request request) handler,
  ) {
    final client = MockClient((request) async {
      requests.add(request);
      return handler(request);
    });
    return NotificationApiService.withClient(
      ApiClient.withDependencies(
        httpClient: client,
        storage: SecureStorageService(tokenStore: _MemoryTokenStore()),
        baseUrl: 'https://example.test',
        timeout: const Duration(seconds: 2),
      ),
    );
  }

  test('getNotifications sends paging and parses the list', () async {
    final service = serviceWith(
      (_) => http.Response(
        jsonEncode({
          'success': true,
          'notifications': [
            {'id': 'n1', 'title': 'A', 'isRead': false, 'type': null},
          ],
          'unreadCount': 1,
          'total': 1,
        }),
        200,
      ),
    );

    final result = await service.getNotifications(limit: 20, offset: 40);

    expect(requests.single.url.path, '/notification');
    expect(requests.single.url.queryParameters, {
      'limit': '20',
      'offset': '40',
    });
    expect((result['notifications'] as List).length, 1);
    expect(result['unreadCount'], 1);
  });

  test('getNotifications tolerates missing fields', () async {
    final service = serviceWith(
      (_) => http.Response(jsonEncode({'success': true}), 200),
    );

    final result = await service.getNotifications();

    expect(result['notifications'], isEmpty);
    expect(result['unreadCount'], 0);
  });

  test('getUnreadCount returns 0 on failure', () async {
    final service = serviceWith(
      (_) => http.Response(jsonEncode({'message': 'down'}), 500),
    );

    expect(await service.getUnreadCount(), 0);
  });

  test('a rejection keeps the backend message', () async {
    final service = serviceWith(
      (_) => http.Response(
        jsonEncode({'success': false, 'message': 'Notification not found'}),
        404,
      ),
    );

    await expectLater(
      service.markAsRead('x'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'Notification not found',
        ),
      ),
    );
    expect(requests.single.method, 'PATCH');
    expect(requests.single.url.path, '/notification/x/read');
  });

  test('deleteAllNotifications calls DELETE /notification/all', () async {
    final service = serviceWith(
      (_) => http.Response(jsonEncode({'success': true}), 200),
    );

    await service.deleteAllNotifications();

    expect(requests.single.method, 'DELETE');
    expect(requests.single.url.path, '/notification/all');
  });
}
