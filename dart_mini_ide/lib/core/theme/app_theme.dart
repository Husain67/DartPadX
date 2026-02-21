import 'package:flutter/material.dart';
import 'package:dart_mini_ide/core/constants/app_colors.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.transparent, // We use gradient container
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      surface: AppColors.backgroundStart,
      onSurface: AppColors.textPrimary,
      background: AppColors.backgroundStart,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    fontFamily: 'Roboto', // Default
  );
}
