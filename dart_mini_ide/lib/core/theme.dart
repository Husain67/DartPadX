import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryAccent = Color(0xFFFACC15); // Bright yellow/golden
  static const Color backgroundDark = Color(0xFF050505);
  static const Color backgroundLight = Color(0xFF1A1A1A);
  static const Color pureBlack = Color(0xFF000000);
  static const Color textLight = Color(0xFFF3F4F6);
  static const Color textMuted = Color(0xFF9CA3AF);

  static BoxDecoration get gradientBackground {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [backgroundDark, backgroundLight],
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryAccent,
      scaffoldBackgroundColor: Colors.transparent, // Handled by gradient container
      appBarTheme: const AppBarTheme(
        backgroundColor: pureBlack,
        elevation: 0,
        iconTheme: IconThemeData(color: textLight),
        titleTextStyle: TextStyle(
          color: textLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryAccent,
        secondary: primaryAccent,
        surface: backgroundLight,
        onSurface: textLight,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: pureBlack,
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
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: pureBlack,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textMuted.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textMuted.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryAccent),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: backgroundLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryAccent,
        unselectedLabelColor: textMuted,
        indicatorColor: primaryAccent,
      ),
    );
  }
}
