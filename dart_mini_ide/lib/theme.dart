import 'package:flutter/material.dart';

class AppTheme {
  static const Color backgroundStart = Color(0xFF050505);
  static const Color backgroundEnd = Color(0xFF1A1A1A);
  static const Color accentYellow = Color(0xFFFACC15);
  static const Color toolbarBg = Color(0xFFF9F9F9);
  static const Color toolbarBorder = Color(0xFFE0E0E0);

  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: Colors.transparent, // Requires container with gradient
    primaryColor: accentYellow,
    colorScheme: const ColorScheme.dark(
      primary: accentYellow,
      surface: backgroundEnd,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentYellow,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
  );
}
