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

  /// GET /notification
  /// Fetches notifications for the currently logged-in user.
  Future<List<dynamic>> getNotifications() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/notification'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data'] ?? [];
    }
    throw Exception('Gagal mengambil notifikasi');
  }

  /// GET /notification/unread-count
  /// Returns only the number of unread notifications.
  Future<int> getUnreadCount() async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/notification/unread-count'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['data'] ?? 0;
    }
    return 0;
  }

  /// PATCH /notification/:id/read
  /// Marks a specific notification as read.
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
  /// Marks all notifications for the user as read.
  Future<void> markAllAsRead() async {
    final response = await http.patch(
      Uri.parse('${AppConfig.baseUrl}/notification/read-all'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal menandai semua notifikasi sebagai sudah dibaca');
    }
  }
}
