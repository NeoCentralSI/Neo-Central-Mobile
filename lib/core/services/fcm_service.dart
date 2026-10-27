import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../../firebase_options.dart';
import '../constants/app_config.dart';
import 'secure_storage_service.dart';

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

  /// Callbacks fired when the user taps a notification and opens the app.
  /// Use this to navigate to the relevant screen (e.g. switch to Dashboard tab).
  final List<void Function(Map<String, dynamic> data)> _openListeners = [];

  /// The most recent tap payload that arrived with no listeners registered.
  /// Replayed to the next listener that calls [addOpenListener] so cold-start
  /// taps (where FCM `getInitialMessage` fires inside AuthGate before any
  /// shell has been built) are not silently lost.
  Map<String, dynamic>? _pendingOpenData;

  void addOpenListener(void Function(Map<String, dynamic> data) listener) {
    _openListeners.add(listener);
    final pending = _pendingOpenData;
    if (pending != null) {
      _pendingOpenData = null;
      // Defer past the pushReplacement entry animation (≈300 ms) so that the
      // shell's Navigator.push is not issued while the transition is still
      // running — Flutter can silently drop a push made mid-transition.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(
          const Duration(milliseconds: 400),
          () => listener(pending),
        );
      });
    }
  }

  void removeOpenListener(void Function(Map<String, dynamic> data) listener) {
    _openListeners.remove(listener);
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
      debugPrint('[FCM] Token obtained');
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

    // A tap on a local notification that launched the app from closed.
    try {
      final launch = await _localNotif.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        _dispatchOpen(_decodePayload(launch!.notificationResponse?.payload));
      }
    } catch (e) {
      debugPrint('[LocalNotif] Launch details error (ignored): $e');
    }

    debugPrint('[FCM] Initialization complete');
  }

  // ── Local Notifications Setup ───────────────────────────────

  Future<void> _setupLocalNotifications() async {
    // Android init
    const androidInit = AndroidInitializationSettings(
      '@drawable/ic_notification',
    );

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
        debugPrint('[LocalNotif] Notification tapped');
        // A tap only opens the matching screen; actions (approve, reject)
        // happen there, so a backend rejection is always shown.
        _dispatchOpen(_decodePayload(response.payload));
      },
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
      icon: '@drawable/ic_notification',
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
        body: jsonEncode({'token': fcmToken, 'platform': 'mobile'}),
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
    debugPrint('[FCM] Message opened');

    final data = message.data;
    _dispatchOpen(data);
    // Data-refresh listeners always fire (no replay — they just refresh data).
    for (final listener in List.of(_listeners)) {
      listener(data);
    }
  }

  /// Hands a tap to the open listeners. With none registered yet (cold start,
  /// before login finished), the tap is kept and replayed to the first one.
  void _dispatchOpen(Map<String, dynamic> data) {
    if (_openListeners.isEmpty) {
      _pendingOpenData = data;
      return;
    }
    for (final listener in List.of(_openListeners)) {
      try {
        listener(data);
      } catch (e) {
        debugPrint('[FCM] Open listener error (ignored): $e');
      }
    }
  }

  static Map<String, dynamic> _decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return <String, dynamic>{};
  }
}

/// Top-level function for background messages (required by Firebase).
/// Data-only messages in background are handled by the system tray automatically
/// only if there's a notification payload. For data-only, we show local notif.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[FCM] Background message received');

  // Show local notification for data-only background messages
  final data = message.data;
  final title = data['title'] ?? '';
  final body = data['body'] ?? '';

  if (title.isNotEmpty || body.isNotEmpty) {
    final plugin = FlutterLocalNotificationsPlugin();

    const androidInit = AndroidInitializationSettings(
      '@drawable/ic_notification',
    );
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
      icon: '@drawable/ic_notification',
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
