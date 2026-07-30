import 'package:flutter/material.dart';

class AppTheme {
  // Deep black/dark gradient background (#050505 to #1a1a1a)
  static const Color backgroundTop = Color(0xFF050505);
  static const Color backgroundBottom = Color(0xFF1A1A1A);

  // Top AppBar: pure black
  static const Color appBarColor = Color(0xFF000000);

  // Primary accent: bright yellow/golden #FACC15
  static const Color primaryAccent = Color(0xFFFACC15);

  // White/cream background for toolbar buttons
  static const Color toolbarButtonBg = Color(0xFFFAFAFA);
  static const Color toolbarButtonBorder = Color(0xFFE0E0E0);

  // Gradient background for standard screens
  static const BoxDecoration backgroundGradient = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [backgroundTop, backgroundBottom],
    ),
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryAccent,
      scaffoldBackgroundColor: backgroundTop,
      colorScheme: const ColorScheme.dark(
        primary: primaryAccent,
        surface: backgroundTop,
        surfaceContainer: backgroundBottom,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: appBarColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: backgroundBottom,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white),
      ),
      useMaterial3: true,
    );
  }
}
