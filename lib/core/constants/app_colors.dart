import 'package:flutter/material.dart';

/// App color constants for NeoCentral
///
/// Contains all brand colors used throughout the application.
/// Primary brand color is orange (#F5A623).
abstract class AppColors {
  AppColors._();

  // Brand Colors
  static const Color primary = Color(0xFFF5A623);
  static const Color primaryLight = Color(0xFFFFBF4D);
  static const Color primaryDark = Color(0xFFD48C00);
  static const Color secondary = Color(
    0xFFF5A623,
  ); // Orange for now, can be adjusted

  // Background Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  // Utility Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;
}
