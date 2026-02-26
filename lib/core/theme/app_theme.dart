/// app_theme.dart
///
/// Centralised theme configuration for the Daraz Clone app.
///
/// Daraz brand colours:
///   Primary / accent   : #FF6000  (Daraz orange)
///   Surface / scaffold : #F5F5F5  (light grey background)
///   Cards              : #FFFFFF
///
/// Using Material 3 (useMaterial3: true) for modern defaults.

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._(); // Prevent instantiation — all members are static.

  /// The primary Daraz orange colour.
  static const Color primaryOrange = Color(0xFFFF6000);

  /// Light-mode application theme.
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryOrange,
        primary: primaryOrange,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryOrange,
      ),
    );
  }
}
