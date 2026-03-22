import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color blackBg = Color(0xFF050505);
  static const Color darkBg = Color(0xFF1A1A1A);
  static const Color yellowAccent = Color(0xFFFACC15);
  static const Color whiteCream = Color(0xFFF9F9F9);
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color textLight = Color(0xFFE2E8F0);
  static const Color textDark = Color(0xFF0F172A);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: blackBg,
      primaryColor: yellowAccent,
      colorScheme: const ColorScheme.dark(
        primary: yellowAccent,
        surface: darkBg,
        onSurface: textLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: whiteCream),
        titleTextStyle: TextStyle(
          color: whiteCream,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: yellowAccent,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: yellowAccent,
          foregroundColor: textDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: darkBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: const TextStyle(color: whiteCream, fontSize: 18, fontWeight: FontWeight.bold),
        contentTextStyle: const TextStyle(color: textLight, fontSize: 14),
      ),
    );
  }
}
