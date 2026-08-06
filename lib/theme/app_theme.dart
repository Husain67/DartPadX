import 'package:flutter/material.dart';

class AppTheme {
  static const Color backgroundStart = Color(0xFF050505);
  static const Color backgroundEnd = Color(0xFF1A1A1A);
  static const Color primaryAccent = Color(0xFFFACC15);
  static const Color appBarColor = Colors.black;
  static const Color toolbarButtonBg = Color(0xFFF5F5DC); // Cream/white
  static const Color toolbarButtonBorder = Colors.white24;
  static const Color toolbarIconColor = Colors.black87;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryAccent,
      scaffoldBackgroundColor: backgroundStart, // Will be overridden by gradient container
      appBarTheme: const AppBarTheme(
        backgroundColor: appBarColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryAccent,
        secondary: primaryAccent,
        surface: backgroundEnd, // Use surface instead of background
      ),
      useMaterial3: true,
    );
  }

  static BoxDecoration get gradientBackground {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [backgroundStart, backgroundEnd],
      ),
    );
  }
}
