import 'package:flutter/material.dart';

class AppColors {
  static const Color backgroundStart = Color(0xFF050505);
  static const Color backgroundEnd = Color(0xFF1A1A1A);
  static const Color accentYellow = Color(0xFFFACC15);
  static const Color toolbarButtonBg = Color(0xFFF9F9F9);
  static const Color toolbarButtonBorder = Color(0xFFE0E0E0);
  static const Color textMain = Colors.white;
  static const Color textSecondary = Colors.grey;
  static const Color errorRed = Colors.redAccent;
  static const Color successGreen = Colors.greenAccent;
  static const Color editorBg = Color(0xFF1E1E1E);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundStart,
      primaryColor: AppColors.accentYellow,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentYellow,
        secondary: AppColors.accentYellow,
        surface: AppColors.backgroundEnd,
        error: AppColors.errorRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.backgroundEnd,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black45,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accentYellow),
        ),
      ),
    );
  }
}
