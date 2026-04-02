import 'package:flutter/material.dart';

class AppColors {
  static const Color backgroundStart = Color(0xFF050505);
  static const Color backgroundEnd = Color(0xFF1A1A1A);
  static const Color appBarBackground = Color(0xFF000000);
  static const Color primaryAccent = Color(0xFFFACC15); // VIDTSX bright yellow

  static const Color toolbarButtonBackground = Color(0xFFF9F9F9);
  static const Color toolbarButtonBorder = Color(0xFFE0E0E0);
  static const Color toolbarButtonText = Color(0xFF000000);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);

  static const Color success = Color(0xFF4ADE80); // Green for stdout
  static const Color error = Color(0xFFF87171); // Red for stderr
  static const Color surface = Color(0xFF222222);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: AppColors.backgroundStart,
      primaryColor: AppColors.primaryAccent,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.appBarBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryAccent,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAccent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
