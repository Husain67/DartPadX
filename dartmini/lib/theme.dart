import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryAccent = Color(0xFFFACC15); // VIDTSX golden yellow
  static const Color backgroundStart = Color(0xFF050505);
  static const Color backgroundEnd = Color(0xFF1A1A1A);
  static const Color appBarColor = Colors.black;
  static const Color buttonBackground = Color(0xFFE5E5E5); // off-white/cream

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryAccent,
      scaffoldBackgroundColor: backgroundStart,
      appBarTheme: const AppBarTheme(
        backgroundColor: appBarColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryAccent,
        surface: Color(0xFF1E1E1E),
        onSurface: Colors.white,
        error: Colors.redAccent,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white70),
      ),
    );
  }

  // A handy gradient container for scaffold bodies
  static BoxDecoration get backgroundGradient => const BoxDecoration(
    gradient: LinearGradient(
      colors: [backgroundStart, backgroundEnd],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );
}
