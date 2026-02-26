import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFFFACC15); // Bright Yellow
  static const Color background = Color(0xFF050505); // Deep Black
  static const Color surface = Color(0xFF1A1A1A); // Dark Grey
  static const Color text = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color border = Colors.white24;

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: primary,
        surface: surface,
        background: background,
        onPrimary: Colors.black,
        onSurface: text,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: text),
        bodyLarge: TextStyle(color: text),
      ),
    );
  }
}
