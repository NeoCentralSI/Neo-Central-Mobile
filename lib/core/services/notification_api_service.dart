import 'api_client.dart';

/// In-app notifications (`/notification`).
///
/// Uses [ApiClient], so an expired access token is refreshed like on every
/// other screen, and a rejection carries the backend message.
class NotificationApiService {
  static final NotificationApiService _instance = NotificationApiService._(
    ApiClient(),
  );
  factory NotificationApiService() => _instance;

  NotificationApiService._(this._api);

  /// For tests.
  NotificationApiService.withClient(ApiClient api) : _api = api;

  final ApiClient _api;

  static int _int(Object? value) => value is num ? value.toInt() : 0;

  /// GET /notification?limit=&offset=
  /// Response: `{ success, notifications: [...], unreadCount, total }`;
  /// `total` is the size of this page.
  Future<Map<String, dynamic>> getNotifications({
    int limit = 20,
    int offset = 0,
    bool onlyUnread = false,
  }) async {
    final res = await _api.get(
      '/notification',
      queryParams: {
        'limit': '$limit',
        'offset': '$offset',
        if (onlyUnread) 'onlyUnread': 'true',
      },
    );
    final body = res is Map ? res : const {};
    final list = body['notifications'];
    return {
      'notifications': list is List ? list : <dynamic>[],
      'unreadCount': _int(body['unreadCount']),
      'total': _int(body['total']),
    };
  }

  /// GET /notification/unread-count → `{ success, unreadCount }`.
  /// Returns 0 when the count cannot be read; it only feeds a badge.
  Future<int> getUnreadCount() async {
    try {
      final res = await _api.get('/notification/unread-count');
      return res is Map ? _int(res['unreadCount']) : 0;
    } catch (_) {
      return 0;
    }
  }

  /// PATCH /notification/:id/read
  Future<void> markAsRead(String id) => _api.patch('/notification/$id/read');

  /// PATCH /notification/read-all
  Future<void> markAllAsRead() => _api.patch('/notification/read-all');

  /// DELETE /notification/:id
  Future<void> deleteNotification(String id) =>
      _api.delete('/notification/$id');

  /// DELETE /notification/all
  Future<void> deleteAllNotifications() => _api.delete('/notification/all');
}
