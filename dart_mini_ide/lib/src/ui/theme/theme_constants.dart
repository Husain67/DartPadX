import 'package:flutter/material.dart';

class ThemeConstants {
  // Deep black/dark gradient background (#050505 -> #1a1a1a)
  static const Color backgroundStart = Color(0xFF050505);
  static const Color backgroundEnd = Color(0xFF1A1A1A);

  // Top AppBar pure black
  static const Color appBarColor = Colors.black;

  // Primary accent: bright yellow/golden (#FACC15)
  static const Color primaryAccent = Color(0xFFFACC15);

  // Toolbar buttons: white/cream background with thin border
  static const Color toolbarButtonBg = Color(0xFFF9F9F9);
  static const Color toolbarButtonBorder = Color(0xFFE0E0E0);
  static const Color toolbarButtonIcon = Colors.black87;

  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundStart,
      primaryColor: primaryAccent,
      colorScheme: const ColorScheme.dark(
        primary: primaryAccent,
        secondary: primaryAccent,
        surface: backgroundEnd,
        error: Colors.redAccent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: appBarColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: primaryAccent),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      useMaterial3: true,
      fontFamily: 'Roboto', // Default standard font
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryAccent,
        ),
      ),
    );
  }
}
