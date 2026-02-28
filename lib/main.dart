import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/services/auth_service.dart';

import 'features/splash/presentation/splash_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/shell/main_shell.dart';

void main() {
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

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Short splash delay
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final result = await _authService.tryAutoLogin();

    if (!mounted) return;

    if (result != null) {
      // Already logged in – go straight to the correct shell
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              MainShell(userRole: result.user.appRole, user: result.user),
        ),
      );
    } else {
      // Not logged in – show login screen
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
