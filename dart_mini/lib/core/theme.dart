import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFFACC15); // Yellow/golden
  static const Color backgroundColor1 = Color(0xFF050505);
  static const Color backgroundColor2 = Color(0xFF1A1A1A);
  static const Color appBarColor = Color(0xFF000000);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor1,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryColor,
        surface: backgroundColor1,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          minimumSize: const Size(48, 48),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: backgroundColor2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      useMaterial3: true,
    );
  }
}
