import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../firebase_options.dart';
import '../constants/app_config.dart';
import 'secure_storage_service.dart';

@pragma('vm:entry-point')
void localNotificationTapBackground(NotificationResponse notificationResponse) {
  _handleNotificationAction(notificationResponse);
}

Future<void> _handleNotificationAction(NotificationResponse response) async {
  if (response.actionId == 'approve_guidance' && response.payload != null) {
    try {
      final data = jsonDecode(response.payload!);
      final guidanceId = data['guidanceId'];
      final role = data['role'];
      if (guidanceId != null && role == 'supervisor') {
        final storage = const FlutterSecureStorage();
        final token = await storage.read(key: 'neocentral_access_token');
        if (token != null) {
          final uri = Uri.parse(
            '${AppConfig.baseUrl}/thesisGuidance/lecturer/requests/$guidanceId/approve',
          );
          final httpRes = await http.patch(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'approvedDate': data['scheduledAt'],
              'duration': 60,
              'feedback': 'Bimbingan disetujui (via Notifikasi)',
            }),
          );
          if (httpRes.statusCode >= 200 && httpRes.statusCode < 300) {
            debugPrint('[LocalNotif] Guidance approved in background!');
          } else {
            debugPrint(
              '[LocalNotif] Failed to approve guidance: ${httpRes.body}',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[LocalNotif] Error handling action: $e');
    }
  }
}

/// Notification channel for Android (required for Android 8+).
const _androidChannel = AndroidNotificationChannel(
  'neocentral_guidance', // id
  'Bimbingan', // name
  description: 'Notifikasi bimbingan tugas akhir',
  importance: Importance.high,
  playSound: true,
);

/// Handles Firebase Cloud Messaging — token registration, foreground/background
/// message handling, and local notification display for data-only payloads.
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final SecureStorageService _storage = SecureStorageService();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  /// Callbacks that screens can register to react on incoming data messages.
  final List<void Function(Map<String, dynamic> data)> _listeners = [];

  void addListener(void Function(Map<String, dynamic> data) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(Map<String, dynamic> data) listener) {
    _listeners.remove(listener);
  }

  // ── Initialisation ──────────────────────────────────────────

  /// Call once after Firebase.initializeApp in main().
  Future<void> init() async {
    // ── 1. Setup local notifications ──
    await _setupLocalNotifications();

    // ── 2. Request FCM permission (iOS / Android 13+) ──
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] Notification permission denied');
      return;
    }

    // ── 3. Get FCM token & register with backend ──
    final token = await _messaging.getToken();
    if (token != null) {
      debugPrint('[FCM] Token obtained: ${token.substring(0, 20)}...');
      await _registerTokenWithBackend(token);
    } else {
      debugPrint('[FCM] WARNING: Token is null!');
    }

    // Re-register when token is refreshed
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('[FCM] Token refreshed');
      _registerTokenWithBackend(newToken);
    });

    // ── 4. Foreground messages ──
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // ── 5. Background / terminated tap ──
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpen);

    // Check for initial message (app was terminated)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpen(initialMessage);
    }

    debugPrint('[FCM] Initialization complete');
  }

  // ── Local Notifications Setup ───────────────────────────────

  Future<void> _setupLocalNotifications() async {
    // Android init
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS init
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotif.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('[LocalNotif] Tapped: ${response.payload}');
        _handleNotificationAction(response);
      },
      onDidReceiveBackgroundNotificationResponse:
          localNotificationTapBackground,
    );

    // Create Android notification channel
    if (Platform.isAndroid) {
      await _localNotif
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_androidChannel);
      debugPrint('[LocalNotif] Android channel created: ${_androidChannel.id}');
    }
  }

  /// Show a local notification from a data-only FCM message.
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      actions:
          (data != null &&
              data['type'] == 'thesis-guidance:requested' &&
              data['role'] == 'supervisor')
          ? [
              const AndroidNotificationAction(
                'approve_guidance',
                'Setujui (Approve)',
                showsUserInterface: true,
              ),
            ]
          : null,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use hashCode of time as unique ID
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _localNotif.show(
      id,
      title,
      body,
      details,
      payload: data != null ? jsonEncode(data) : null,
    );
    debugPrint('[LocalNotif] Shown: "$title" - "$body"');
  }

  // ── Token registration ──────────────────────────────────────

  Future<void> _registerTokenWithBackend(String fcmToken) async {
    try {
      final accessToken = await _storage.getAccessToken();
      if (accessToken == null) {
        debugPrint('[FCM] Skipping token registration: not logged in');
        return;
      }

      debugPrint('[FCM] Registering token with backend...');
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/notification/fcm/register'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'token': fcmToken}),
      );

      if (response.statusCode == 200) {
        debugPrint('[FCM] Token registered successfully');
      } else {
        debugPrint(
          '[FCM] Token registration failed: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('[FCM] Token registration error: $e');
    }
  }

  /// Call after login succeeds to register the current device token.
  Future<void> registerAfterLogin() async {
    final token = await _messaging.getToken();
    debugPrint(
      '[FCM] registerAfterLogin token=${token != null ? "${token.substring(0, 20)}..." : "null"}',
    );
    if (token != null) {
      await _registerTokenWithBackend(token);
    }
  }

  /// Call on logout to unregister the device token.
  Future<void> unregisterOnLogout() async {
    try {
      final fcmToken = await _messaging.getToken();
      final accessToken = await _storage.getAccessToken();
      if (fcmToken == null || accessToken == null) return;

      await http.delete(
        Uri.parse('${AppConfig.baseUrl}/notification/fcm/unregister'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'token': fcmToken}),
      );
      debugPrint('[FCM] Token unregistered');
    } catch (e) {
      debugPrint('[FCM] Token unregister error: $e');
    }
  }

  // ── Message handlers ────────────────────────────────────────

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] ──── Foreground message received ────');
    debugPrint('[FCM] data: ${message.data}');
    debugPrint(
      '[FCM] notification: ${message.notification?.title} / ${message.notification?.body}',
    );

    // Extract title/body from data (backend sends dataOnly=true)
    final data = message.data;
    final title = message.notification?.title ?? data['title'] ?? '';
    final body = message.notification?.body ?? data['body'] ?? '';

    // Show local notification so user sees the push
    if (title.isNotEmpty || body.isNotEmpty) {
      _showLocalNotification(title: title, body: body, data: data);
    }

    // Notify all registered listeners
    for (final listener in _listeners) {
      listener(data);
    }
  }

  void _handleMessageOpen(RemoteMessage message) {
    debugPrint('[FCM] Message opened: ${message.data}');

    // Notify listeners so screens can react (e.g. refresh data)
    final data = message.data;
    for (final listener in _listeners) {
      listener(data);
    }
  }
}

/// Top-level function for background messages (required by Firebase).
/// Data-only messages in background are handled by the system tray automatically
/// only if there's a notification payload. For data-only, we show local notif.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[FCM] Background message: ${message.data}');

  // Show local notification for data-only background messages
  final data = message.data;
  final title = data['title'] ?? '';
  final body = data['body'] ?? '';

  if (title.isNotEmpty || body.isNotEmpty) {
    final plugin = FlutterLocalNotificationsPlugin();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await plugin.initialize(initSettings);

    // Ensure channel exists
    await plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    final androidDetails = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      actions:
          (data['type'] == 'thesis-guidance:requested' &&
              data['role'] == 'supervisor')
          ? [
              const AndroidNotificationAction(
                'approve_guidance',
                'Setujui (Approve)',
                showsUserInterface: true,
              ),
            ]
          : null,
    );

    await plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(android: androidDetails),
      payload: jsonEncode(data),
    );
  }
}
