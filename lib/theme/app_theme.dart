// lib/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // Main teal colors from the design
  static const Color primary = Color(0xFF1A7A6E);
  static const Color primaryDark = Color(0xFF135C52);
  static const Color primaryLight = Color(0xFF2AA99A);
  static const Color background = Color(0xFFF0F4F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A3C38);
  static const Color textGrey = Color(0xFF7A9E9B);
  static const Color inputFill = Color(0xFFF0F4F3);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: primaryLight,
      background: background,
      surface: surface,
    ),
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryDark,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputFill,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    fontFamily: 'Roboto',
  );
}