import 'package:flutter/material.dart';

class AppTheme {
  // Deep black gradient background (#050505 to #1a1a1a)
  static const Color backgroundDark = Color(0xFF050505);
  static const Color backgroundLight = Color(0xFF1a1a1a);

  // Bright yellow accent (#FACC15)
  static const Color accentYellow = Color(0xFFFACC15);

  static const Color surfaceColor = Color(0xFF121212);
  static const Color whiteCream = Color(0xFFF9F9F9);
  static const Color borderLight = Color(0xFFE0E0E0);

  static BoxDecoration get gradientBackground {
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [backgroundDark, backgroundLight],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: accentYellow,
      scaffoldBackgroundColor: Colors.transparent, // Handled by gradient container
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black, // Pure black Top AppBar
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      colorScheme: const ColorScheme.dark(
        primary: accentYellow,
        secondary: accentYellow,
        surface: surfaceColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentYellow,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}
