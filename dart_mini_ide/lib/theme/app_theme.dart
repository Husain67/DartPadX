import 'package:flutter/material.dart';

class AppTheme {
  // Deep black gradient background (#050505 -> #1a1a1a)
  static const Color bgDark = Color(0xFF050505);
  static const Color bgLight = Color(0xFF1A1A1A);

  // Bright yellow/golden accent
  static const Color accentYellow = Color(0xFFFACC15);

  // Text colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFAAAAAA);

  // UI Elements
  static const Color toolbarBg = Color(0xFFF9F9F9);
  static const Color toolbarBorder = Color(0xFFE0E0E0);
  static const Color toolbarIcon = Colors.black87;

  // Editor
  static const Color editorBg = Color(0xFF0D0D0D);
  static const Color gutterBg = Color(0xFF111111);
  static const Color gutterText = Color(0xFF555555);
  static const Color lineHighlight = Color(0x22FACC15);

  // Output
  static const Color outputStdout = Colors.greenAccent;
  static const Color outputStderr = Colors.redAccent;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: accentYellow,
      colorScheme: const ColorScheme.dark(
        primary: accentYellow,
        secondary: accentYellow,
        surface: bgLight,
        error: Colors.redAccent,
        onPrimary: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: accentYellow),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentYellow,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          elevation: 0,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentYellow,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF333333)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentYellow),
        ),
        labelStyle: const TextStyle(color: textSecondary),
      ),
    );
  }
}

class AppConstants {
  static const double maxMobileWidth = 480.0;
  static const double defaultPadding = 16.0;
  static const double toolbarHeight = 60.0;
  static const double toolbarButtonSize = 48.0;
}
