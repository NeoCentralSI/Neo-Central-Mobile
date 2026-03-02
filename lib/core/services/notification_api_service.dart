import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_config.dart';
import 'secure_storage_service.dart';

/// Service for interaction with the notification system.
class NotificationApiService {
  static final NotificationApiService _instance =
      NotificationApiService._internal();
  factory NotificationApiService() => _instance;
  NotificationApiService._internal();

  final SecureStorageService _storage = SecureStorageService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// GET /notification?limit=&offset=
  /// Response: { success, notifications: [...], unreadCount, total }
  Future<Map<String, dynamic>> getNotifications({
    int limit = 20,
    int offset = 0,
    bool onlyUnread = false,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/notification').replace(
      queryParameters: {
        'limit': limit.toString(),
        'offset': offset.toString(),
        if (onlyUnread) 'onlyUnread': 'true',
      },
    );
    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'notifications': (body['notifications'] as List<dynamic>?) ?? [],
        'unreadCount': (body['unreadCount'] as int?) ?? 0,
        'total': (body['total'] as int?) ?? 0,
      };
    }
    throw Exception('Gagal mengambil notifikasi');
  }

  /// GET /notification/unread-count
  /// Response: { success, unreadCount }
  Future<int> getUnreadCount() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/notification/unread-count'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return (body['unreadCount'] as int?) ?? 0;
    }
    return 0;
  }

  /// PATCH /notification/:id/read
  Future<void> markAsRead(String id) async {
    final response = await http.patch(
      Uri.parse('${AppConfig.baseUrl}/notification/$id/read'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal menandai notifikasi sebagai sudah dibaca');
    }
  }

  /// PATCH /notification/read-all
  Future<void> markAllAsRead() async {
    final response = await http.patch(
      Uri.parse('${AppConfig.baseUrl}/notification/read-all'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal menandai semua notifikasi sebagai sudah dibaca');
    }
  }

  /// DELETE /notification/:id
  Future<void> deleteNotification(String id) async {
    final response = await http.delete(
      Uri.parse('${AppConfig.baseUrl}/notification/$id'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus notifikasi');
    }
  }

  /// DELETE /notification/all
  Future<void> deleteAllNotifications() async {
    final response = await http.delete(
      Uri.parse('${AppConfig.baseUrl}/notification/all'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus semua notifikasi');
    }
  }
}
