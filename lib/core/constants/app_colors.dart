import 'package:flutter/material.dart';

/// App color constants for NeoCentral
///
/// Contains all brand colors used throughout the application.
/// Primary brand color matches the web frontend orange theme (#F7931E).
abstract class AppColors {
  AppColors._();

  // Brand Colors
  static const Color primary = Color(0xFFF7931E);
  static const Color primaryLight = Color(0xFFFFAF4D);
  static const Color primaryDark = Color(0xFFD47800);
  static const Color secondary = Color(0xFFF7931E);

  // Background Colors
  static const Color background = Color(0xFFF9F9F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFFFF8F0); // warm cream

  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // Border
  static const Color border = Color(0xFFFED7AA); // orange-200
  static const Color borderLight = Color(0xFFF3F4F6);

  // Status Colors
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color successDark = Color(0xFF16A34A);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFD97706);

  static const Color destructive = Color(0xFFEF4444);
  static const Color destructiveLight = Color(0xFFFEE2E2);
  static const Color destructiveDark = Color(0xFFDC2626);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFEFF6FF);
  static const Color infoDark = Color(0xFF2563EB);

  // Utility Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  // Divider
  static const Color divider = Color(0xFFE5E7EB);

  // Shadow
  static Color shadow = const Color(0xFF000000).withValues(alpha: 0.08);
  static Color primaryShadow = const Color(0xFFF7931E).withValues(alpha: 0.25);
}
