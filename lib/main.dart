import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/services/auth_service.dart';
import 'core/services/fcm_service.dart';

import 'features/splash/presentation/splash_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/shell/main_shell.dart';
import 'features/internship/presentation/internship_shell.dart';
import 'core/services/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const NeoCentralApp());
}

/// Global navigator key — required by aad_oauth to show OAuth WebView
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Root application widget
class NeoCentralApp extends StatelessWidget {
  const NeoCentralApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeoCentral',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      navigatorKey: navigatorKey, // required by aad_oauth
      home: const _AuthGate(),
    );
  }
}

/// Determines the initial route:
/// - Splash → check persisted token → LoginScreen or MainShell
class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  final _authService = AuthService();
  final _fcmService = FcmService();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Short splash delay
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    try {
      final result = await _authService.tryAutoLogin();

      if (!mounted) return;

      if (result != null) {
        // Initialize FCM — non-blocking; don't let FCM failure block login
        try {
          await _fcmService.init();
          await _fcmService.registerAfterLogin();
        } catch (e) {
          debugPrint('[AuthGate] FCM init error (non-fatal): $e');
        }

        if (!mounted) return;

        // Check preferred default home
        final prefs = PreferencesService();
        final defaultHome = await prefs.getDefaultHome();

        if (!mounted) return;

        // Already logged in – go to preferred shell
        Widget targetScreen;
        if (defaultHome == 'internship') {
          targetScreen = InternshipShell(user: result.user);
        } else {
          targetScreen = MainShell(userRole: result.user.appRole, user: result.user);
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => targetScreen),
        );
      } else {
        // Not logged in – show login screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      debugPrint('[AuthGate] Auth check error: $e');
      if (!mounted) return;
      // Fallback to login screen on any error
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show splash while checking auth
    return const SplashScreen();
  }
}
