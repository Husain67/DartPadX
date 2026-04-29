import 'package:flutter/material.dart';

class AppTheme {
  static const Color backgroundStart = Color(0xFF050505);
  static const Color backgroundEnd = Color(0xFF1A1A1A);
  static const Color primaryAccent = Color(0xFFFACC15);
  static const Color toolbarBg = Color(0xFFF9F9F9);
  static const Color toolbarBorder = Color(0xFFE0E0E0);

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.transparent,
    primaryColor: primaryAccent,
    colorScheme: const ColorScheme.dark(
      primary: primaryAccent,
      secondary: primaryAccent,
      surface: backgroundStart,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
  );
}
