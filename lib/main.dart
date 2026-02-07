import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/splash/presentation/splash_screen.dart';

void main() {
  runApp(const NeoCentralApp());
}

/// Root application widget
/// 
/// Configures the app with NeoCentral theme and routing.
class NeoCentralApp extends StatelessWidget {
  const NeoCentralApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeoCentral',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
