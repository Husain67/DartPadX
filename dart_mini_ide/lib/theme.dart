import 'package:flutter/material.dart';

class AppTheme {
  static const Color backgroundStart = Color(0xFF050505);
  static const Color backgroundEnd = Color(0xFF1a1a1a);
  static const Color primaryYellow = Color(0xFFFACC15);
  static const Color appBarColor = Colors.black;
  static const Color toolbarButtonBg = Color(0xFFF9F9F9);
  static const Color toolbarButtonBorder = Color(0xFFE0E0E0);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryYellow,
      scaffoldBackgroundColor: backgroundStart,
      appBarTheme: const AppBarTheme(
        backgroundColor: appBarColor,
        elevation: 0,
        centerTitle: false,
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryYellow,
        surface: backgroundStart,
      ),
    );
  }
}
