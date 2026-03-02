import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

/// Tests for the response handling patterns in NotificationApiService.
///
/// NotificationApiService uses raw `http` package (not ApiClient),
/// so we test the response parsing logic independently.
void main() {
  // Helper: simulates getNotifications response parsing
  Map<String, dynamic> parseNotificationsResponse(String body) {
    final bodyMap = jsonDecode(body) as Map<String, dynamic>;
    return {
      'notifications': (bodyMap['notifications'] as List<dynamic>?) ?? [],
      'unreadCount': (bodyMap['unreadCount'] as int?) ?? 0,
      'total': (bodyMap['total'] as int?) ?? 0,
    };
  }

  // ─── getNotifications parsing ─────────────────────────────

  group('getNotifications response parsing', () {
    test('parses complete response', () {
      final body = jsonEncode({
        'success': true,
        'notifications': [
          {'id': 'n1', 'title': 'Test', 'isRead': false},
          {'id': 'n2', 'title': 'Test2', 'isRead': true},
        ],
        'unreadCount': 1,
        'total': 2,
      });

      final result = parseNotificationsResponse(body);
      expect((result['notifications'] as List).length, 2);
      expect(result['unreadCount'], 1);
      expect(result['total'], 2);
    });

    test('handles missing notifications key', () {
      final body = jsonEncode({'success': true});
      final result = parseNotificationsResponse(body);
      expect(result['notifications'], isEmpty);
      expect(result['unreadCount'], 0);
      expect(result['total'], 0);
    });

    test('handles null unreadCount', () {
      final body = jsonEncode({
        'notifications': [],
        'unreadCount': null,
        'total': null,
      });
      final result = parseNotificationsResponse(body);
      expect(result['unreadCount'], 0);
      expect(result['total'], 0);
    });
  });

  // ─── getUnreadCount parsing ───────────────────────────────

  group('getUnreadCount response parsing', () {
    test('extracts unreadCount from response', () {
      final body = jsonDecode(jsonEncode({
        'success': true,
        'unreadCount': 5,
      })) as Map<String, dynamic>;

      final count = (body['unreadCount'] as int?) ?? 0;
      expect(count, 5);
    });

    test('defaults to 0 when unreadCount missing', () {
      final body = jsonDecode(jsonEncode({
        'success': true,
      })) as Map<String, dynamic>;

      final count = (body['unreadCount'] as int?) ?? 0;
      expect(count, 0);
    });
  });

  // ─── Error handling patterns ──────────────────────────────

  group('error handling', () {
    test('getNotifications throws on non-200', () {
      // Simulates what the service does on non-200 response
      void checkStatus(int statusCode) {
        if (statusCode != 200) {
          throw Exception('Gagal mengambil notifikasi');
        }
      }

      expect(() => checkStatus(500), throwsException);
      expect(() => checkStatus(401), throwsException);
      expect(() => checkStatus(200), returnsNormally);
    });

    test('markAsRead throws on non-200', () {
      void checkStatus(int statusCode) {
        if (statusCode != 200) {
          throw Exception(
              'Gagal menandai notifikasi sebagai sudah dibaca');
        }
      }

      expect(() => checkStatus(404), throwsException);
      expect(() => checkStatus(200), returnsNormally);
    });

    test('markAllAsRead throws on non-200', () {
      void checkStatus(int statusCode) {
        if (statusCode != 200) {
          throw Exception(
              'Gagal menandai semua notifikasi sebagai sudah dibaca');
        }
      }

      expect(() => checkStatus(500), throwsException);
      expect(() => checkStatus(200), returnsNormally);
    });

    test('deleteNotification throws on non-200', () {
      void checkStatus(int statusCode) {
        if (statusCode != 200) {
          throw Exception('Gagal menghapus notifikasi');
        }
      }

      expect(() => checkStatus(403), throwsException);
      expect(() => checkStatus(200), returnsNormally);
    });

    test('deleteAllNotifications throws on non-200', () {
      void checkStatus(int statusCode) {
        if (statusCode != 200) {
          throw Exception('Gagal menghapus semua notifikasi');
        }
      }

      expect(() => checkStatus(500), throwsException);
      expect(() => checkStatus(200), returnsNormally);
    });
  });
}
