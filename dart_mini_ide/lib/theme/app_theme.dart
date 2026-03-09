import 'package:flutter/material.dart';

class AppTheme {
  static const Color backgroundStart = Color(0xFF050505);
  static const Color backgroundEnd = Color(0xFF1A1A1A);
  static const Color primaryAccent = Color(0xFFFACC15); // Bright yellow
  static const Color pillBackground = Color(0xFFF9F9F9); // White/cream
  static const Color pillBorder = Color(0xFFE0E0E0);
  static const Color pureBlack = Color(0xFF000000);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundStart, // We'll use a Container with gradient instead
      primaryColor: primaryAccent,
      appBarTheme: const AppBarTheme(
        backgroundColor: pureBlack,
        elevation: 0,
        centerTitle: false,
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryAccent,
        secondary: primaryAccent,
        surface: backgroundEnd,

      ),
      useMaterial3: true,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white70),
        titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: backgroundEnd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
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
