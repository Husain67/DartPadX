import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFFACC15); // VIDTSX Yellow
  static const Color backgroundColor = Color(0xFF050505); // Deep Black
  static const Color surfaceColor = Color(0xFF1A1A1A); // Dark Gradient End
  static const Color appBarColor = Colors.black; // Pure Black
  static const Color textColor = Colors.white;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryColor,
        surface: surfaceColor,
        onSurface: textColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: appBarColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black,
        ),
      ),
      useMaterial3: true,
    );
  }
}
