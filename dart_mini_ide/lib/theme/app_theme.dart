import 'package:flutter/material.dart';

class AppTheme {
  static const Color backgroundStart = Color(0xFF050505);
  static const Color backgroundEnd = Color(0xFF1a1a1a);
  static const Color primaryYellow = Color(0xFFFACC15);
  static const Color toolbarBg = Color(0xFFF9F9F9);
  static const Color toolbarBorder = Color(0xFFE0E0E0);
  static const Color pureBlack = Colors.black;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent, // Uses Container gradient
      appBarTheme: const AppBarTheme(
        backgroundColor: pureBlack,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryYellow,
        surface: pureBlack,
        onSurface: Colors.white,
      ),
    );
  }
}
